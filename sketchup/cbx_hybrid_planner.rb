require 'sketchup.rb'
require 'json'
require 'tmpdir'

# Load canonical engine without modifying it (safe for in-memory eval where __dir__ is nil)
if defined?(__dir__) && __dir__
  engine_path = File.join(__dir__, 'cbx_hybrid_engine.rb')
  engine_path = File.expand_path(File.join(__dir__, '..', 'cbx_hybrid_engine.rb')) unless File.exist?(engine_path)
  load engine_path if File.exist?(engine_path)

  hud_path = File.join(__dir__, 'cbx_viewport_hud.rb')
  load hud_path if File.exist?(hud_path)

  editor_path = File.join(__dir__, 'cbx_box_editor.rb')
  load editor_path if File.exist?(editor_path)

  exports_path = File.join(__dir__, 'cbx_exports.rb')
  load exports_path if File.exist?(exports_path)
end

module CabinexAI
  module HybridPlanner
    class << self
      attr_accessor :last_specs, :project_settings
    end

    HTML_PATH = (defined?(__dir__) && __dir__) ? File.join(__dir__, 'cbx_hybrid_planner.html') : File.join(File.dirname(__FILE__), 'cbx_hybrid_planner.html')

    BASE_BLIND_RETURN = 625.mm
    TOP_BLIND_RETURN = 375.mm
    MIN_CORNER_DOOR_OPENING = 450.mm
    MIN_BASE_CORNER_WIDTH = 1075.mm
    MIN_TOP_CORNER_WIDTH = 825.mm
    MAX_BOTTOM_WIDTH = 1200.mm
    MAX_TOP_WIDTH = 900.mm
    HOOD_CLEARANCE = 6.inch
    SLIM_HOOD_WIDTH = 600.mm
    SLIM_HOOD_DEPTH = 300.mm
    SLIM_HOOD_HEIGHT = 140.mm
    TALL_WIDTH = 600.mm

    def self.animate_status_bar(prefix_msg = "Processing")
      @anim_active = true
      states = ["===>", "======>", "=========>", "============>"]
      idx = 0
      @anim_timer = UI.start_timer(0.3, true) do
        Sketchup.set_status_text("#{prefix_msg} #{states[idx % states.length]}")
        idx += 1
      end
    end

    def self.stop_status_bar_animation(final_msg = "")
      @anim_active = false
      UI.stop_timer(@anim_timer) if @anim_timer
      Sketchup.set_status_text(final_msg)
    end

    def self.show_dialog
      if @dialog && @dialog.visible?
        @dialog.close rescue nil
      end

      @dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "Cabinex AI Studio â€” Modular Board Kitchen Planner",
          :preferences_key => "com.cabinetrix.modular_planner_v1",
          :scrollable => true,
          :resizable => true,
          :width => 580,
          :height => 840,
          :min_width => 440,
          :min_height => 540,
          :style => UI::HtmlDialog::STYLE_DIALOG
        }
      )

      # Load raw HTML directly to bypass Chromium disk cache (supports Cloud preloaded HTML in RAM)
      html_content = if defined?(CabinexAI::CloudUI::PLANNER_B64) && !CabinexAI::CloudUI::PLANNER_B64.to_s.empty?
        require 'base64'
        Base64.strict_decode64(CabinexAI::CloudUI::PLANNER_B64).force_encoding('UTF-8')
      elsif defined?(CabinexAI::CloudUI::PLANNER_HTML) && !CabinexAI::CloudUI::PLANNER_HTML.to_s.empty?
        CabinexAI::CloudUI::PLANNER_HTML
      elsif File.exist?(HTML_PATH.to_s)
        File.read(HTML_PATH)
      else
        ''
      end
      @dialog.set_html(html_content)

      # 1. Logout Handler
      @dialog.add_action_callback("doLogout") do |_action_context|
        UI.start_timer(0.1, false) do
          @dialog.close rescue nil
          if defined?(CabinexAI::CloudLoader) && CabinexAI::CloudLoader.respond_to?(:show_login_dialog)
            CabinexAI::CloudLoader.show_login_dialog
          elsif defined?(CabinexAI::CloudLoader) && CabinexAI::CloudLoader.respond_to?(:show_login_dialog)
            CabinexAI::CloudLoader.show_login_dialog
          end
        end
      end

      # 2. 3D Kitchen Generation with Complexity-Based Token Deduction
      @dialog.add_action_callback("buildKitchen") do |_action_context, params_json|
        begin
          specs = JSON.parse(params_json)

          # Verify & Consume Generation Tokens from Cloud
          if defined?(CabinexAI::CloudLoader) && CabinexAI::CloudLoader.respond_to?(:consume_tokens)
            res = CabinexAI::CloudLoader.consume_tokens(specs)
            if res && !res['success']
              err_msg = res['error'] || "Insufficient tokens to generate this kitchen design."
              UI.messagebox("âš ï¸ Cabinex License Notice:\n\n#{err_msg}\n\nPlease top up tokens in your Admin Console.")
              @dialog.execute_script("onKitchenGenerated('error', #{err_msg.to_json}, null);")
              next
            end

            # Update live token balance in dialog header
            if res && !res['tokens_remaining'].nil?
              @dialog.execute_script("setUserContext(null, #{res['tokens_remaining'].to_json});")
            end
          elsif defined?(CabinexAI::CloudLoader) && CabinexAI::CloudLoader.respond_to?(:consume_tokens)
            res = CabinexAI::CloudLoader.consume_tokens(specs)
            if res && !res['success']
              err_msg = res['error'] || "Insufficient tokens to generate this kitchen design."
              UI.messagebox("âš ï¸ Cabinex License Notice:\n\n#{err_msg}\n\nPlease top up tokens in your Admin Console.")
              @dialog.execute_script("onKitchenGenerated('error', #{err_msg.to_json}, null);")
              next
            end

            # Update live token balance in dialog header
            if res && !res['tokens_remaining'].nil?
              @dialog.execute_script("setUserContext(null, #{res['tokens_remaining'].to_json});")
            end
          end

          animate_status_bar("Generating 3D Kitchen")
          CabinexAI::HybridPlanner.last_specs = specs
          bom_data = build_from_specs(specs)
          CabinexAI::ViewportHUD.update_from_specs(specs, bom_data) if defined?(CabinexAI::ViewportHUD)
          stop_status_bar_animation("Kitchen generated successfully!")
          @dialog.execute_script("onKitchenGenerated('success', 'Kitchen generated successfully!', #{bom_data.to_json})")
        rescue => e
          stop_status_bar_animation("Failed to build kitchen.")
          puts "Cabinex Planner Error: #{e.message}\n#{e.backtrace.first(8).join("\n")}"
          UI.messagebox("Failed to build kitchen: #{e.message}\nCheck Ruby console.")
          @dialog.execute_script("onKitchenGenerated('error', #{e.message.to_json}, null)")
        end
      end

      @dialog.add_action_callback("exportWorkshopPack") do |_action_context, params_json|
        begin
          specs = JSON.parse(params_json)

          room = specs['room'] || {}
          quote = specs['quote'] || {}
          wa = (room['wall_a_mm'] || 2488).to_i
          wb = (room['wall_b_mm'] || 1379).to_i
          markup_pct = (quote['markup_pct'] || 35.0).to_f
          linear_ft = ((wa + wb) / 304.8) * 2.2
          base_cost = linear_ft * 49500
          quote_lkr = base_cost * (1.0 + markup_pct / 100.0)

          if defined?(CabinexAI::CloudLoader) && CabinexAI::CloudLoader.respond_to?(:send_telemetry)
            CabinexAI::CloudLoader.send_telemetry('QUOTATION_EXPORTED', quote['project_name'] || 'Client Quotation Export', wa, wb, linear_ft, quote_lkr)
          end

          animate_status_bar("Exporting Workshop Pack")
          show_workshop_report(specs)
          stop_status_bar_animation("Workshop Pack Exported")
        rescue => e
          stop_status_bar_animation("Failed to export Workshop Pack.")
          puts "Workshop Export Error: #{e.message}\n#{e.backtrace.first(6).join("\n")}"
          UI.messagebox("Could not generate workshop pack: #{e.message}")
        end
      end

      # 4. Live 3D Viewport Snapshot Capture for UI Previews Tab
      @dialog.add_action_callback("get3DPreviews") do |_action_context|
        begin
          images = capture_viewport_images
          @dialog.execute_script("if (typeof on3DPreviewsReady === 'function') on3DPreviewsReady(#{images.to_json});")
        rescue => e
          puts "3D Preview Capture Notice: #{e.message}"
        end
      end

      @dialog.show

      # Inject User Account & Token Balance Context
      UI.start_timer(0.35, false) do
        user_name = defined?(CabinexAI::CloudLoader) ? CabinexAI::CloudLoader.active_user : 'asanke1@gmail.com'
        tok_bal = defined?(CabinexAI::CloudLoader) ? CabinexAI::CloudLoader.token_balance : 100
        @dialog.execute_script("setUserContext(#{user_name.to_json}, #{tok_bal.to_json});")
      end
    end

    def self.image_to_base64(file_path)
      return "" unless file_path && File.exist?(file_path)
      require 'base64'
      raw_bytes = File.binread(file_path)
      "data:image/png;base64,#{Base64.strict_encode64(raw_bytes)}"
    rescue => e
      puts "Base64 encode notice for #{file_path}: #{e.message}"
      ""
    end

    def self.capture_viewport_images
      model = Sketchup.active_model
      view = model.active_view
      camera = view.camera
      temp_dir = File.join(Dir.tmpdir, 'cabinex_reports')
      Dir.mkdir(temp_dir) unless File.exist?(temp_dir)

      iso_path = File.join(temp_dir, 'cbx_iso.png')
      front_path = File.join(temp_dir, 'cbx_front.png')
      return_path = File.join(temp_dir, 'cbx_return.png')
      top_path = File.join(temp_dir, 'cbx_top.png')

      saved_eye = camera.eye
      saved_target = camera.target
      saved_up = camera.up
      saved_perspective = camera.perspective?

      begin
        # 1. 3D Isometric Overview
        camera.perspective = true
        view.zoom_extents
        view.write_image({ filename: iso_path, width: 1200, height: 800, antialias: true, compression: 0.9 })

        # 2. Front Elevation (Wall A)
        camera.perspective = false
        cam_eye = Geom::Point3d.new(1500.mm, -4000.mm, 1200.mm)
        cam_target = Geom::Point3d.new(1500.mm, 0, 1200.mm)
        cam_up = Geom::Vector3d.new(0, 0, 1)
        camera.set(cam_eye, cam_target, cam_up)
        view.zoom_extents
        view.write_image({ filename: front_path, width: 1200, height: 800, antialias: true, compression: 0.9 })

        # 3. Return Elevation (Wall B)
        cam_eye = Geom::Point3d.new(-4000.mm, 1000.mm, 1200.mm)
        cam_target = Geom::Point3d.new(0, 1000.mm, 1200.mm)
        camera.set(cam_eye, cam_target, cam_up)
        view.zoom_extents
        view.write_image({ filename: return_path, width: 1200, height: 800, antialias: true, compression: 0.9 })

        # 4. Top Plan
        cam_eye = Geom::Point3d.new(1500.mm, 1000.mm, 6000.mm)
        cam_target = Geom::Point3d.new(1500.mm, 1000.mm, 0)
        cam_up = Geom::Vector3d.new(0, 1, 0)
        camera.set(cam_eye, cam_target, cam_up)
        view.zoom_extents
        view.write_image({ filename: top_path, width: 1200, height: 800, antialias: true, compression: 0.9 })

        # Restore original camera
        camera.perspective = saved_perspective
        camera.set(saved_eye, saved_target, saved_up)
        view.zoom_extents
      rescue => e
        puts "Warning capturing viewport images: #{e.message}"
      end

      {
        iso: image_to_base64(iso_path),
        front: image_to_base64(front_path),
        return_view: image_to_base64(return_path),
        top: image_to_base64(top_path)
      }
    end

    def self.set_doors_and_panels_visibility(box_grp, visible)
      hide_sub = lambda do |parent|
        parent.entities.grep(Sketchup::Group).each do |g|
          name = g.name.to_s
          role = g.get_attribute('CBX', 'role').to_s

          # CRITICAL: Structural frame members (Posts, Uprights, Rails, Struts, BoxBars, Feet) must NEVER be hidden!
          if name.include?('Upright') || name.include?('Post') || name.include?('Rail') ||
             name.include?('Strut') || name.include?('BoxBar') || name.include?('Foot') ||
             role.include?('BoxBar') || role.include?('Rail') || role.include?('Post') || role.include?('Upright')
            g.hidden = false
            hide_sub.call(g)
            next
          end

          # Hide only door leaves, drawer faces/boxes, glass infill panes, and cladding panels
          is_leaf = g.get_attribute('CBX', 'is_door_leaf') == true ||
                    name.include?('Door') || name.include?('Drawer') ||
                    name.include?('Sash_Door') || name.include?('Panel') ||
                    name.include?('Glass') || name.include?('Glazed') || name.include?('Infill') ||
                    name.include?('Clad') || name.include?('ACP') ||
                    name.include?('Handle') || name.include?('Finger_Sash') ||
                    role.include?('Sash') || role.include?('Door') || role.include?('Pane') || role.include?('Clad')

          if is_leaf
            g.hidden = !visible
          else
            hide_sub.call(g)
          end
        end
      end
      hide_sub.call(box_grp)
    end

    def self.generate_unit_assembly_breakdown(entities)
      units = []
      unit_num = 1
      cabinet_boxes = []

      # 1. Search for dedicated individual staged pods on the workshop floor
      staging_grp = nil
      staged_pods = []
      find_staging = lambda do |parent_ents|
        parent_ents.grep(Sketchup::Group).each do |g|
          name = g.name.to_s
          if name == 'Workshop_Individual_Cabinet_Pods' || g.get_attribute('CBX', 'is_staging_group') == true
            staging_grp = g
            staged_pods = g.entities.grep(Sketchup::Group).select { |sg| sg.name.start_with?('Staged_Pod_') || sg.get_attribute('CBX', 'is_staged_pod') == true }
          else
            find_staging.call(g.entities) if staged_pods.empty?
          end
        end
      end
      find_staging.call(entities)

      if staged_pods.any?
        cabinet_boxes = staged_pods
      else
        # Recursive collector for discrete cabinet boxes from assembled kitchen
        collect_boxes = lambda do |parent_ents|
          parent_ents.grep(Sketchup::Group).each do |g|
            name = g.name.to_s
            next if name.start_with?('Room_Shell') || name == 'Wall_A' || name == 'Wall_B' || name == 'Wall_C' || name.start_with?('Floor') ||
                    name.include?('Countertop') || name.include?('Granite') || name.include?('Backsplash') ||
                    name.include?('LED_Task') || name.include?('Dimension') || name.include?('Sink_Fixture') ||
                    name.include?('Cooktop') || name.include?('Foot_Frame') || name.include?('Gola') || name.include?('Plinth') ||
                    name.include?('Door_Opening') || name.include?('Window_Opening') || name.include?('Faucet')

            if g.get_attribute('CBX', 'is_cabinet_box') == true || name.start_with?('Unit_') ||
               name.include?('Base_Cabinet') || name.include?('Wall_Cabinet') || name.include?('Tall_Oven') ||
               name.include?('Tall_Pantry') || name.include?('Aluminum_Base') || name.include?('Blind_Corner') ||
               name.include?('Aluminum_Wall') || name.include?('Aluminum_Continuous') || name.include?('Continuous_')
              cabinet_boxes << g
            else
              collect_boxes.call(g.entities)
            end
          end
        end
        collect_boxes.call(entities)
      end

      # 2. Multi-Angle Camera Capture Setup (ISO, Front, Top, Frame Only, X-Ray) with Background Removal
      model = Sketchup.active_model
      view = model.active_view
      camera = view.camera
      temp_dir = File.join(Dir.tmpdir, 'cabinex_reports')
      Dir.mkdir(temp_dir) unless File.exist?(temp_dir)

      # Save state
      saved_eye = camera.eye
      saved_target = camera.target
      saved_up = camera.up
      saved_perspective = camera.perspective?
      saved_transparency = model.rendering_options['ModelTransparency'] rescue false
      saved_draw_ground = model.rendering_options['DrawGround'] rescue false
      saved_draw_horizon = model.rendering_options['DrawHorizon'] rescue false
      saved_bg_color = model.rendering_options['BackgroundColor'] rescue nil

      # Configure clean studio rendering settings (Clean white background, crisp edge lines)
      begin
        model.rendering_options['DrawGround'] = false
        model.rendering_options['DrawHorizon'] = false
        model.rendering_options['BackgroundColor'] = Sketchup::Color.new(255, 255, 255)
        model.rendering_options['EdgeDisplayMode'] = 1
        model.rendering_options['ProfileLines'] = true
      rescue => e
      end

      # Expand continuous runs into their individual bay units
      expanded_boxes = []
      cabinet_boxes.each do |box_grp|
        is_run = box_grp.get_attribute('CBX', 'is_continuous_run') == true
        bay_json = box_grp.get_attribute('CBX', 'bay_units_json')
        if is_run && bay_json
          begin
            require 'json'
            bay_specs = JSON.parse(bay_json)
            wall_label = box_grp.get_attribute('CBX', 'wall_label') || ''
            run_h = box_grp.get_attribute('CBX', 'height_mm')&.to_f || 870.0
            run_d = box_grp.get_attribute('CBX', 'depth_mm')&.to_f || 600.0
            bay_specs.each do |bay|
              bw = bay['width'].to_f
              btype = bay['type'].to_s
              bay_type_label = case btype
                               when 'drawers'    then 'Drawer Base'
                               when 'blind_corner', 'blind' then 'Blind Corner Unit'
                               when 'sink'       then 'Sink Base Unit'
                               when 'cooker'     then 'Cooktop Base'
                               when 'hood'       then 'Hood Bay'
                               when 'open_rack'  then 'Open Display Rack'
                               else 'Door Base Unit'
                               end
              expanded_boxes << {
                _grp: box_grp,
                _virtual_width: bw,
                _bay_type: btype,
                _override_title: "#{wall_label} #{bay_type_label} (#{bw.round}mm)",
                _override_type: bay_type_label,
                _height: run_h,
                _depth: run_d
              }
            end
          rescue => e
            puts "Bay JSON parse error for #{box_grp.name}: #{e.message}"
            expanded_boxes << { _grp: box_grp }
          end
        else
          expanded_boxes << { _grp: box_grp }
        end
      end

      expanded_boxes.each do |entry|
        box_grp = entry[:_grp]
        b_name = box_grp.name.to_s
        clean_name = b_name.gsub(/^Staged_Pod_\d+_/, '').gsub(/^Unit_/, '').gsub('_', ' ')

        is_virtual = entry.key?(:_virtual_width)
        unit_title = entry[:_override_title] || box_grp.get_attribute('CBX', 'unit_title') || "Box #{unit_num}: #{clean_name}"
        unit_type  = entry[:_override_type]  || box_grp.get_attribute('CBX', 'unit_type')  || 'Modular Base Carcass'

        # For virtual bay entries use override dims; otherwise read from group
        if is_virtual
          w_mm = entry[:_virtual_width].to_f
          h_mm = entry[:_height].to_f
          d_mm = entry[:_depth].to_f
        else
          b_name_check = b_name
          unit_type ||= if b_name_check.include?('Tall')
                          'Tall Appliance & Pantry Tower'
                        elsif b_name_check.include?('Drawer')
                          'Multi-Tier Soft-Close Drawer Base'
                        elsif b_name_check.include?('Blind') || b_name_check.include?('Corner')
                          'Blind Corner Base Transition'
                        elsif b_name_check.include?('Base')
                          'Continuous Aluminum Base Run'
                        elsif b_name_check.include?('Top') || b_name_check.include?('Overhead') || b_name_check.include?('Wall_Run')
                          'Overhead Wall Cabinet'
                        elsif b_name_check.include?('Cooker') || b_name_check.include?('Hob')
                          'Cooktop Base Unit'
                        elsif b_name_check.include?('Sink')
                          'Sink & Plumbing Base Unit'
                        else
                          'Modular Base Carcass'
                        end
        end

        # Output file paths
        photo_iso_rel = ""
        photo_front_rel = ""
        photo_top_rel = ""
        photo_frame_rel = ""
        photo_xray_rel = ""

        # No model isolation needed â€” just position camera and capture
        cab_target = box_grp

        begin
          # Identify actual cabinet sub-component if in a staged pod
          if box_grp.respond_to?(:entities)
            sub_cab = box_grp.entities.grep(Sketchup::ComponentInstance).first ||
                      box_grp.entities.grep(Sketchup::Group).find { |g|
                        n = g.name.to_s
                        !n.include?('Text') && !n.include?('Pad') && !n.include?('Label') && !n.include?('Floor')
                      }
            cab_target = sub_cab if sub_cab
          end

          bbox = cab_target.bounds
          center = bbox.center
          diag = [bbox.diagonal, 800.mm].max

          unless is_virtual
            w_mm = box_grp.get_attribute('CBX', 'width_mm')&.to_f || cab_target.get_attribute('CBX', 'width_mm')&.to_f || bbox.width.to_mm.round
            h_mm = box_grp.get_attribute('CBX', 'height_mm')&.to_f || cab_target.get_attribute('CBX', 'height_mm')&.to_f || bbox.height.to_mm.round
            d_mm = box_grp.get_attribute('CBX', 'depth_mm')&.to_f || cab_target.get_attribute('CBX', 'depth_mm')&.to_f || bbox.depth.to_mm.round
          end
          w_mm = 600 if w_mm.nil? || w_mm < 50
          h_mm = 870 if h_mm.nil? || h_mm < 50
          d_mm = 600 if d_mm.nil? || d_mm < 50

          cam_eye_iso = Geom::Point3d.new(center.x + diag * 1.15, center.y - diag * 1.30, center.z + diag * 0.90)

          # Shot 1: 3D Isometric View
          begin
            iso_file = File.join(temp_dir, "box_#{unit_num}_iso.png")
            camera.perspective = true
            camera.set(cam_eye_iso, center, Geom::Vector3d.new(0, 0, 1))
            view.zoom(cab_target)
            view.invalidate
            view.write_image(iso_file, 900, 600, false, 0.9)
            photo_iso_rel = image_to_base64(iso_file)
            puts "  ISO ok: #{File.exist?(iso_file) ? File.size(iso_file) : 0} bytes"
          rescue => e
            puts "Unit #{unit_num} ISO snapshot error: #{e.message}"
          end

          # Shot 2: Front Elevation
          begin
            front_file = File.join(temp_dir, "box_#{unit_num}_front.png")
            camera.perspective = false
            cam_eye_front = Geom::Point3d.new(center.x, center.y - diag * 2.5, center.z)
            camera.set(cam_eye_front, center, Geom::Vector3d.new(0, 0, 1))
            view.zoom(cab_target)
            view.invalidate
            view.write_image(front_file, 900, 600, false, 0.9)
            photo_front_rel = image_to_base64(front_file)
          rescue => e
            puts "Unit #{unit_num} Front snapshot error: #{e.message}"
          end

          # Shot 3: Top Plan View
          begin
            top_file = File.join(temp_dir, "box_#{unit_num}_top.png")
            camera.perspective = false
            cam_eye_top = Geom::Point3d.new(center.x, center.y, center.z + diag * 2.5)
            camera.set(cam_eye_top, center, Geom::Vector3d.new(0, 1, 0))
            view.zoom(cab_target)
            view.invalidate
            view.write_image(top_file, 900, 600, false, 0.9)
            photo_top_rel = image_to_base64(top_file)
          rescue => e
            puts "Unit #{unit_num} Top snapshot error: #{e.message}"
          end

          # Shot 4: Frame Only (doors hidden)
          begin
            frame_file = File.join(temp_dir, "box_#{unit_num}_frame.png")
            set_doors_and_panels_visibility(cab_target, false)
            camera.perspective = true
            camera.set(cam_eye_iso, center, Geom::Vector3d.new(0, 0, 1))
            view.zoom(cab_target)
            view.invalidate
            view.write_image(frame_file, 900, 600, false, 0.9)
            photo_frame_rel = image_to_base64(frame_file)
          rescue => e
            puts "Unit #{unit_num} Frame snapshot error: #{e.message}"
          ensure
            set_doors_and_panels_visibility(cab_target, true) rescue nil
          end

          # Shot 5: X-Ray / Transparency
          begin
            xray_file = File.join(temp_dir, "box_#{unit_num}_xray.png")
            model.rendering_options['ModelTransparency'] = true rescue nil
            camera.perspective = true
            camera.set(cam_eye_iso, center, Geom::Vector3d.new(0, 0, 1))
            view.zoom(cab_target)
            view.invalidate
            view.write_image(xray_file, 900, 600, false, 0.9)
            photo_xray_rel = image_to_base64(xray_file)
          rescue => e
            puts "Unit #{unit_num} X-Ray snapshot error: #{e.message}"
          ensure
            model.rendering_options['ModelTransparency'] = saved_transparency rescue nil
          end

        end # begin block for snapshot capture

        units << {
          unit_number: unit_num,
          title: unit_title,
          type: unit_type,
          width_mm: w_mm.round,
          height_mm: h_mm.round,
          depth_mm: d_mm.round,
          photo: photo_iso_rel,
          photo_iso: photo_iso_rel,
          photo_front: photo_front_rel,
          photo_top: photo_top_rel,
          photo_frame: photo_frame_rel,
          photo_xray: photo_xray_rel
        }
        unit_num += 1
      end

      # Restore camera and rendering options to original state
      begin
        camera.perspective = saved_perspective
        camera.set(saved_eye, saved_target, saved_up)
        model.rendering_options['ModelTransparency'] = saved_transparency if saved_transparency != nil
        model.rendering_options['DrawGround'] = saved_draw_ground if saved_draw_ground != nil
        model.rendering_options['DrawHorizon'] = saved_draw_horizon if saved_draw_horizon != nil
        model.rendering_options['BackgroundColor'] = saved_bg_color if saved_bg_color
        view.zoom_extents
      rescue => e
      end

      units
    end

    def self.calculate_actual_covered_linear_lengths(parent_ents)
      base_mm = 0.0
      top_mm = 0.0
      tall_h_mm = 0.0

      parent_ents.grep(Sketchup::Group).each do |grp|
        next if grp.name.start_with?('Workshop_') || grp.name.start_with?('Staged_') || grp.name.start_with?('Pod_')
        grp.entities.grep(Sketchup::Group).each do |sub|
          next if sub.name.start_with?('Workshop_') || sub.name.start_with?('Staged_') || sub.name.start_with?('Pod_')
          role = sub.get_attribute('CBX', 'cabinet_type').to_s
          w = sub.get_attribute('CBX', 'width_mm')&.to_f || 0.0
          h = sub.get_attribute('CBX', 'height_mm')&.to_f || 0.0
          name = sub.name.to_s

          if role.include?('TALL') || name.include?('Tall')
            tall_h_mm += (h > 0 ? h : 2123.0)
          elsif role.include?('TOP') || role.include?('WALL') || name.include?('Top') || name.include?('Wall')
            top_mm += w
          elsif role.include?('BASE') || name.include?('Base') || name.include?('Main_Wall') || name.include?('Return_Run')
            base_mm += w
          end
        end
      end

      # Fallback if unassigned from specific group hierarchies
      base_mm = 3000.0 if base_mm < 300.0
      top_mm = 2488.0 + 1379.0 if top_mm < 300.0
      tall_h_mm = 2123.0 if tall_h_mm < 300.0

      base_ft = base_mm / 304.8
      top_ft = top_mm / 304.8
      tall_h_ft = tall_h_mm / 304.8
      total_linear_ft = base_ft + top_ft + tall_h_ft

      {
        base_covered_mm: base_mm.round,
        top_covered_mm: top_mm.round,
        tall_height_mm: tall_h_mm.round,
        base_covered_ft: base_ft.round(1),
        top_covered_ft: top_ft.round(1),
        tall_height_ft: tall_h_ft.round(1),
        total_covered_ft: total_linear_ft.round(1)
      }
    end

    def self.show_workshop_report(specs = nil)
      specs ||= (defined?(@last_specs) && @last_specs) ? @last_specs : {}
      report_html = (defined?(__dir__) && __dir__) ? File.join(__dir__, 'cbx_workshop_report.html') : ''
      model = Sketchup.active_model
      bom_data = CBXHybridEngine.generate_bom_and_nesting(model.active_entities)
      images = capture_viewport_images
      units = generate_unit_assembly_breakdown(model.active_entities)
      linear_data = calculate_actual_covered_linear_lengths(model.active_entities)

      room = specs['room'] || {}
      quote = specs['quote'] || {}
      custom_modules = specs['custom_wall_modules'] || {}

      # Calculate drawer count & tall units count
      total_drawers = 0
      total_tall = 0
      has_sink = false
      has_cooker = false

      (custom_modules['A'] || []).concat(custom_modules['B'] || []).each do |m|
        t = (m['type'] || '').to_s
        if t == 'drawers'
          total_drawers += (m['drawer_count'] || 3).to_i
        elsif t == 'tall_oven'
          total_tall += 1
        elsif t == 'sink'
          has_sink = true
        elsif t == 'cooker'
          has_cooker = true
        end
      end
      total_drawers = 3 if total_drawers == 0

      report_payload = {
        date: Time.now.strftime('%d %b %Y'),
        quotation_no: "CBX-QT-#{Time.now.strftime('%Y%m%d')}-#{rand(100..999)}",
        client_name: quote['client_name'] || 'Valued Customer',
        project_name: quote['project_name'] || 'Luxury All-Aluminum Modular Kitchen',
        markup_pct: (quote['markup_pct'] || 35.0).to_f,
        kitchen_type: (specs['style'] && specs['style']['kitchen_type']) || 'FULL_ALU_FRAME',
        wall_a_mm: (room['wall_a_mm'] || 3048).to_i,
        wall_b_mm: (room['wall_b_mm'] || 3048).to_i,
        ceiling_h_mm: (room['ceiling_height_mm'] || 2743).to_i,
        base_h_mm: (room['base_height_mm'] || 870).to_i,
        top_h_mm: (room['top_height_mm'] || 720).to_i,
        tall_h_mm: (room['tall_height_mm'] || 2123).to_i,
        drawer_count: total_drawers,
        tall_units_count: total_tall,
        has_sink: has_sink,
        has_cooker: has_cooker,
        images: images,
        nesting: bom_data[:nesting],
        hardware: bom_data[:hardware],
        raw_bom: bom_data,
        units: units,
        linear_lengths: linear_data,
        custom_rates: quote['custom_rates'] || {}
      }

      # Generate standalone preloaded HTML file for external browser viewing & direct PDF export (supports Cloud preloaded HTML in RAM)
      raw_html = if defined?(CabinexAI::CloudUI::REPORT_B64) && !CabinexAI::CloudUI::REPORT_B64.to_s.empty?
        require 'base64'
        Base64.strict_decode64(CabinexAI::CloudUI::REPORT_B64).force_encoding('UTF-8')
      elsif defined?(CabinexAI::CloudUI::REPORT_HTML) && !CabinexAI::CloudUI::REPORT_HTML.to_s.empty?
        CabinexAI::CloudUI::REPORT_HTML
      elsif File.exist?(report_html.to_s) && !report_html.to_s.empty?
        File.read(report_html)
      else
        ''
      end
      injected_html = raw_html.sub('</head>', "<script>window.__PRELOADED_PAYLOAD__ = #{report_payload.to_json};</script></head>")
      temp_dir = File.join(Dir.tmpdir, 'cabinex_reports')
      Dir.mkdir(temp_dir) unless File.exist?(temp_dir)
      temp_report_path = File.join(temp_dir, "Cabinex_Workshop_Report_#{Time.now.strftime('%Y%m%d_%H%M%S')}.html")
      File.write(temp_report_path, injected_html)

      report_dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "Cabinex AI - Customer Design Presentation & Quotation System",
          :preferences_key => "com.cabinex.workshop_report",
          :scrollable => true,
          :resizable => true,
          :width => 1180,
          :height => 900,
          :style => UI::HtmlDialog::STYLE_DIALOG
        }
      )

      report_dialog.set_html(injected_html)

      report_dialog.add_action_callback("openInBrowser") do |_context|
        begin
          UI.openURL("file:///#{temp_report_path.tr('\\', '/')}")
        rescue => e
          puts "Open in external browser error: #{e.message}"
        end
      end

      report_dialog.add_action_callback("ready") do |_context|
        report_dialog.execute_script("initializeReport(#{report_payload.to_json})")
      end
      report_dialog.show
      # Small delay fallback to ensure DOM is ready
      UI.start_timer(0.4, false) do
        report_dialog.execute_script("initializeReport(#{report_payload.to_json})")
      end
    end

    def self.prepare_materials(model)
      mats = {
        wood: model.materials['White ACP Cladding'] || model.materials.add('White ACP Cladding'),
        carcase_alu: model.materials['Alu Carcase BoxBar Matte Black'] || model.materials.add('Alu Carcase BoxBar Matte Black'),
        boxbar: model.materials['Alu BoxBar Gray'] || model.materials.add('Alu BoxBar Gray'),
        sash_alu: model.materials['Alu Door Sash Gloss Anthracite'] || model.materials.add('Alu Door Sash Gloss Anthracite'),
        alu: model.materials['Alu Carcase BoxBar Matte Black'] || model.materials.add('Alu Carcase BoxBar Matte Black'),
        glass: model.materials['Glass Translucent Clear'] || model.materials.add('Glass Translucent Clear'),
        acp: model.materials['White ACP Cladding'] || model.materials.add('White ACP Cladding'),
        door_acp: model.materials['Door ACP Infill Gloss Panel'] || model.materials.add('Door ACP Infill Gloss Panel'),
        gola: model.materials['Gola Aluminum Extrusion'] || model.materials.add('Gola Aluminum Extrusion'),
        appliance: model.materials['Dark Appliance Glass'] || model.materials.add('Dark Appliance Glass'),
        hole: model.materials['Hole Dark'] || model.materials.add('Hole Dark'),
        hinge: model.materials['Hinge Marker Red'] || model.materials.add('Hinge Marker Red'),
        edge: model.materials['Edge Line Black'] || model.materials.add('Edge Line Black'),
        cooktop: model.materials['Ceramic Cooktop'] || model.materials.add('Ceramic Cooktop'),
        hood: model.materials['Stainless Steel Hood'] || model.materials.add('Stainless Steel Hood'),
        wall: model.materials['Room Wall Gray'] || model.materials.add('Room Wall Gray'),
        floor: model.materials['Room Floor Tile'] || model.materials.add('Room Floor Tile'),
        window_frame: model.materials['Window Frame Dark'] || model.materials.add('Window Frame Dark'),
        granite: model.materials['Black Granite Polished'] || model.materials.add('Black Granite Polished'),
        backsplash_tile: model.materials['Ceramic Backsplash Tile'] || model.materials.add('Ceramic Backsplash Tile'),
        led_light: model.materials['Warm LED Strip Light'] || model.materials.add('Warm LED Strip Light'),
        sink_chrome: model.materials['Stainless Steel Sink'] || model.materials.add('Stainless Steel Sink'),
        faucet: model.materials['Chrome Faucet'] || model.materials.add('Chrome Faucet')
      }
      mats[:wood].color = Sketchup::Color.new(255, 253, 240)
      mats[:carcase_alu].color = Sketchup::Color.new(120, 124, 130) # BoxBar — medium gray
      mats[:sash_alu].color = Sketchup::Color.new(200, 203, 208)   # Sash — lighter gray
      mats[:alu].color = Sketchup::Color.new(120, 124, 130)        # BoxBar alias — medium gray
      mats[:boxbar].color = Sketchup::Color.new(120, 124, 130) if mats[:boxbar]
      mats[:glass].color = Sketchup::Color.new(200, 230, 245)
      mats[:glass].alpha = 0.40
      mats[:acp].color = Sketchup::Color.new(255, 220, 60)        # Cover/cladding ACP — yellow (visibility)
      mats[:door_acp].color = Sketchup::Color.new(250, 250, 252)  # Door infill ACP — white
      mats[:gola].color = Sketchup::Color.new(150, 154, 160)
      mats[:appliance].color = Sketchup::Color.new(30, 32, 36)
      mats[:hole].color = Sketchup::Color.new(15, 15, 15)
      mats[:hinge].color = Sketchup::Color.new(220, 20, 30) if mats[:hinge]  # hinge markers red
      mats[:edge].color = Sketchup::Color.new(10, 10, 10) if mats[:edge]    # edge highlights black
      mats[:cooktop].color = Sketchup::Color.new(20, 20, 22)
      mats[:hood].color = Sketchup::Color.new(195, 200, 205)
      mats[:wall].color = Sketchup::Color.new(235, 236, 238)
      mats[:floor].color = Sketchup::Color.new(210, 212, 215)
      mats[:window_frame].color = Sketchup::Color.new(50, 52, 58)
      mats[:granite].color = Sketchup::Color.new(20, 22, 26)
      mats[:backsplash_tile].color = Sketchup::Color.new(245, 247, 250)
      mats[:led_light].color = Sketchup::Color.new(255, 248, 220)
      mats[:sink_chrome].color = Sketchup::Color.new(205, 210, 218)
      mats[:faucet].color = Sketchup::Color.new(230, 235, 242)
      mats
    end

    def self.place_return_run(group, corner_x, blind_return = BASE_BLIND_RETURN)
      rotation = Geom::Transformation.rotation(
        Geom::Point3d.new(0, 0, 0), Geom::Vector3d.new(0, 0, 1),
        -90.degrees
      )
      translation = Geom::Transformation.translation(
        [corner_x, -blind_return, 0]
      )
      group.transform!(translation * rotation)
    end

    def self.place_left_return_run(group, total_run_len, corner_offset_c = BASE_BLIND_RETURN)
      rotation = Geom::Transformation.rotation(
        Geom::Point3d.new(0, 0, 0), Geom::Vector3d.new(0, 0, 1),
        90.degrees
      )
      translation = Geom::Transformation.translation(
        [0, -(corner_offset_c + total_run_len), 0]
      )
      group.transform!(translation * rotation)
    end

    def self.place_island_run(group, island_x, island_y)
      translation = Geom::Transformation.translation([island_x, island_y, 0])
      group.transform!(translation)
    end

    # Intelligent aesthetic door/bay division algorithm:
    # Keeps individual door leaves in the golden 400mm - 500mm aesthetic range (and top cabinets 350-450mm).
    # Divides runs into clean, mathematically balanced bays.
    # Max bottom door width 600mm (up to 1200mm for 2-door bay with no center post).
    # Max top door width 450mm (up to 900mm for 2-door bay with no center post).
    def self.split_bays(total_width, max_limit = nil, is_top: false)
      total_w = total_width.to_f
      return [] if total_w <= 50.mm
      
      max_comfortable_bay = max_limit || (is_top ? MAX_TOP_WIDTH : MAX_BOTTOM_WIDTH)

      # If total span is already within comfortable bay limit, return it directly
      if total_w <= max_comfortable_bay
        return [total_w]
      end

      target_bay = is_top ? 750.mm : 900.mm
      count = (total_w / target_bay).round
      count = 1 if count < 1

      while (total_w / count.to_f) > max_comfortable_bay
        count += 1
      end
      while count > 1 && (total_w / count.to_f) < (is_top ? 450.mm : 600.mm)
        count -= 1
      end

      bay_w = total_w / count.to_f
      Array.new(count, bay_w)
    end

    # Evaluates and decides whether the blind corner unit should be hosted on Wall A or Wall B.
    # Requirement: Guarantees corner door opening >= 450mm and prevents cramping the other wall's modules.
    def self.determine_corner_wall_placement(wall_a, wall_b, has_tall = false, custom_modules = nil)
      if custom_modules
        return 'B' if custom_modules['B']&.any? { |b| (b['type'] || '').to_s == 'blind_corner' }
        return 'A' if custom_modules['A']&.any? { |b| (b['type'] || '').to_s == 'blind_corner' }
      end
      return 'A' if wall_b <= 0.mm

      tall_w = has_tall ? TALL_WIDTH : 0.mm
      rem_b_if_corner_on_a = wall_b - BASE_BLIND_RETURN - tall_w
      if rem_b_if_corner_on_a < MIN_CORNER_DOOR_OPENING
        return 'B'
      end

      opening_on_a = [wall_a - 1200.mm - BASE_BLIND_RETURN, MIN_CORNER_DOOR_OPENING].max
      opening_on_b = wall_b - BASE_BLIND_RETURN
      (opening_on_b > opening_on_a && (wall_a - BASE_BLIND_RETURN) >= 1200.mm) ? 'B' : 'A'
    end

    def self.build_room_shell_with_openings(ents, wall_a, wall_b, wall_c, ceiling_h, openings, mats, custom_modules = nil)
      room = ents.add_group
      room.name = "Room_Shell_#{wall_a.to_mm.round}x#{wall_b.to_mm.round}"
      sub = room.entities
      wall_thick = 150.mm

      # 1. Floor (Extended to outer perimeter)
      max_y_bound = [wall_b, wall_c, (custom_modules && custom_modules['Island'] && custom_modules['Island'].any? ? 2400.mm : 0.mm)].max
      floor_pts = [
        [-wall_thick, wall_thick, -5.mm],
        [wall_a + wall_thick, wall_thick, -5.mm],
        [wall_a + wall_thick, -max_y_bound - wall_thick, -5.mm],
        [-wall_thick, -max_y_bound - wall_thick, -5.mm]
      ]
      floor = sub.add_face(floor_pts)
      floor.material = mats[:floor] if floor

      # 2. Wall A (Back Wall along Y=0..wall_thick)
      wall_a_group = sub.add_group
      wall_a_group.name = "Wall_A"
      w_ents = wall_a_group.entities
      
      f_a = w_ents.add_face([[-wall_thick, 0, 0], [wall_a + wall_thick, 0, 0], [wall_a + wall_thick, wall_thick, 0], [-wall_thick, wall_thick, 0]])
      if f_a
        f_a.reverse! if f_a.normal.z < 0
        f_a.pushpull(ceiling_h)
      end
      wall_a_group.material = mats[:wall]

      # 3. Wall B (Right Wall along X=wall_a..wall_a+wall_thick)
      if wall_b > 0
        wall_b_group = sub.add_group
        wall_b_group.name = "Wall_B"
        wb_ents = wall_b_group.entities
        f_b = wb_ents.add_face([
          [wall_a, wall_thick, 0],
          [wall_a + wall_thick, wall_thick, 0],
          [wall_a + wall_thick, -wall_b, 0],
          [wall_a, -wall_b, 0]
        ])
        if f_b
          f_b.reverse! if f_b.normal.z < 0
          f_b.pushpull(ceiling_h)
        end
        wall_b_group.material = mats[:wall]
      end

      # 3b. Wall C (Left Wall along X=-wall_thick..0)
      if wall_c > 0
        wall_c_group = sub.add_group
        wall_c_group.name = "Wall_C"
        wc_ents = wall_c_group.entities
        f_c = wc_ents.add_face([
          [-wall_thick, wall_thick, 0],
          [0, wall_thick, 0],
          [0, -wall_c, 0],
          [-wall_thick, -wall_c, 0]
        ])
        if f_c
          f_c.reverse! if f_c.normal.z < 0
          f_c.pushpull(ceiling_h)
        end
        wall_c_group.material = mats[:wall]
      end

      # 4. Openings with Real-World Physical Collision Check (Never penetrate tall towers)
      list = openings['__list__'] || []
      if list.empty?
        # Legacy fallback
        if openings['window_wall'] && openings['window_wall'] != 'none'
          list << {
            'type' => 'window',
            'wall' => openings['window_wall'],
            'offset' => openings['window_offset_mm'] || 1200,
            'width' => openings['window_width_mm'] || 1200,
            'height' => openings['window_sill_mm'] || 1050
          }
        end
        if openings['door_wall'] && openings['door_wall'] != 'none'
          list << {
            'type' => 'door',
            'wall' => openings['door_wall'],
            'offset' => openings['door_offset_mm'] || 2400,
            'width' => openings['door_width_mm'] || 900,
            'height' => 2100
          }
        end
      end

      list.each_with_index do |op, idx|
        op_wall = op['wall']
        op_offset = op['offset'].to_f.mm
        op_width = op['width'].to_f.mm
        op_type = op['type']
        
        if op_type == 'window'
          w_sill = op['height'].to_f.mm
          w_height = 1100.mm
          win_group = sub.add_group
          win_group.name = "Window_Opening_#{idx}"
          win_ents = win_group.entities
          
          if op_wall == 'A'
            a_list = (custom_modules && custom_modules['A']) || []
            has_tall_a = a_list.any? { |b| (b['type'] || '').to_s == 'tall_oven' || (b['type'] || '').to_s == 'tall_pantry' }
            max_win_a = has_tall_a ? [wall_a - 600.mm, 0.mm].max : wall_a
            w_end = [op_offset + op_width, max_win_a].min
            if w_end > op_offset + 100.mm
              frame = win_ents.add_face([
                [op_offset, 0, w_sill], [w_end, 0, w_sill],
                [w_end, 0, w_sill + w_height], [op_offset, 0, w_sill + w_height]
              ])
              frame.material = mats[:glass] if frame
            end
          elsif op_wall == 'B' && wall_b > 0
            b_list = (custom_modules && custom_modules['B']) || []
            has_tall_b = b_list.any? { |b| (b['type'] || '').to_s == 'tall_oven' || (b['type'] || '').to_s == 'tall_pantry' }
            tall_b_w = has_tall_b ? 600.mm : 0.mm
            max_win_reach = [wall_b - tall_b_w, 0.mm].max
            w_end = [op_offset + op_width, max_win_reach].min
            if w_end > op_offset + 100.mm
              frame = win_ents.add_face([
                [wall_a, -op_offset, w_sill], [wall_a, -w_end, w_sill],
                [wall_a, -w_end, w_sill + w_height], [wall_a, -op_offset, w_sill + w_height]
              ])
              frame.material = mats[:glass] if frame
            end
          end
        else
          d_height = op_type == 'door' ? 2100.mm : op['height'].to_f.mm
          door_group = sub.add_group
          door_group.name = "#{op_type.capitalize}_Opening_#{idx}"
          door_ents = door_group.entities
          
          if op_wall == 'A'
            f = door_ents.add_face([
              [op_offset, 0, 0], [op_offset + op_width, 0, 0],
              [op_offset + op_width, 0, d_height], [op_offset, 0, d_height]
            ])
            f.material = mats[:window_frame] if f
          elsif op_wall == 'B' && wall_b > 0
            f = door_ents.add_face([
              [wall_a, -op_offset, 0], [wall_a, -op_offset - op_width, 0],
              [wall_a, -op_offset - op_width, d_height], [wall_a, -op_offset, d_height]
            ])
            f.material = mats[:window_frame] if f
          end
        end
      end
    end

    def self.build_cooktop_and_hood(main_ents, cooker_x, cooker_w, top_z, mats)
      cooktop_w = [cooker_w - 100.mm, 450.mm].max
      ct_group = main_ents.add_group
      ct_group.name = 'Cooktop_Appliance'
      ct_face = ct_group.entities.add_face([
        [cooker_x + (cooker_w - cooktop_w) / 2.0, -510.mm, 870.mm],
        [cooker_x + (cooker_w + cooktop_w) / 2.0, -510.mm, 870.mm],
        [cooker_x + (cooker_w + cooktop_w) / 2.0, -90.mm, 870.mm],
        [cooker_x + (cooker_w - cooktop_w) / 2.0, -90.mm, 870.mm]
      ])
      ct_face.pushpull(12.mm) if ct_face
      ct_group.material = mats[:cooktop]

      hood_group = main_ents.add_group
      hood_group.name = 'Slim_Hood_Cassette_600mm'
      hood_x = cooker_x + (cooker_w - SLIM_HOOD_WIDTH) / 2.0
      hood_z = top_z + (HOOD_CLEARANCE - SLIM_HOOD_HEIGHT) / 2.0
      hf = hood_group.entities.add_face([
        [hood_x, -350.mm, hood_z],
        [hood_x + SLIM_HOOD_WIDTH, -350.mm, hood_z],
        [hood_x + SLIM_HOOD_WIDTH, -50.mm, hood_z],
        [hood_x, -50.mm, hood_z]
      ])
      hf.pushpull(SLIM_HOOD_HEIGHT) if hf
      hood_group.material = mats[:hood]
    end

    def self.add_tall_interior_shelves(sub_ents, width, height, depth, mats)
      shelf_count = 4
      spacing = height / (shelf_count + 1).to_f

      pw = CBXHybridEngine::PROFILE_WIDTH   # 25.4mm
      ph = CBXHybridEngine::PROFILE_HEIGHT  # 38.1mm
      sash_thick = CBXHybridEngine::SASH_THICKNESS # 21.2mm

      # Clearances inside aluminum carcase to guarantee realistic assembly without material collisions:
      # X-Axis: 2.0mm clearance on left and right inside the vertical BoxBar posts
      # Y-Axis: 12.0mm clearance in front of rear ACP cladding and 12.0mm behind front door/frame
      margin_x = 2.0.mm
      margin_y_back = 12.0.mm
      margin_y_front = 12.0.mm

      shelf_w = [width - 2 * pw - 2 * margin_x, 100.mm].max
      shelf_d = [depth - 2 * pw - margin_y_back - margin_y_front, 100.mm].max
      shelf_x0 = pw + margin_x
      shelf_y0 = -pw - margin_y_back

      (1..shelf_count).each do |i|
        sz = (i * spacing).round(2)

        # Pre-check: Avoid collision with bottom/top structural rails
        next if sz < ph + 10.mm || sz + sash_thick > height - ph - 10.mm

        # 1. Build authentic 4-sided mitered Sash Frame with Glazed Glass Infill Pane
        # Rotate +90 degrees around local X-axis:
        # Transforms X -> X, Y -> Z (upward thickness 21.2mm), Z -> -Y (inward depth extending from back towards front)
        sash_shelf = CBXHybridEngine.build_horizontal_sash_shelf(
          sub_ents, shelf_w, shelf_d, shelf_x0, shelf_y0, sz,
          mats, "Aluminum_Sash_Glazed_Shelf_#{i}"
        )
        sash_shelf.set_attribute('CBX', 'shelf_index', i)

        # 2. Post-Check Conformity Verification:
        # Asserts that the shelf sits 100% strictly within the internal cavity bounds
        bbox = sash_shelf.bounds
        tol = 1.0.mm
        min_cavity_x = pw
        max_cavity_x = width - pw
        min_cavity_y = -depth + pw
        max_cavity_y = -pw

        valid_x = bbox.min.x >= (min_cavity_x - tol) && bbox.max.x <= (max_cavity_x + tol)
        valid_y = bbox.min.y >= (min_cavity_y - tol) && bbox.max.y <= (max_cavity_y + tol)
        valid_z = bbox.min.z >= (0 - tol) && bbox.max.z <= (height + tol)

        unless valid_x && valid_y && valid_z
          puts "[CBX Conformity Warning] Shelf #{i} outside cavity bounds! bbox: #{bbox.min}..#{bbox.max}"
        end

        # 3. Four Heavy-Duty Chrome Corner Support Clips / Pins (14x14x14mm)
        # Positioned flush against the inner face of the 4 vertical Box-Bar posts, supporting the shelf frame from underneath
        clip_w = 14.mm
        clip_d = 14.mm
        clip_h = 14.mm
        clip_z0 = sz - clip_h

        clips_defs = [
          # Rear-Left (mounted on rear-left post X=0..pw, Y=-pw..0)
          [pw, -pw - clip_d],
          # Rear-Right (mounted on rear-right post X=width-pw..width, Y=-pw..0)
          [width - pw - clip_w, -pw - clip_d],
          # Front-Left (mounted on front-left post X=0..pw, Y=-depth..-depth+pw)
          [pw, -depth + pw],
          # Front-Right (mounted on front-right post X=width-pw..width, Y=-depth..-depth+pw)
          [width - pw - clip_w, -depth + pw]
        ]

        clips_defs.each_with_index do |(cx, cy), c_idx|
          c_grp = sub_ents.add_group
          c_grp.name = "Shelf_#{i}_Support_Clip_#{c_idx + 1}"
          c_face = c_grp.entities.add_face([
            [cx, cy, clip_z0],
            [cx + clip_w, cy, clip_z0],
            [cx + clip_w, cy + clip_d, clip_z0],
            [cx, cy + clip_d, clip_z0]
          ])
          c_face.pushpull(clip_h) if c_face
          c_grp.material = mats[:faucet] || mats[:sink_chrome]
          c_grp.set_attribute('CBX', 'role', 'Shelf_Support_Clip')
        end
      end
    end

    def self.build_granite_countertop_backsplash_and_fixtures(ents, wall_a, wall_b, wall_c, base_h, top_z, custom_modules, openings, mats)
      gt_group = ents.add_group
      gt_group.name = 'Solid_Granite_Countertop_Pack'
      gt_ents = gt_group.entities

      granite_thick = 30.mm
      counter_d = 620.mm # 600mm base depth + 20mm front overhang
      splash_thick = 12.mm

      a_list = (custom_modules && custom_modules['A']) || []
      b_list = (custom_modules && custom_modules['B']) || []
      c_list = (custom_modules && custom_modules['C']) || []
      isl_list = (custom_modules && custom_modules['Island']) || []

      # Helper to create upward extruded solid granite slab (870mm -> 900mm)
      add_granite_slab = lambda do |pts, name|
        f = gt_ents.add_face(pts)
        if f
          f.reverse! if f.normal.z < 0 # Ensure top normal points +Z
          f.pushpull(granite_thick)    # Extrudes UPWARD above cabinet carcase
        end
      end

      # 1. Wall A Solid Granite Countertop (Full continuous run across back wall)
      has_tall_a_start = a_list.first && ((a_list.first['type'] || '').to_s == 'tall_oven' || (a_list.first['type'] || '').to_s == 'tall_pantry')
      tall_a_start_w = has_tall_a_start ? (a_list.first['width'] || 600).to_f.mm : 0.mm

      has_tall_a_end = a_list.last && a_list.length > 1 && ((a_list.last['type'] || '').to_s == 'tall_oven' || (a_list.last['type'] || '').to_s == 'tall_pantry')
      tall_a_end_w = has_tall_a_end ? (a_list.last['width'] || 600).to_f.mm : 0.mm

      ga_x_start = (wall_c > 0) ? 0.mm : tall_a_start_w
      ga_x_end = (wall_b > 0) ? wall_a : (wall_a - tall_a_end_w)
      ga_w = [ga_x_end - ga_x_start, 0.mm].max

      if ga_w > 0
        # Divide into standard 2440mm (8ft) material slabs if longer than 2440mm
        max_slab_len = 2440.mm
        num_slabs = (ga_w / max_slab_len).ceil
        slab_w = ga_w / num_slabs
        num_slabs.times do |s_idx|
          x0 = ga_x_start + s_idx * slab_w
          x1 = ga_x_start + (s_idx + 1) * slab_w
          add_granite_slab.call([
            [x0, 0, base_h],
            [x1, 0, base_h],
            [x1, -counter_d, base_h],
            [x0, -counter_d, base_h]
          ], "Wall_A_Granite_Slab_#{s_idx + 1}")
        end
      end

      # 2. Wall B Solid Granite Countertop (Right Return Run - seamless butt joint at Wall A)
      if wall_b > 0
        base_b_modules = b_list.reject { |b| (b['type'] || '').to_s == 'tall_oven' || (b['type'] || '').to_s == 'tall_pantry' }
        has_tall_b = b_list.any? { |b| (b['type'] || '').to_s == 'tall_oven' || (b['type'] || '').to_s == 'tall_pantry' }
        tall_w_b = has_tall_b ? 600.mm : 0.mm
        gb_end_y = [wall_b - tall_w_b, counter_d + 100.mm].max

        gb_span = gb_end_y - counter_d
        if gb_span > 0
          add_granite_slab.call([
            [wall_a - counter_d, -counter_d, base_h],
            [wall_a, -counter_d, base_h],
            [wall_a, -gb_end_y, base_h],
            [wall_a - counter_d, -gb_end_y, base_h]
          ], "Wall_B_Granite_Return_Slab")
        end
      end

      # 3. Wall C Solid Granite Countertop (Left Return Run - seamless butt joint at Wall A)
      if wall_c > 0 && c_list.any?
        has_bar_counter = (project_settings && (project_settings['has_bar_counter'] == true || project_settings['layout_archetype'] == 'U_BAR_BULKHEAD'))
        counter_d_c = has_bar_counter ? 900.mm : counter_d # 300mm extended seating overhang for breakfast bar
        base_c_modules = c_list.reject { |b| (b['type'] || '').to_s == 'tall_oven' || (b['type'] || '').to_s == 'tall_pantry' }
        has_tall_c = c_list.any? { |b| (b['type'] || '').to_s == 'tall_oven' || (b['type'] || '').to_s == 'tall_pantry' }
        tall_w_c = has_tall_c ? 600.mm : 0.mm
        gc_end_y = [wall_c - tall_w_c, counter_d + 100.mm].max

        gc_span = gc_end_y - counter_d
        if gc_span > 0
          add_granite_slab.call([
            [0, -counter_d, base_h],
            [counter_d_c, -counter_d, base_h],
            [counter_d_c, -gc_end_y, base_h],
            [0, -gc_end_y, base_h]
          ], "Wall_C_Granite_Return_Slab")
        end
      end

      # 4. Island Solid Granite Countertop
      if isl_list.any?
        total_isl_w = isl_list.sum { |b| (b['width'] || 600).to_f.mm }
        isl_x = [(wall_a - total_isl_w) / 2.0, 0.mm].max
        
        if wall_c > 0 && wall_b > 0
          mid_u_depth = [wall_b, wall_c].min
          if mid_u_depth >= 2200.mm
            isl_y = -600.mm - 900.mm
          else
            isl_y = -[wall_b, wall_c].max - 1000.mm
          end
        else
          isl_y = -[wall_b, wall_c, 800.mm].max - 1100.mm
        end
        
        isl_overhang = 20.mm
        add_granite_slab.call([
          [isl_x - isl_overhang, isl_y + isl_overhang, base_h],
          [isl_x + total_isl_w + isl_overhang, isl_y + isl_overhang, base_h],
          [isl_x + total_isl_w + isl_overhang, isl_y - counter_d - isl_overhang, base_h],
          [isl_x - isl_overhang, isl_y - counter_d - isl_overhang, base_h]
        ], "Island_Granite_Slab")
      end

      gt_group.material = mats[:granite]

      # 3. Tiled Backsplash Wall (Wall A & Wall B)
      bs_group = ents.add_group
      bs_group.name = 'Designer_Tiled_Backsplash_Wall'
      bs_ents = bs_group.entities

      splash_z0 = base_h + granite_thick
      splash_h = [top_z - splash_z0, 450.mm].max

      # Wall A Backsplash: Exactly matching countertop span!
      if ga_w > 0
        ba_face = bs_ents.add_face([
          [ga_x_start, -1.mm, splash_z0],
          [ga_x_end,   -1.mm, splash_z0],
          [ga_x_end,   -1.mm, splash_z0 + splash_h],
          [ga_x_start, -1.mm, splash_z0 + splash_h]
        ])
        ba_face.pushpull(-splash_thick) if ba_face
      end

      # Wall B Backsplash: Exactly matching return countertop span (Stopping BEFORE tall unit)!
      if wall_b > 0 && gb_span && gb_span > 0
        bb_end_y = -gb_end_y
        bb_face = bs_ents.add_face([
          [wall_a - 1.mm, 0, splash_z0],
          [wall_a - 1.mm, bb_end_y, splash_z0],
          [wall_a - 1.mm, bb_end_y, splash_z0 + splash_h],
          [wall_a - 1.mm, 0, splash_z0 + splash_h]
        ])
        bb_face.pushpull(splash_thick) if bb_face
      end

      # Wall C Backsplash: Exactly matching left return countertop span (Stopping BEFORE tall unit)!
      if wall_c > 0 && gc_span && gc_span > 0
        bc_end_y = -gc_end_y
        bc_face = bs_ents.add_face([
          [1.mm, 0, splash_z0],
          [1.mm, bc_end_y, splash_z0],
          [1.mm, bc_end_y, splash_z0 + splash_h],
          [1.mm, 0, splash_z0 + splash_h]
        ])
        bc_face.pushpull(-splash_thick) if bc_face
      end

      bs_group.material = mats[:tile]

      # 4. Concealed Linear Under-Cabinet LED Task Strip Lighting
      # (Strictly positioned UNDER overhead top cabinet boxes only - child of top cabinet span)
      led_group = ents.add_group
      led_group.name = 'Under_Cabinet_LED_Task_Lighting'
      led_ents = led_group.entities

      # Wall A LEDs (Only where top cabinets exist)
      a_list = (custom_modules && custom_modules['A']) || []
      cur_x = 0.mm
      if a_list.any?
        a_list.each do |box|
          bw = (box['width'] || 600).to_f.mm
          b_type = (box['type'] || 'door').to_s
          has_ovh = (box['overhead'] || 'yes').to_s

          if has_ovh != 'none' && b_type != 'tall_oven' && b_type != 'tall_pantry'
            led_z = (has_ovh == 'hood') ? (top_z + 6.inch - 8.mm) : (top_z - 8.mm)
            x_start = cur_x + 10.mm
            x_end   = cur_x + bw - 10.mm
            if x_end > x_start
              l_face = led_ents.add_face([
                [x_start, -330.mm, led_z],
                [x_end,   -330.mm, led_z],
                [x_end,   -305.mm, led_z],
                [x_start, -305.mm, led_z]
              ])
              l_face.pushpull(8.mm) if l_face
            end
          end
          cur_x += bw
        end
      else
        # Default run fallback: skip cooker hood elevation
        l_face = led_ents.add_face([
          [10.mm, -330.mm, top_z - 8.mm],
          [[wall_a - 10.mm, 100.mm].max, -330.mm, top_z - 8.mm],
          [[wall_a - 10.mm, 100.mm].max, -305.mm, top_z - 8.mm],
          [10.mm, -305.mm, top_z - 8.mm]
        ])
        l_face.pushpull(8.mm) if l_face
      end

      # Wall B LEDs (Only where top cabinets exist before window/tall unit)
      if wall_b > 0
        b_list = (custom_modules && custom_modules['B']) || []
        w_on_b = (openings && openings['window_wall'] == 'B')
        w_offset_b = (openings && (openings['window_offset_mm'] || 1200).to_f.mm) || 1200.mm

        cur_ret = TOP_BLIND_RETURN
        b_list.each do |box|
          bw = (box['width'] || 600).to_f.mm
          b_type = (box['type'] || 'door').to_s
          has_ovh = (box['overhead'] || 'yes').to_s

          # If window starts before this top unit position on Wall B, stop placing LEDs
          if w_on_b && (cur_ret + 100.mm >= w_offset_b)
            break
          end

          if has_ovh != 'none' && b_type != 'tall_oven' && b_type != 'tall_pantry'
            led_z = (has_ovh == 'hood') ? (top_z + 6.inch - 8.mm) : (top_z - 8.mm)
            y_start = cur_ret + 10.mm
            y_end   = cur_ret + bw - 10.mm
            if w_on_b && y_end > w_offset_b
              y_end = [w_offset_b - 10.mm, y_start].max
            end

            if y_end > y_start
              lb_face = led_ents.add_face([
                [wall_a - 330.mm, -y_start, led_z],
                [wall_a - 330.mm, -y_end,   led_z],
                [wall_a - 305.mm, -y_end,   led_z],
                [wall_a - 305.mm, -y_start, led_z]
              ])
              lb_face.pushpull(8.mm) if lb_face
            end
          end
          cur_ret += bw
        end
      end
      led_group.material = mats[:led_light]

      # 5. Stainless Undermount Sink & Chrome Gooseneck Mixer Faucet
      build_sink_and_faucet_fixtures(ents, wall_a, wall_b, base_h, custom_modules, mats)
    end

    def self.build_top_bulkhead_soffit(ents, wall_a, wall_b, wall_c, top_z, top_h, ceiling_h, custom_modules, mats)
      return if ceiling_h <= (top_z + top_h + 50.mm)
      
      bh_grp = ents.add_group
      bh_grp.name = 'Top_Bulkhead_Ceiling_Soffit_Pack'
      bh_ents = bh_grp.entities
      
      bh_z0 = top_z + top_h
      bh_height = ceiling_h - bh_z0
      bh_depth = 360.mm
      
      # Wall A Bulkhead Soffit
      f_a = bh_ents.add_face([
        [0, 0, bh_z0],
        [wall_a, 0, bh_z0],
        [wall_a, -bh_depth, bh_z0],
        [0, -bh_depth, bh_z0]
      ])
      if f_a
        f_a.reverse! if f_a.normal.z < 0
        f_a.pushpull(bh_height)
      end
      
      # Wall B Bulkhead Soffit
      if wall_b > 0
        f_b = bh_ents.add_face([
          [wall_a - bh_depth, -bh_depth, bh_z0],
          [wall_a, -bh_depth, bh_z0],
          [wall_a, -wall_b, bh_z0],
          [wall_a - bh_depth, -wall_b, bh_z0]
        ])
        if f_b
          f_b.reverse! if f_b.normal.z < 0
          f_b.pushpull(bh_height)
        end
      end
      
      # Wall C Bulkhead Soffit (if top units exist on C)
      c_list = (custom_modules && custom_modules['C']) || []
      has_c_top = c_list.any? { |b| (b['overhead'] || 'yes').to_s != 'none' }
      if wall_c > 0 && has_c_top
        f_c = bh_ents.add_face([
          [0, -bh_depth, bh_z0],
          [bh_depth, -bh_depth, bh_z0],
          [bh_depth, -wall_c, bh_z0],
          [0, -wall_c, bh_z0]
        ])
        if f_c
          f_c.reverse! if f_c.normal.z < 0
          f_c.pushpull(bh_height)
        end
      end
      
      bh_grp.material = mats[:wall] || mats[:tile]
    end

    def self.build_sink_and_faucet_fixtures(ents, wall_a, wall_b, base_h, custom_modules, mats)
      a_list = (custom_modules && custom_modules['A']) || []
      b_list = (custom_modules && custom_modules['B']) || []

      sink_on_a = false
      sink_on_b = false
      sink_x = 0.mm
      sink_y = 0.mm

      # 1. Search Wall A for explicit sink module
      cur_x = 0.mm
      a_list.each do |b|
        bw = (b['width'] || 600).to_f.mm
        if b['type'].to_s == 'sink'
          sink_on_a = true
          sink_x = cur_x + bw / 2.0
          sink_y = -310.mm
          break
        end
        cur_x += bw
      end

      # 2. Search Wall B for explicit sink module
      unless sink_on_a
        has_corner_on_b = b_list.any? { |b| (b['type'] || '').to_s == 'blind_corner' }
        cur_y = has_corner_on_b ? 0.mm : BASE_BLIND_RETURN
        b_list.each do |b|
          bw = (b['width'] || 600).to_f.mm
          if b['type'].to_s == 'sink'
            sink_on_b = true
            sink_x = wall_a - 310.mm
            sink_y = -(cur_y + bw / 2.0)
            break
          end
          cur_y += bw
        end
      end

      # 3. Fallback if no explicit sink module in custom modules
      if !sink_on_a && !sink_on_b
        if b_list.any?
          has_corner_on_b = b_list.any? { |b| (b['type'] || '').to_s == 'blind_corner' }
          cur_y = has_corner_on_b ? 0.mm : BASE_BLIND_RETURN
          b_list.each do |b|
            bw = (b['width'] || 600).to_f.mm
            b_type = (b['type'] || '').to_s
            if b_type != 'tall_oven' && b_type != 'tall_pantry' && b_type != 'blind_corner'
              sink_on_b = true
              sink_x = wall_a - 310.mm
              sink_y = -(cur_y + bw / 2.0)
              break
            end
            cur_y += bw
          end
        elsif wall_b > 600.mm
          return_avail = wall_b - BASE_BLIND_RETURN
          sink_on_b = true
          sink_x = wall_a - 310.mm
          sink_y = -(BASE_BLIND_RETURN + [return_avail / 2.0, 450.mm].min)
        else
          sink_on_a = true
          sink_x = wall_a / 2.0
          sink_y = -310.mm
        end
      end

      sink_grp = ents.add_group
      sink_grp.name = 'Stainless_Undermount_Sink'
      s_ents = sink_grp.entities

      # Stainless Basin Bowl (480mm x 400mm x 170mm depth)
      bw = 480.mm
      bd = 400.mm
      bh = 170.mm
      basin_z = base_h + 15.mm

      bf = s_ents.add_face([
        [sink_x - bw/2.0, sink_y - bd/2.0, basin_z],
        [sink_x + bw/2.0, sink_y - bd/2.0, basin_z],
        [sink_x + bw/2.0, sink_y + bd/2.0, basin_z],
        [sink_x - bw/2.0, sink_y + bd/2.0, basin_z]
      ])
      bf.pushpull(-bh) if bf

      # Chrome Drain Strainer
      df = s_ents.add_face([
        [sink_x - 45.mm, sink_y - 45.mm, basin_z - bh + 2.mm],
        [sink_x + 45.mm, sink_y - 45.mm, basin_z - bh + 2.mm],
        [sink_x + 45.mm, sink_y + 45.mm, basin_z - bh + 2.mm],
        [sink_x - 45.mm, sink_y + 45.mm, basin_z - bh + 2.mm]
      ])
      df.pushpull(3.mm) if df

      sink_grp.material = mats[:sink_chrome]

      # Gooseneck Swivel Faucet
      f_grp = ents.add_group
      f_grp.name = 'Chrome_Gooseneck_Mixer_Faucet'
      f_ents = f_grp.entities

      faucet_base_z = base_h + 30.mm
      faucet_pos_x = sink_on_a ? sink_x : (wall_a - 110.mm)
      faucet_pos_y = sink_on_a ? -110.mm : sink_y

      # 1. Vertical Riser Tube
      rf = f_ents.add_face([
        [faucet_pos_x - 12.mm, faucet_pos_y - 12.mm, faucet_base_z],
        [faucet_pos_x + 12.mm, faucet_pos_y - 12.mm, faucet_base_z],
        [faucet_pos_x + 12.mm, faucet_pos_y + 12.mm, faucet_base_z],
        [faucet_pos_x - 12.mm, faucet_pos_y + 12.mm, faucet_base_z]
      ])
      rf.pushpull(240.mm) if rf

      # 2. Horizontal Swivel Spout Arm & Downward Tip
      if sink_on_a
        # Extends forward towards -Y
        sf = f_ents.add_face([
          [faucet_pos_x - 9.mm, faucet_pos_y, faucet_base_z + 225.mm],
          [faucet_pos_x + 9.mm, faucet_pos_y, faucet_base_z + 225.mm],
          [faucet_pos_x + 9.mm, faucet_pos_y - 140.mm, faucet_base_z + 225.mm],
          [faucet_pos_x - 9.mm, faucet_pos_y - 140.mm, faucet_base_z + 225.mm]
        ])
        sf.pushpull(18.mm) if sf

        tf = f_ents.add_face([
          [faucet_pos_x - 7.mm, faucet_pos_y - 140.mm, faucet_base_z + 225.mm],
          [faucet_pos_x + 7.mm, faucet_pos_y - 140.mm, faucet_base_z + 225.mm],
          [faucet_pos_x + 7.mm, faucet_pos_y - 126.mm, faucet_base_z + 225.mm],
          [faucet_pos_x - 7.mm, faucet_pos_y - 126.mm, faucet_base_z + 225.mm]
        ])
        tf.pushpull(-40.mm) if tf
      else
        # Extends left towards -X
        sf = f_ents.add_face([
          [faucet_pos_x, faucet_pos_y - 9.mm, faucet_base_z + 225.mm],
          [faucet_pos_x - 140.mm, faucet_pos_y - 9.mm, faucet_base_z + 225.mm],
          [faucet_pos_x - 140.mm, faucet_pos_y + 9.mm, faucet_base_z + 225.mm],
          [faucet_pos_x, faucet_pos_y + 9.mm, faucet_base_z + 225.mm]
        ])
        sf.pushpull(18.mm) if sf

        tf = f_ents.add_face([
          [faucet_pos_x - 140.mm, faucet_pos_y - 7.mm, faucet_base_z + 225.mm],
          [faucet_pos_x - 126.mm, faucet_pos_y - 7.mm, faucet_base_z + 225.mm],
          [faucet_pos_x - 126.mm, faucet_pos_y + 7.mm, faucet_base_z + 225.mm],
          [faucet_pos_x - 140.mm, faucet_pos_y + 7.mm, faucet_base_z + 225.mm]
        ])
        tf.pushpull(-40.mm) if tf
      end

      f_grp.material = mats[:faucet]
    end

    def self.build_3d_dimension_callouts(ents, wall_a, wall_b, wall_c, base_h, top_z, top_h, tall_h, mats)
      dim_group = ents.add_group
      dim_group.name = 'Kitchen_Dimension_Callouts'
      d_ents = dim_group.entities

      # Add text callouts on walls
      d_ents.add_text("Wall A: #{wall_a.to_mm.round} mm", Geom::Point3d.new(wall_a / 2.0, 0, base_h + 380.mm))
      if wall_b > 0
        d_ents.add_text("Wall B: #{wall_b.to_mm.round} mm", Geom::Point3d.new(wall_a, -wall_b / 2.0, base_h + 380.mm))
      end
      if wall_c > 0
        d_ents.add_text("Wall C: #{wall_c.to_mm.round} mm", Geom::Point3d.new(0, -wall_c / 2.0, base_h + 380.mm))
      end
      d_ents.add_text("Base Height: #{base_h.to_mm.round} mm | Top Height: #{top_h.to_mm.round} mm | Tall Tower: #{tall_h.to_mm.round} mm", Geom::Point3d.new(wall_a / 2.0, 0, top_z + top_h + 100.mm))
    end

    # -------------------------------------------------------------------------
    # Helper: Real 3D Floor Geometry Text (Not camera-rotating billboard label)
    # -------------------------------------------------------------------------
    def self.create_floor_3d_text(parent_ents, text_lines, center_x, baseline_y, z, letter_h, mat)
      text_grp = parent_ents.add_group
      text_grp.name = 'Floor_Text_3D'
      t_sub = text_grp.entities

      line_spacing = letter_h * 1.40
      text_lines.reverse.each_with_index do |line_str, l_idx|
        line_grp = t_sub.add_group
        line_grp.name = "Line_#{text_lines.length - l_idx}"
        align = defined?(TextAlignCenter) ? TextAlignCenter : 1
        begin
          line_grp.entities.add_3d_text(
            line_str.to_s,
            align,
            'Arial',
            true,   # bold
            false,  # italic
            letter_h,
            0.0,    # tolerance
            2.0.mm, # z_extrusion (solid 3D text)
            true,   # filled
            0.0     # extrusion_depth
          )
        rescue => e
          line_grp.entities.add_3d_text(line_str.to_s, 0, 'Arial', false, false, letter_h)
        end
        # Center horizontally at X = 0
        l_bounds = line_grp.bounds
        l_center_x = (l_bounds.center.x rescue 0.0)
        line_grp.transform!(Geom::Transformation.translation([-l_center_x, l_idx * line_spacing, 0]))
      end

      # Translate entire centered text block to [center_x, baseline_y, z]
      text_grp.transform!(Geom::Transformation.translation([center_x, baseline_y, z]))
      text_grp.material = mat if mat
      text_grp
    end

    # -------------------------------------------------------------------------
    # Module Staging Area on the Floor (Right-hand side, 2m spacing, 3 cols/row)
    # -------------------------------------------------------------------------
    def self.build_individual_module_staging_area(parent_ents, assembled_root_ents, wall_a, wall_b, mats)
      cabinet_boxes = []
      collect_boxes = lambda do |p_ents|
        p_ents.grep(Sketchup::Group).each do |g|
          name = g.name.to_s
          next if name.start_with?('Room_Shell') || name == 'Wall_A' || name == 'Wall_B' || name == 'Wall_C' || name.start_with?('Floor') ||
                  name.include?('Countertop') || name.include?('Granite') || name.include?('Backsplash') ||
                  name.include?('LED_Task') || name.include?('Dimension') || name.include?('Sink_Fixture') ||
                  name.include?('Cooktop') || name.include?('Foot_Frame') || name.include?('Gola') || name.include?('Plinth') ||
                  name.start_with?('Workshop_') || name.start_with?('Staged_') || name.start_with?('Pod_') ||
                  name.include?('Door_Opening') || name.include?('Window_Opening') || name.include?('Faucet')

          if g.get_attribute('CBX', 'is_cabinet_box') == true || name.start_with?('Unit_') ||
             name.include?('Base_Cabinet') || name.include?('Wall_Cabinet') || name.include?('Tall_Oven') ||
             name.include?('Tall_Pantry') || name.include?('Aluminum_Base') || name.include?('Blind_Corner') ||
             name.include?('Aluminum_Wall') || name.include?('Alu_Top_Cabinet') || name.include?('Aluminum_Continuous') || name.include?('Continuous_')
            cabinet_boxes << g
          else
            collect_boxes.call(g.entities)
          end
        end
      end
      collect_boxes.call(assembled_root_ents)

      return if cabinet_boxes.empty?

      # Dedicated Staging Parent Group
      staging_grp = parent_ents.add_group
      staging_grp.name = 'Workshop_Individual_Cabinet_Pods'
      staging_grp.set_attribute('CBX', 'is_staging_group', true)
      staging_sub = staging_grp.entities

      # Partition into standard units (width <= 3000mm) and long units (> 3000mm)
      # User rule: if cabinet is longer than 3m, send to back to accommodate 2x2m pod area
      standard_boxes = []
      long_boxes = []

      cabinet_boxes.each do |box_grp|
        def_b = (box_grp.definition.bounds rescue box_grp.bounds)
        bw = box_grp.get_attribute('CBX', 'width_mm')&.to_f || def_b.width.to_mm
        if bw > 3000.0
          long_boxes << box_grp
        else
          standard_boxes << box_grp
        end
      end

      # Grid parameters: 3 columns per row, 2m spacing apart
      cols_per_row = 3
      col_gap = 2000.mm
      row_gap = 2000.mm

      max_cell_w = 1200.mm
      max_cell_d = 700.mm

      col_pitch = max_cell_w + col_gap # 3200mm slot width
      row_pitch = max_cell_d + row_gap # 2700mm slot depth

      # Start position: 2m to the right of the assembled kitchen
      start_x = [wall_a + 150.mm + 2000.mm, 4500.mm].max
      start_y = 0.mm # Datum front row

      staged_items = []

      # 1. Standard boxes: 3 in front, others behind in a grid (3 columns per row)
      standard_boxes.each_with_index do |box_grp, idx|
        row = idx / cols_per_row
        col = idx % cols_per_row

        pod_x = start_x + col * col_pitch
        pod_y = start_y + row * row_pitch

        staged_items << { box: box_grp, pod_x: pod_x, pod_y: pod_y, is_long: false, pod_num: idx + 1 }
      end

      # 2. Long boxes (> 3m): placed in back row(s)
      num_standard_rows = (standard_boxes.length / cols_per_row.to_f).ceil
      back_row_idx = [num_standard_rows, 1].max

      long_boxes.each_with_index do |box_grp, l_idx|
        row = back_row_idx + l_idx
        pod_x = start_x
        pod_y = start_y + row * row_pitch

        staged_items << { box: box_grp, pod_x: pod_x, pod_y: pod_y, is_long: true, pod_num: standard_boxes.length + l_idx + 1 }
      end

      # High contrast text material and clean floor pad material
      text_mat = mats[:carcase_alu] || mats[:appliance] || mats[:alu]
      pad_mat = mats[:floor] || mats[:tile]

      staged_items.each do |item|
        box_grp = item[:box]
        pod_x = item[:pod_x]
        pod_y = item[:pod_y]
        p_num = item[:pod_num]

        def_b = (box_grp.definition.bounds rescue box_grp.bounds)
        w_mm = box_grp.get_attribute('CBX', 'width_mm')&.to_f || def_b.width.to_mm.round
        h_mm = box_grp.get_attribute('CBX', 'height_mm')&.to_f || def_b.height.to_mm.round
        d_mm = box_grp.get_attribute('CBX', 'depth_mm')&.to_f || def_b.depth.to_mm.round
        w_mm = 600.0 if w_mm < 50
        h_mm = 870.0 if h_mm < 50
        d_mm = 600.0 if d_mm < 50

        unit_title = box_grp.get_attribute('CBX', 'unit_title') || box_grp.name.to_s.gsub('_', ' ')

        # Pod Container
        safe_name = unit_title.gsub(/[^a-zA-Z0-9_-]/, '_')
        pod_grp = staging_sub.add_group
        pod_grp.name = "Staged_Pod_#{p_num}_#{safe_name}"
        pod_grp.set_attribute('CBX', 'is_staged_pod', true)
        pod_ents = pod_grp.entities

        # Normalize instance translation so bottom is on floor Z=0 and front is at pod_y
        local_min_x = def_b.min.x
        local_max_y = def_b.max.y
        local_min_z = def_b.min.z

        trans_x = pod_x - local_min_x
        trans_y = pod_y - local_max_y
        trans_z = 0.0 - local_min_z

        box_instance = pod_ents.add_instance(box_grp.definition, Geom::Transformation.translation([trans_x, trans_y, trans_z]))
        box_instance.make_unique rescue nil

        # Workshop floor pad platform demarcation
        pad_margin = 150.mm
        pad_x0 = pod_x - pad_margin
        pad_x1 = pod_x + w_mm.mm + pad_margin
        pad_y0 = pod_y - d_mm.mm - 480.mm
        pad_y1 = pod_y + pad_margin

        pad_f = pod_ents.add_face([
          [pad_x0, pad_y0, 0.2.mm],
          [pad_x1, pad_y0, 0.2.mm],
          [pad_x1, pad_y1, 0.2.mm],
          [pad_x0, pad_y1, 0.2.mm]
        ])
        pad_f.material = pad_mat if pad_f

        # Pad crisp border wireframe
        border_pts = [
          [pad_x0, pad_y0, 0.4.mm],
          [pad_x1, pad_y0, 0.4.mm],
          [pad_x1, pad_y1, 0.4.mm],
          [pad_x0, pad_y1, 0.4.mm],
          [pad_x0, pad_y0, 0.4.mm]
        ]
        pod_ents.add_curve(border_pts)

        # Real 3D Floor Text Callout: Name & Dimensions (Flat on floor, does not rotate with camera)
        letter_h = [70.mm, (w_mm.mm * 0.85 / [unit_title.length * 0.55, 1].max)].min
        letter_h = [letter_h, 40.mm].max

        text_lines = [
          unit_title.upcase,
          "SIZE: #{w_mm.round}W Ã— #{h_mm.round}H Ã— #{d_mm.round}D mm"
        ]

        text_mid_x = pod_x + (w_mm.mm / 2.0)
        text_base_y = pod_y - d_mm.mm - 340.mm

        create_floor_3d_text(pod_ents, text_lines, text_mid_x, text_base_y, 0.5.mm, letter_h, text_mat)
      end
    end

    def self.build_from_specs(specs)
      model = Sketchup.active_model
      model.start_operation('Cabinex AI Generate Kitchen', true)

      begin
        project_settings = specs['project_settings'] || {}
        CabinexAI::HybridPlanner.project_settings = project_settings
        
        # Redefine engine ACP panel thickness dynamically (user-editable, default 3.0 mm)
        acp_thick_val = project_settings['acp_thickness_mm'] || 3.0
        acp_thick = acp_thick_val.to_f.mm
        if defined?(CBXHybridEngine::ACP_PANEL_THICKNESS)
          CBXHybridEngine.send(:remove_const, :ACP_PANEL_THICKNESS)
          CBXHybridEngine.const_set(:ACP_PANEL_THICKNESS, acp_thick)
        end
        
        # Set engine top and base door style dynamically
        top_door_val = project_settings['top_door_style'] || 'glass_sash'
        CBXHybridEngine.top_door_style = top_door_val
        base_door_val = project_settings['base_door_style'] || 'solid_acp'
        CBXHybridEngine.base_door_style = base_door_val
        tall_style_val = project_settings['tall_unit_style'] || 'double_oven'
        CBXHybridEngine.tall_unit_style = tall_style_val

        mats = self.prepare_materials(model)
        root = model.active_entities.add_group
        root.name = "Cabinex_Hybrid_Kitchen_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
        ents = root.entities

        room = specs['room'] || {}
        openings = specs['openings'] || {}
        openings_list = specs['openings_list']
        
        if openings_list && !openings_list.empty?
          openings['__list__'] = openings_list
          
          first_win = openings_list.find { |o| o['type'] == 'window' }
          if first_win
            openings['window_wall'] = first_win['wall']
            openings['window_offset_mm'] = first_win['offset']
            openings['window_width_mm'] = first_win['width']
            openings['window_height_mm'] = 1100
            openings['window_sill_mm'] = first_win['height']
          else
            openings['window_wall'] = 'none'
          end
          
          first_door = openings_list.find { |o| o['type'] == 'door' }
          if first_door
            openings['door_wall'] = first_door['wall']
            openings['door_offset_mm'] = first_door['offset']
            openings['door_width_mm'] = first_door['width']
          else
            openings['door_wall'] = 'none'
          end
        end

        style = specs['style'] || {}
        modules = specs['modules'] || {}
        project_settings = specs['project_settings'] || {}

        # Save project settings attributes for persistence and downstream reporting
        root.set_attribute('CBX', 'project_settings_json', project_settings.to_json)
        model.set_attribute('CBX', 'last_project_settings', project_settings.to_json)

        wall_a = (room['wall_a_mm'] || 3048).to_f.mm
        wall_b = (room['wall_b_mm'] || 3048).to_f.mm
        wall_c = (room['wall_c_mm'] || 0).to_f.mm
        ceiling_h = (room['ceiling_height_mm'] || 2743).to_f.mm
        base_h = (room['base_height_mm'] || 870).to_f.mm
        top_z = (room['top_z_mm'] || 1500).to_f.mm
        top_h = (room['top_height_mm'] || 610).to_f.mm
        tall_h = (room['tall_height_mm'] || 2133).to_f.mm

        kitchen_type = project_settings['construction_logic'] || style['kitchen_type'] || 'FULL_ALU_FRAME'
        # Master engine: keep ALL construction types (aluminum, board, wardrobe).
        # Coerce only unknown/legacy values to the default aluminum build.
        unless %w[FULL_ALU_FRAME FULL_ALU_FRAME_L ECONOMY_FRAME ECONOMY_FRAME_L FULL_BOARD FULL_BOARD_L BOARD_WARDROBE].include?(kitchen_type)
          kitchen_type = 'FULL_ALU_FRAME'
        end
        use_gola = (project_settings['gola_mode'] || style['gola_mode']) != 'none'
        custom_modules = specs['custom_wall_modules']

        Sketchup.set_status_text("Cabinex AI: Generating 3D Room Shell...")
        build_room_shell_with_openings(ents, wall_a, wall_b, wall_c, ceiling_h, openings, mats, custom_modules)

        drawer_w = [ (modules['drawer_width_mm'] || 600).to_f.mm, MAX_BOTTOM_WIDTH ].min
        drawer_cnt = (modules['drawer_count'] || 3).to_i
        cooker_w = [ (modules['cooker_width_mm'] || 750).to_f.mm, MAX_BOTTOM_WIDTH ].min
        sink_w = [ (modules['sink_width_mm'] || 900).to_f.mm, MAX_BOTTOM_WIDTH ].min
        has_tall = modules['has_tall_oven'] != false
        has_open_rack = modules['has_open_rack'] == true
        has_hood = modules['has_hood_bay'] == true

        if custom_modules && (!custom_modules['A'].nil? || !custom_modules['B'].nil?)
          Sketchup.set_status_text("Cabinex AI: Building Custom Wall Modules...")
          build_custom_wall_modules_orchestrator(ents, wall_a, wall_b, wall_c, base_h, top_z, top_h, tall_h, custom_modules, kitchen_type, style, openings, mats)
        else
          case kitchen_type
          when 'FULL_ALU_FRAME', 'FULL_ALU_FRAME_L'
            build_full_aluminum_l_orchestrator(ents, wall_a, wall_b, base_h, top_z, top_h, tall_h, drawer_w, drawer_cnt, cooker_w, sink_w, has_tall, has_open_rack, has_hood, openings, mats)
          when 'ECONOMY_FRAME', 'ECONOMY_FRAME_L'
            build_economy_frame_l_orchestrator(ents, wall_a, wall_b, base_h, top_z, top_h, tall_h, drawer_w, drawer_cnt, cooker_w, sink_w, has_tall, has_open_rack, has_hood, openings, mats)
          when 'FULL_BOARD', 'FULL_BOARD_L'
            build_full_board_orchestrator(ents, wall_a, wall_b, base_h, top_z, top_h, tall_h, drawer_w, drawer_cnt, cooker_w, sink_w, has_tall, has_open_rack, has_hood, openings, mats)
          when 'BOARD_WARDROBE'
            build_board_wardrobe_orchestrator(ents, wall_a, wall_b, base_h, top_z, top_h, tall_h, drawer_w, drawer_cnt, cooker_w, sink_w, has_tall, has_open_rack, has_hood, openings, mats)
          else
            build_full_aluminum_l_orchestrator(ents, wall_a, wall_b, base_h, top_z, top_h, tall_h, drawer_w, drawer_cnt, cooker_w, sink_w, has_tall, has_open_rack, has_hood, openings, mats)
          end
        end

        # Generate Solid Granite Countertops, Backsplash Tiling, Linear LED Task Lighting, Sink & Faucet
        Sketchup.set_status_text("Cabinex AI: Generating Solid Granite Countertops & Fixtures...")
        build_granite_countertop_backsplash_and_fixtures(ents, wall_a, wall_b, wall_c, base_h, top_z, custom_modules, openings, mats)

        # Build Top Bulkhead / Ceiling Soffit if selected
        has_bulkhead = project_settings['has_top_bulkhead'] == true || project_settings['layout_archetype'] == 'U_BAR_BULKHEAD'
        if has_bulkhead
          Sketchup.set_status_text("Cabinex AI: Building Architectural Top Bulkhead Soffit...")
          build_top_bulkhead_soffit(ents, wall_a, wall_b, wall_c, top_z, top_h, ceiling_h, custom_modules, mats)
        end

        # Add 3D Architectural Dimension Callouts
        build_3d_dimension_callouts(ents, wall_a, wall_b, wall_c, base_h, top_z, top_h, tall_h, mats)

        # Automatically calculate nested BOM
        Sketchup.set_status_text("Cabinex AI: Calculating Bill of Materials & CNC Bar Cut Optimization...")
        bom_data = CBXHybridEngine.generate_bom_and_nesting(root.entities)

        # Build Staged Individual Cabinet Modules Grid on Floor (2m separation, 3x columns, 3D text on floor)
        Sketchup.set_status_text("Cabinex AI: Preparing Workshop Staging Area & Exploded Views...")
        build_individual_module_staging_area(ents, ents, wall_a, wall_b, mats)

        puts "========================================================="
        puts "CABINEX AI - BILL OF MATERIALS & NESTING SUMMARY"
        puts "========================================================="
        puts "Matte Black Carcase Frame 6400mm Bars: #{bom_data[:nesting][:boxbar_matte_black_6m_bars][:total_bars]} bars (#{bom_data[:nesting][:boxbar_matte_black_6m_bars][:total_net_length_m]} m)"
        puts "Gloss Door Sash Profile 6400mm Bars:   #{bom_data[:nesting][:sash_gloss_6m_bars][:total_bars]} bars (#{bom_data[:nesting][:sash_gloss_6m_bars][:total_net_length_m]} m)"
        puts "White ACP 3mm Sheets (2440x1220):   #{bom_data[:nesting][:acp_2440x1220_sheets_est]} sheets (#{bom_data[:nesting][:total_acp_sqm]} mÂ²)"
        puts "Glass Panes:                        #{bom_data[:nesting][:total_glass_sqm]} mÂ²"
        puts "Hardware Hinges:                    #{bom_data[:hardware][:hinges]} pcs"
        puts "========================================================="

        begin
          model.active_view.zoom_extents
        rescue
        end

        model.commit_operation
        bom_data
      rescue => e
        model.abort_operation
        raise e
      end
    end

    def self.build_full_aluminum_l_orchestrator(ents, wall_a, wall_b, base_h, top_z, top_h, tall_h, drawer_w, drawer_cnt, cooker_w, sink_w, has_tall, has_open_rack, has_hood, openings, mats)
      corner_wall = determine_corner_wall_placement(wall_a, wall_b, has_tall)
      w_on_b = openings['window_wall'] == 'B'
      w_offset_b = (openings['window_offset_mm'] || 1200).to_f.mm

      main = ents.add_group
      main.name = 'All_Aluminum_L_Main_Run'
      m_ents = main.entities

      tall_w = has_tall ? TALL_WIDTH : 0.mm

      if corner_wall == 'B'
        avail_a = [wall_a - BASE_BLIND_RETURN, 600.mm].max
        main_units = []
        if has_tall
          main_units << { width: tall_w, front: :door, is_tall: true }
        end
        rem_a = avail_a - (has_tall ? tall_w : 0.mm)
        fixed_a = drawer_w + cooker_w
        if rem_a >= fixed_a + 450.mm
          rem_mid = rem_a - fixed_a
          mid_bays = split_bays(rem_mid, MAX_BOTTOM_WIDTH)
          main_units << { width: drawer_w, front: :drawers, drawer_count: drawer_cnt }
          main_units << { width: cooker_w, front: :door }
          mid_bays.each { |bw| main_units << { width: bw, front: :door } }
        else
          bays = split_bays(rem_a, MAX_BOTTOM_WIDTH)
          bays.each_with_index do |bw, idx|
            if idx == 0
              main_units << { width: bw, front: :drawers, drawer_count: drawer_cnt }
            else
              main_units << { width: bw, front: :door }
            end
          end
        end

        actual_wall_a = main_units.sum { |u| u[:width] }
        CBXHybridEngine.build_aluminum_continuous_base_run(
          m_ents,
          { width: actual_wall_a, height: base_h, depth: 600.mm, units: main_units.reject { |u| u[:is_tall] }, right_end_panel: :none },
          mats
        )

        avail_top_a = [wall_a - TOP_BLIND_RETURN, 600.mm].max
        top_hood_w = SLIM_HOOD_WIDTH
        rem_top_a = [avail_top_a - drawer_w - top_hood_w, 0.mm].max
        top_bays_a = [drawer_w, top_hood_w]
        if rem_top_a > 100.mm
          top_bays_a += split_bays(rem_top_a, MAX_TOP_WIDTH, is_top: true)
        end
        hood_idx = has_hood ? 2 : nil
        open_idx = (has_open_rack && top_bays_a.length >= 4) ? 3 : nil
        CBXHybridEngine.build_aluminum_continuous_wall_run(
          m_ents,
          { bay_widths: top_bays_a, x: 0, z: top_z, height: top_h, depth: 350.mm, hood_bay: hood_idx, open_bay: open_idx, right_end_panel: :none },
          mats
        )
        build_cooktop_and_hood(m_ents, drawer_w, cooker_w, top_z, mats)

        ret_base = ents.add_group
        ret_base.name = 'All_Aluminum_L_Return_Run_Corner_B'
        rb_ents = ret_base.entities

        corner_b_w = [wall_b, MIN_BASE_CORNER_WIDTH].max
        ret_units = [
          { width: corner_b_w, front: :blind, blind_width: BASE_BLIND_RETURN, blind_side: :left }
        ]
        CBXHybridEngine.build_aluminum_continuous_base_run(
          rb_ents,
          { width: corner_b_w, height: base_h, depth: 600.mm, units: ret_units, left_end_panel: :none, right_end_panel: :acp },
          mats
        )
        place_return_run(ret_base, actual_wall_a + BASE_BLIND_RETURN, 0.mm)

        ret_top = ents.add_group
        ret_top.name = 'All_Aluminum_L_Return_Tops_Corner_B'
        top_corner_b_w = [wall_b, MIN_TOP_CORNER_WIDTH].max
        CBXHybridEngine.build_aluminum_continuous_wall_run(
          ret_top.entities,
          { bay_widths: [top_corner_b_w], x: 0, z: top_z, height: top_h, depth: 350.mm, hood_bay: nil, open_bay: nil, left_end_panel: :none, right_end_panel: :acp },
          mats
        )
        place_return_run(ret_top, actual_wall_a + BASE_BLIND_RETURN, 0.mm)

      else
        fixed_front = drawer_w + cooker_w
        rem_a = wall_a - fixed_front

        corner_w = [rem_a, MIN_BASE_CORNER_WIDTH].max
        actual_corner_w = (rem_a >= MIN_BASE_CORNER_WIDTH + 450.mm) ? MIN_BASE_CORNER_WIDTH : rem_a
        mid_span = rem_a - actual_corner_w

        main_units = [
          { width: drawer_w, front: :drawers, drawer_count: drawer_cnt },
          { width: cooker_w, front: :door }
        ]
        if mid_span >= 450.mm
          split_bays(mid_span, MAX_BOTTOM_WIDTH).each do |bw|
            main_units << { width: bw, front: :door }
          end
        end
        main_units << { width: actual_corner_w, front: :blind, blind_width: BASE_BLIND_RETURN, blind_side: :right }

        actual_wall_a = main_units.sum { |u| u[:width] }
        CBXHybridEngine.build_aluminum_continuous_base_run(
          m_ents,
          { width: actual_wall_a, height: base_h, depth: 600.mm, units: main_units, right_end_panel: :none },
          mats
        )

        top_hood_w = SLIM_HOOD_WIDTH
        rem_top = actual_wall_a - drawer_w - top_hood_w
        top_corner_w = (rem_top >= MIN_TOP_CORNER_WIDTH + 400.mm) ? MIN_TOP_CORNER_WIDTH : rem_top
        top_mid_span = rem_top - top_corner_w
        top_mid_bays = (top_mid_span >= 350.mm) ? split_bays(top_mid_span, MAX_TOP_WIDTH, is_top: true) : []
        main_top_bays = [drawer_w, top_hood_w] + top_mid_bays + [top_corner_w]

        hood_idx = (has_hood && main_top_bays.length >= 2) ? 2 : nil
        open_idx = (has_open_rack && main_top_bays.length >= 4) ? 3 : nil

        CBXHybridEngine.build_aluminum_continuous_wall_run(
          m_ents,
          { bay_widths: main_top_bays, x: 0, z: top_z, height: top_h, depth: 350.mm, hood_bay: hood_idx, open_bay: open_idx, right_end_panel: :none },
          mats
        )
        build_cooktop_and_hood(m_ents, drawer_w, cooker_w, top_z, mats)
        CBXHybridEngine.validate_wall_row_alignment!(m_ents)

        return_run_avail = wall_b - BASE_BLIND_RETURN
        if return_run_avail > 300.mm
          ret_base = ents.add_group
          ret_base.name = 'All_Aluminum_L_Return_Run'
          rb_ents = ret_base.entities

          include_tall = has_tall && return_run_avail >= tall_w
          base_span = include_tall ? (return_run_avail - tall_w) : return_run_avail

          if base_span > 0
            bays = split_bays(base_span, MAX_BOTTOM_WIDTH)
            bays = [base_span] if bays.empty?
            CBXHybridEngine.build_aluminum_continuous_base_run(
              rb_ents,
              { width: base_span, height: base_h, depth: 600.mm, units: bays.map { |bw| { width: bw, front: :door } }, left_end_panel: :none, right_end_panel: (include_tall ? :none : :acp) },
              mats
            )
          end

          if include_tall
            tall = CBXHybridEngine.build_aluminum_top_cabinet(
              rb_ents,
              { width: tall_w, height: tall_h - CBXHybridEngine::PROFILE_HEIGHT, depth: 600.mm,
                x: base_span, y: 0, z: CBXHybridEngine::PROFILE_HEIGHT,
                has_left_sash: true, has_right_sash: true, end_sash_panel: :acp, door_count: 1,
                door_handle_side: :opening, assembly_role: 'Aluminum_Framed_Tall_End_600' },
              mats
            )
            tall.set_attribute('CBX', 'shared_floor_frame', true)
          end

          place_return_run(ret_base, actual_wall_a, BASE_BLIND_RETURN)

          return_top_run_span = include_tall ? (base_span + (BASE_BLIND_RETURN - TOP_BLIND_RETURN)) : (wall_b - TOP_BLIND_RETURN)
          if return_top_run_span > 300.mm
            top_span = w_on_b ? [w_offset_b - TOP_BLIND_RETURN, 0.mm].max : return_top_run_span
            if top_span > 300.mm
              ret_top = ents.add_group
              ret_top.name = 'All_Aluminum_L_Return_Tops'
              top_bays = split_bays(top_span, MAX_TOP_WIDTH, is_top: true)
              CBXHybridEngine.build_aluminum_continuous_wall_run(
                ret_top.entities,
                { bay_widths: top_bays, x: 0, z: top_z, height: top_h, depth: 350.mm, hood_bay: nil, open_bay: nil, left_end_panel: :none, right_end_panel: :acp },
                mats
              )
              CBXHybridEngine.validate_wall_row_alignment!(ret_top.entities)
              place_return_run(ret_top, actual_wall_a, TOP_BLIND_RETURN)
            end
          end
        end
      end

      # Corner Tunnels
      CBXHybridEngine.build_aluminum_l_corner_tunnel(
        ents, { corner_x: actual_wall_a, blind_return: BASE_BLIND_RETURN, main_depth: 600.mm, height: base_h, support_height: CBXHybridEngine::PROFILE_HEIGHT }, mats
      )
      CBXHybridEngine.build_aluminum_l_corner_tunnel(
        ents, { corner_x: actual_wall_a, blind_return: TOP_BLIND_RETURN, main_depth: 350.mm, z: top_z, height: top_h, include_top: true }, mats
      )
    end

    def self.build_economy_frame_l_orchestrator(ents, wall_a, wall_b, base_h, top_z, top_h, tall_h, drawer_w, drawer_cnt, cooker_w, sink_w, has_tall, has_open_rack, has_hood, openings, mats)
      corner_wall = determine_corner_wall_placement(wall_a, wall_b, has_tall)
      w_on_b = openings['window_wall'] == 'B'
      w_offset_b = (openings['window_offset_mm'] || 1200).to_f.mm

      main = ents.add_group
      main.name = 'Economy_L_Main_Run'
      m_ents = main.entities

      tall_w = has_tall ? TALL_WIDTH : 0.mm

      if corner_wall == 'B'
        avail_a = [wall_a - BASE_BLIND_RETURN, 600.mm].max
        main_units = []
        if has_tall
          main_units << { width: tall_w, front: :door, is_tall: true }
        end
        rem_a = avail_a - (has_tall ? tall_w : 0.mm)
        fixed_a = drawer_w + cooker_w
        if rem_a >= fixed_a + 450.mm
          rem_mid = rem_a - fixed_a
          mid_bays = split_bays(rem_mid, MAX_BOTTOM_WIDTH)
          main_units << { width: drawer_w, front: :drawers, drawer_count: drawer_cnt }
          main_units << { width: cooker_w, front: :door }
          mid_bays.each { |bw| main_units << { width: bw, front: :door } }
        else
          bays = split_bays(rem_a, MAX_BOTTOM_WIDTH)
          bays.each_with_index do |bw, idx|
            if idx == 0
              main_units << { width: bw, front: :drawers, drawer_count: drawer_cnt }
            else
              main_units << { width: bw, front: :door }
            end
          end
        end

        actual_wall_a = main_units.sum { |u| u[:width] }
        CBXHybridEngine.build_aluminum_continuous_base_run(
          m_ents,
          { economy: true, width: actual_wall_a, height: base_h, depth: 600.mm, units: main_units.reject { |u| u[:is_tall] }, right_end_panel: :none },
          mats
        )

        avail_top_a = [wall_a - TOP_BLIND_RETURN, 600.mm].max
        top_hood_w = SLIM_HOOD_WIDTH
        rem_top_a = [avail_top_a - drawer_w - top_hood_w, 0.mm].max
        top_bays_a = [drawer_w, top_hood_w]
        if rem_top_a > 100.mm
          top_bays_a += split_bays(rem_top_a, MAX_TOP_WIDTH, is_top: true)
        end
        hood_idx = has_hood ? 2 : nil
        open_idx = (has_open_rack && top_bays_a.length >= 4) ? 3 : nil
        CBXHybridEngine.build_aluminum_continuous_wall_run(
          m_ents,
          { economy: true, bay_widths: top_bays_a, x: 0, z: top_z, height: top_h, depth: 350.mm, hood_bay: hood_idx, open_bay: open_idx, right_end_panel: :none },
          mats
        )
        build_cooktop_and_hood(m_ents, drawer_w, cooker_w, top_z, mats)

        ret_base = ents.add_group
        ret_base.name = 'Economy_L_Return_Run_Corner_B'
        rb_ents = ret_base.entities

        corner_b_w = [wall_b, MIN_BASE_CORNER_WIDTH].max
        ret_units = [
          { width: corner_b_w, front: :blind, blind_width: BASE_BLIND_RETURN, blind_side: :left }
        ]
        CBXHybridEngine.build_aluminum_continuous_base_run(
          rb_ents,
          { economy: true, width: corner_b_w, height: base_h, depth: 600.mm, units: ret_units, left_end_panel: :none, right_end_panel: :acp },
          mats
        )
        place_return_run(ret_base, actual_wall_a + BASE_BLIND_RETURN, 0.mm)

        ret_top = ents.add_group
        ret_top.name = 'Economy_L_Return_Tops_Corner_B'
        top_corner_b_w = [wall_b, MIN_TOP_CORNER_WIDTH].max
        CBXHybridEngine.build_aluminum_continuous_wall_run(
          ret_top.entities,
          { economy: true, bay_widths: [top_corner_b_w], x: 0, z: top_z, height: top_h, depth: 350.mm, hood_bay: nil, open_bay: nil, left_end_panel: :none, right_end_panel: :acp },
          mats
        )
        place_return_run(ret_top, actual_wall_a + BASE_BLIND_RETURN, 0.mm)

      else
        fixed_front = drawer_w + cooker_w
        rem_a = wall_a - fixed_front

        corner_w = [rem_a, MIN_BASE_CORNER_WIDTH].max
        actual_corner_w = (rem_a >= MIN_BASE_CORNER_WIDTH + 450.mm) ? MIN_BASE_CORNER_WIDTH : rem_a
        mid_span = rem_a - actual_corner_w

        main_units = [
          { width: drawer_w, front: :drawers, drawer_count: drawer_cnt },
          { width: cooker_w, front: :door }
        ]
        if mid_span >= 450.mm
          split_bays(mid_span, MAX_BOTTOM_WIDTH).each do |bw|
            main_units << { width: bw, front: :door }
          end
        end
        main_units << { width: actual_corner_w, front: :blind, blind_width: BASE_BLIND_RETURN, blind_side: :right }

        actual_wall_a = main_units.sum { |u| u[:width] }
        CBXHybridEngine.build_aluminum_continuous_base_run(
          m_ents,
          { economy: true, width: actual_wall_a, height: base_h, depth: 600.mm, units: main_units, right_end_panel: :none },
          mats
        )

        top_hood_w = SLIM_HOOD_WIDTH
        rem_top = actual_wall_a - drawer_w - top_hood_w
        top_corner_w = (rem_top >= MIN_TOP_CORNER_WIDTH + 400.mm) ? MIN_TOP_CORNER_WIDTH : rem_top
        top_mid_span = rem_top - top_corner_w
        top_mid_bays = (top_mid_span >= 350.mm) ? split_bays(top_mid_span, MAX_TOP_WIDTH, is_top: true) : []
        main_top_bays = [drawer_w, top_hood_w] + top_mid_bays + [top_corner_w]

        hood_idx = (has_hood && main_top_bays.length >= 2) ? 2 : nil
        open_idx = (has_open_rack && main_top_bays.length >= 4) ? 3 : nil

        CBXHybridEngine.build_aluminum_continuous_wall_run(
          m_ents,
          { economy: true, bay_widths: main_top_bays, x: 0, z: top_z, height: top_h, depth: 350.mm, hood_bay: hood_idx, open_bay: open_idx, right_end_panel: :none },
          mats
        )
        build_cooktop_and_hood(m_ents, drawer_w, cooker_w, top_z, mats)
        CBXHybridEngine.validate_wall_row_alignment!(m_ents)

        return_run_avail = wall_b - BASE_BLIND_RETURN
        if return_run_avail > 300.mm
          ret_base = ents.add_group
          ret_base.name = 'Economy_L_Return_Run'
          rb_ents = ret_base.entities

          include_tall = has_tall && return_run_avail >= tall_w
          base_span = include_tall ? (return_run_avail - tall_w) : return_run_avail

          if base_span > 0
            bays = split_bays(base_span, MAX_BOTTOM_WIDTH)
            CBXHybridEngine.build_aluminum_continuous_base_run(
              rb_ents,
              { economy: true, width: base_span, height: base_h, depth: 600.mm, units: bays.map { |bw| { width: bw, front: :door } }, left_end_panel: :none, right_end_panel: (include_tall ? :none : :acp) },
              mats
            )
          end

          if include_tall
            tall = CBXHybridEngine.build_aluminum_top_cabinet(
              rb_ents,
              { width: tall_w, height: tall_h - CBXHybridEngine::PROFILE_HEIGHT, depth: 600.mm,
                x: base_span, y: 0, z: CBXHybridEngine::PROFILE_HEIGHT,
                has_left_sash: true, has_right_sash: true, end_sash_panel: :acp, door_count: 1,
                door_handle_side: :opening, assembly_role: 'Aluminum_Framed_Tall_End_600' },
              mats
            )
            tall.set_attribute('CBX', 'shared_floor_frame', true)
          end

          place_return_run(ret_base, actual_wall_a, BASE_BLIND_RETURN)

          return_top_run_span = include_tall ? (base_span + (BASE_BLIND_RETURN - TOP_BLIND_RETURN)) : (wall_b - TOP_BLIND_RETURN)
          if return_top_run_span > 300.mm
            top_span = w_on_b ? [w_offset_b - TOP_BLIND_RETURN, 0.mm].max : return_top_run_span
            if top_span > 300.mm
              ret_top = ents.add_group
              ret_top.name = 'Economy_L_Return_Tops'
              top_bays = split_bays(top_span, MAX_TOP_WIDTH, is_top: true)
              CBXHybridEngine.build_aluminum_continuous_wall_run(
                ret_top.entities,
                { economy: true, bay_widths: top_bays, x: 0, z: top_z, height: top_h, depth: 350.mm, hood_bay: nil, open_bay: nil, left_end_panel: :none, right_end_panel: :acp },
                mats
              )
              CBXHybridEngine.validate_wall_row_alignment!(ret_top.entities)
              place_return_run(ret_top, actual_wall_a, TOP_BLIND_RETURN)
            end
          end
        end
      end

      # Corner Tunnels
      CBXHybridEngine.build_aluminum_l_corner_tunnel(
        ents, { corner_x: actual_wall_a, blind_return: BASE_BLIND_RETURN, main_depth: 600.mm, height: base_h, support_height: CBXHybridEngine::PROFILE_HEIGHT }, mats
      )
      CBXHybridEngine.build_aluminum_l_corner_tunnel(
        ents, { corner_x: actual_wall_a, blind_return: TOP_BLIND_RETURN, main_depth: 350.mm, z: top_z, height: top_h, include_top: true }, mats
      )
    end

    # -------------------------------------------------------------------------
    # Master engine: board kitchen + wardrobe orchestrators.
    # Phase 0 wiring exposes these; Phase 1 implements the box builders. They
    # fail loudly so the catalog matrix test reports EXACTLY what is not built.
    # -------------------------------------------------------------------------
    def self.build_full_board_orchestrator(ents, wall_a, wall_b, base_h, top_z, top_h, tall_h, drawer_w, drawer_cnt, cooker_w, sink_w, has_tall, has_open_rack, has_hood, openings, mats)
      raise 'Phase 1: build_full_board_orchestrator not yet built (board kitchen boxes).'
    end

    def self.build_board_wardrobe_orchestrator(ents, wall_a, wall_b, base_h, top_z, top_h, tall_h, drawer_w, drawer_cnt, cooker_w, sink_w, has_tall, has_open_rack, has_hood, openings, mats)
      raise 'Phase 1: build_board_wardrobe_orchestrator not yet built (wardrobe boxes).'
    end

    def self.partition_wall_modules(module_list)
      chunks = []
      current_base_units = []
      current_start_x = 0.mm
      cursor = 0.mm

      module_list.each do |box|
        bw = (box['width'] || 600).to_f.mm
        b_type = (box['type'] || 'door').to_s

        if b_type == 'tall_oven' || b_type == 'tall_pantry'
          if current_base_units.any?
            chunks << { type: :base_run, units: current_base_units, start_x: current_start_x }
            current_base_units = []
          end
          chunks << { type: :tall, box: box, start_x: cursor }
          cursor += bw
          current_start_x = cursor
        else
          if current_base_units.empty?
            current_start_x = cursor
          end
          current_base_units << box
          cursor += bw
        end
      end

      if current_base_units.any?
        chunks << { type: :base_run, units: current_base_units, start_x: current_start_x }
      end

      chunks
    end

    # Helper to partition top bays into continuous runs and standalone open racks
    def self.build_continuous_top_runs_orchestrator(parent_ents, top_bays_list, base_z, top_h, mats, is_return_wall = false, wall_label = 'Wall A')
      return if top_bays_list.empty?

      top_chunks = []
      current_run_bays = []
      current_start_x = 0.mm
      cursor = 0.mm

      top_bays_list.each do |tb|
        tw = tb[:width]
        is_open = tb[:is_open]
        is_hood = tb[:is_hood]
        bay_x = tb[:x] || cursor

        # Split into chunks if there is a spatial gap between runs
        if current_run_bays.any? && (bay_x - cursor).abs > 1.mm
          top_chunks << { type: :continuous_run, bays: current_run_bays, start_x: current_start_x }
          current_run_bays = []
          current_start_x = bay_x
          cursor = bay_x
        end

        if is_open
          if current_run_bays.any?
            top_chunks << { type: :continuous_run, bays: current_run_bays, start_x: current_start_x }
            current_run_bays = []
          end
          top_chunks << { type: :open_rack, bay: tb, start_x: bay_x }
          cursor = bay_x + tw
          current_start_x = cursor
        else
          if current_run_bays.empty?
            current_start_x = bay_x
          end
          current_run_bays << tb
          cursor = bay_x + tw
        end
      end

      if current_run_bays.any?
        top_chunks << { type: :continuous_run, bays: current_run_bays, start_x: current_start_x }
      end

      top_chunks.each_with_index do |chunk, c_idx|
        if chunk[:type] == :open_rack
          tb = chunk[:bay]
          tw = tb[:width]
          rack_box = CBXHybridEngine.build_aluminum_open_rack_box(
            parent_ents,
            { width: tw, height: top_h, frame_depth: 350.mm, x: chunk[:start_x], y: 0, z: base_z },
            mats
          )
          rack_box.name = "Unit_Top_OpenRack_#{tw.to_mm.round}mm"
          rack_box.set_attribute('CBX', 'is_cabinet_box', true)
          rack_box.set_attribute('CBX', 'unit_title', "Open Display Box (#{tw.to_mm.round}mm)")
          rack_box.set_attribute('CBX', 'unit_type', 'Doorless Open Display Box')
          rack_box.set_attribute('CBX', 'width_mm', tw.to_mm)
          rack_box.set_attribute('CBX', 'height_mm', top_h.to_mm)
          rack_box.set_attribute('CBX', 'depth_mm', 350.0)

        else
          bays = chunk[:bays]
          bay_widths = bays.map { |b| b[:width] }
          total_top_w = bay_widths.sum
          hood_idx = bays.find_index { |b| b[:is_hood] } ? (bays.find_index { |b| b[:is_hood] } + 1) : nil

          top_run_grp = CBXHybridEngine.build_aluminum_continuous_wall_run(
            parent_ents,
            {
              bay_widths: bay_widths,
              x: chunk[:start_x],
              y: 0,
              z: base_z,
              height: top_h,
              depth: 350.mm,
              hood_bay: hood_idx,
              open_bay: nil,
              left_end_panel: ((c_idx == 0 && !is_return_wall) ? :acp : :none),
              right_end_panel: ((c_idx == top_chunks.length - 1 && is_return_wall) ? :acp : :none)
            },
            mats
          )

          top_run_grp.set_attribute('CBX', 'is_cabinet_box', true)
          top_run_grp.set_attribute('CBX', 'unit_title', "Continuous Overhead Wall Run (#{total_top_w.to_mm.round}mm)")
          top_run_grp.set_attribute('CBX', 'unit_type', 'Continuous Aluminum Overhead Run')
          top_run_grp.set_attribute('CBX', 'width_mm', total_top_w.to_mm)
          top_run_grp.set_attribute('CBX', 'height_mm', top_h.to_mm)
          top_run_grp.set_attribute('CBX', 'depth_mm', 350.0)
          top_bay_specs = bays.map { |b| { 'width' => b[:width].to_mm.round(1), 'type' => (b[:is_hood] ? 'hood' : (b[:is_open] ? 'open_rack' : 'door')) } }
          top_run_grp.set_attribute('CBX', 'is_continuous_run', true)
          top_run_grp.set_attribute('CBX', 'bay_units_json', top_bay_specs.to_json)
          top_run_grp.set_attribute('CBX', 'origin_x_mm', (chunk[:start_x].to_mm rescue 0))
          top_run_grp.set_attribute('CBX', 'wall_label', "#{wall_label} Overhead")
        end
      end
    end

    def self.build_custom_wall_modules_orchestrator(ents, wall_a, wall_b, wall_c, base_h, top_z, top_h, tall_h, custom_modules, kitchen_type, style, openings, mats)
      use_gola = style['gola_mode'] != 'none'

      # -------------------------------------------------------------
      # 1. BUILD WALL A BASE RUNS & TALL TOWERS (MERGED CONTINUOUS RUNS)
      # -------------------------------------------------------------
      a_list = custom_modules['A'] || []
      a_chunks = partition_wall_modules(a_list)
      top_bays_a = []

      a_chunks.each_with_index do |chunk, c_idx|
        is_left_end = (c_idx == 0)
        is_right_end = (c_idx == a_chunks.length - 1 && wall_b <= 0)

        if chunk[:type] == :tall
          box = chunk[:box]
          bw = (box['width'] || 600).to_f.mm
          CBXHybridEngine.build_aluminum_foot_frame(
            ents, { width: bw, depth: 600.mm, x: chunk[:start_x] }, mats
          )
          tall_grp = CBXHybridEngine.build_aluminum_top_cabinet(
            ents,
            { width: bw, height: tall_h - CBXHybridEngine::PROFILE_HEIGHT, depth: 600.mm,
              x: chunk[:start_x], y: 0, z: CBXHybridEngine::PROFILE_HEIGHT,
              has_left_sash: true, has_right_sash: true, end_sash_panel: :acp, door_count: 1,
              door_handle_side: :opening, assembly_role: "Tall_Pantry_Tower_#{bw.to_mm.round}",
              shelves: :none }, mats
          )
          add_tall_interior_shelves(tall_grp.entities, bw, tall_h - CBXHybridEngine::PROFILE_HEIGHT, 600.mm, mats)
          tall_grp.name = "Unit_Tall_Tower_#{bw.to_mm.round}"
          tall_grp.set_attribute('CBX', 'is_cabinet_box', true)
          tall_grp.set_attribute('CBX', 'unit_title', "Tall Appliance & Pantry Tower (#{bw.to_mm.round}mm)")
          tall_grp.set_attribute('CBX', 'unit_type', 'Tall Appliance & Pantry Tower (Sash Shelves)')
          tall_grp.set_attribute('CBX', 'width_mm', bw.to_mm)
          tall_grp.set_attribute('CBX', 'height_mm', tall_h.to_mm)
          tall_grp.set_attribute('CBX', 'depth_mm', 600.0)

        else
          # Base Run Chunk
          total_run_w = chunk[:units].sum { |b| (b['width'] || 600).to_f.mm }
          run_units = chunk[:units].map do |b|
            bw = (b['width'] || 600).to_f.mm
            b_type = (b['type'] || 'door').to_s
            d_cnt = (b['drawer_count'] || 3).to_i
            if b_type == 'drawers'
              { width: bw, front: :drawers, drawer_count: d_cnt }
            elsif b_type == 'blind_corner'
              corner_actual_w = [bw, MIN_BASE_CORNER_WIDTH].max
              actual_blind_ret = [BASE_BLIND_RETURN, corner_actual_w - MIN_CORNER_DOOR_OPENING].min
              { width: corner_actual_w, front: :blind, blind_width: actual_blind_ret, blind_side: :right }
            else
              { width: bw, front: :door }
            end
          end

          base_run_grp = CBXHybridEngine.build_aluminum_continuous_base_run(
            ents,
            {
              width: total_run_w,
              height: base_h,
              depth: 600.mm,
              x: chunk[:start_x],
              y: 0,
              z: 0,
              units: run_units,
              left_end_panel: (is_left_end ? :acp : :none),
              right_end_panel: (is_right_end ? :acp : :none),
              economy: (kitchen_type == 'ECONOMY_FRAME')
            },
            mats
          )
          base_run_grp.name = "Aluminum_Continuous_Base_Run_#{total_run_w.to_mm.round}mm"
          base_run_grp.set_attribute('CBX', 'is_cabinet_box', true)
          base_run_grp.set_attribute('CBX', 'unit_title', "Wall A Continuous Base Run (#{total_run_w.to_mm.round}mm)")
          base_run_grp.set_attribute('CBX', 'unit_type', 'Continuous Aluminum Carcase Frame Run')
          base_run_grp.set_attribute('CBX', 'width_mm', total_run_w.to_mm)
          base_run_grp.set_attribute('CBX', 'height_mm', base_h.to_mm)
          base_run_grp.set_attribute('CBX', 'depth_mm', 600.0)
          # Store per-bay unit specs so generate_unit_assembly_breakdown can expand to individual cards
          bay_specs = chunk[:units].map { |b| { 'width' => (b['width'] || 600).to_f, 'type' => (b['type'] || 'door').to_s, 'drawer_count' => (b['drawer_count'] || 3).to_i } }
          base_run_grp.set_attribute('CBX', 'is_continuous_run', true)
          base_run_grp.set_attribute('CBX', 'bay_units_json', bay_specs.to_json)
          base_run_grp.set_attribute('CBX', 'origin_x_mm', chunk[:start_x].to_mm)
          base_run_grp.set_attribute('CBX', 'wall_label', 'Wall A')

          # Add cooktop fixture if cooker bay present
          cur_bx = chunk[:start_x]
          chunk[:units].each do |b|
            bw = (b['width'] || 600).to_f.mm
            if b['type'].to_s == 'cooker'
              build_cooktop_and_hood(ents, cur_bx, bw, top_z, mats)
            end
            cur_bx += bw
          end
        end
      end
      # -------------------------------------------------------------
      # 2. BUILD WALL A TOP RUNS (MERGED CONTINUOUS RUNS)
      # -------------------------------------------------------------
      cur_ax = 0.mm
      a_list.each_with_index do |box, b_idx|
        bw = (box['width'] || 600).to_f.mm
        b_type = (box['type'] || 'door').to_s
        has_ovh = (box['overhead'] || 'yes').to_s

        if b_type != 'tall_oven' && b_type != 'tall_pantry' && has_ovh != 'none'
          if has_ovh == 'hood'
            top_bays_a << { width: 600.mm, is_hood: true, is_open: false, x: cur_ax }
          else
            top_bays_a << { width: bw, is_hood: false, is_open: (has_ovh == 'open_rack'), x: cur_ax }
          end
        end
        cur_ax += bw
      end

      if top_bays_a.any?
          build_continuous_top_runs_orchestrator(ents, top_bays_a, top_z, top_h, mats, false, 'Wall A')
      end

      # -------------------------------------------------------------
      # 3. BUILD WALL B RETURN BASE RUNS & TALL TOWERS
      # -------------------------------------------------------------
      b_list = custom_modules['B'] || []
      has_corner_on_b = b_list.any? { |b| (b['type'] || '').to_s == 'blind_corner' }

      if b_list.any?
        ret_base = ents.add_group
        ret_base.name = 'All_Aluminum_L_Return_Base'
        rb_ents = ret_base.entities

        b_chunks = partition_wall_modules(b_list)

        b_chunks.each_with_index do |chunk, c_idx|
          has_tall_after = (c_idx < b_chunks.length - 1 && b_chunks[c_idx + 1][:type] == :tall)

          if chunk[:type] == :tall
            box = chunk[:box]
            bw = (box['width'] || 600).to_f.mm

            CBXHybridEngine.build_aluminum_foot_frame(
              rb_ents, { width: bw, depth: 600.mm, x: chunk[:start_x] }, mats
            )

            tall_b = CBXHybridEngine.build_aluminum_top_cabinet(
              rb_ents,
              { width: bw, height: tall_h - CBXHybridEngine::PROFILE_HEIGHT, depth: 600.mm,
                x: chunk[:start_x], y: 0, z: CBXHybridEngine::PROFILE_HEIGHT,
                has_left_sash: true, has_right_sash: true, end_sash_panel: :acp, door_count: 1,
                door_handle_side: :opening, assembly_role: "Tall_Return_Tower_#{bw.to_mm.round}",
                shelves: :none }, mats
            )
            add_tall_interior_shelves(tall_b.entities, bw, tall_h - CBXHybridEngine::PROFILE_HEIGHT, 600.mm, mats)
            tall_b.name = "Unit_Return_Tall_Tower_#{bw.to_mm.round}"
            tall_b.set_attribute('CBX', 'is_cabinet_box', true)
            tall_b.set_attribute('CBX', 'unit_title', "Wall B Tall Appliance & Pantry Tower (#{bw.to_mm.round}mm)")
            tall_b.set_attribute('CBX', 'unit_type', 'Tall Appliance & Pantry Tower (Sash Shelves)')
            tall_b.set_attribute('CBX', 'width_mm', bw.to_mm)
            tall_b.set_attribute('CBX', 'height_mm', tall_h.to_mm)
            tall_b.set_attribute('CBX', 'depth_mm', 600.0)

          else
            # Merged Return Base Run
            total_run_w = chunk[:units].sum { |b| (b['width'] || 600).to_f.mm }
            run_units = chunk[:units].map do |b|
              bw = (b['width'] || 600).to_f.mm
              b_type = (b['type'] || 'door').to_s
              d_cnt = (b['drawer_count'] || 3).to_i
              if b_type == 'drawers'
                { width: bw, front: :drawers, drawer_count: d_cnt }
              elsif b_type == 'blind_corner'
                corner_actual_w = [bw, MIN_BASE_CORNER_WIDTH].max
                actual_blind_ret = [BASE_BLIND_RETURN, corner_actual_w - MIN_CORNER_DOOR_OPENING].min
                { width: corner_actual_w, front: :blind, blind_width: actual_blind_ret, blind_side: :left }
              else
                { width: bw, front: :door }
              end
            end

            ret_run_grp = CBXHybridEngine.build_aluminum_continuous_base_run(
              rb_ents,
              {
                width: total_run_w,
                height: base_h,
                depth: 600.mm,
                x: chunk[:start_x],
                y: 0,
                z: 0,
                units: run_units,
                left_end_panel: :none,
                right_end_panel: (has_tall_after ? :none : :acp),
                economy: (kitchen_type == 'ECONOMY_FRAME')
              },
              mats
            )
            ret_run_grp.name = "Aluminum_Continuous_Return_Base_Run_#{total_run_w.to_mm.round}mm"
            ret_run_grp.set_attribute('CBX', 'is_cabinet_box', true)
            ret_run_grp.set_attribute('CBX', 'unit_title', "Wall B Continuous Base Run (#{total_run_w.to_mm.round}mm)")
            ret_run_grp.set_attribute('CBX', 'unit_type', 'Continuous Aluminum Carcase Frame Run')
            ret_run_grp.set_attribute('CBX', 'width_mm', total_run_w.to_mm)
            ret_run_grp.set_attribute('CBX', 'height_mm', base_h.to_mm)
            ret_run_grp.set_attribute('CBX', 'depth_mm', 600.0)
            bay_specs_b = chunk[:units].map { |b| { 'width' => (b['width'] || 600).to_f, 'type' => (b['type'] || 'door').to_s, 'drawer_count' => (b['drawer_count'] || 3).to_i } }
            ret_run_grp.set_attribute('CBX', 'is_continuous_run', true)
            ret_run_grp.set_attribute('CBX', 'bay_units_json', bay_specs_b.to_json)
            ret_run_grp.set_attribute('CBX', 'origin_x_mm', chunk[:start_x].to_mm)
            ret_run_grp.set_attribute('CBX', 'wall_label', 'Wall B')
          end
        end

        corner_offset_b = has_corner_on_b ? 0.mm : BASE_BLIND_RETURN
        place_return_run(ret_base, wall_a, corner_offset_b)

        # -------------------------------------------------------------
        # 4. BUILD WALL B RETURN TOP RUNS (MERGED CONTINUOUS RUNS)
        # -------------------------------------------------------------
        top_corner_offset_b = has_corner_on_b ? 0.mm : TOP_BLIND_RETURN
        top_bays_b = []
        cur_bx = 0.mm
        b_list.each_with_index do |box, b_idx|
          bw = (box['width'] || 600).to_f.mm
          b_type = (box['type'] || 'door').to_s
          has_ovh = (box['overhead'] || 'yes').to_s

          if b_type != 'tall_oven' && b_type != 'tall_pantry' && has_ovh != 'none'
            if has_ovh == 'hood'
              top_bays_b << { width: 600.mm, is_hood: true, is_open: false, x: cur_bx }
            else
              top_bays_b << { width: bw, is_hood: false, is_open: (has_ovh == 'open_rack'), x: cur_bx }
            end
          end
          cur_bx += bw
        end

        if top_bays_b.any?
          ret_top = ents.add_group
          ret_top.name = 'All_Aluminum_L_Return_Tops'
          build_continuous_top_runs_orchestrator(ret_top.entities, top_bays_b, top_z, top_h, mats, true, 'Wall B')
          place_return_run(ret_top, wall_a, top_corner_offset_b)
        end
      end

      # -------------------------------------------------------------
      # 5. BUILD WALL C (U-SHAPE LEFT RETURN) BASE & TOP RUNS
      # -------------------------------------------------------------
      c_list = custom_modules['C'] || []
      if c_list.any?
        ret_c_base = ents.add_group
        ret_c_base.name = 'All_Aluminum_U_Return_C_Base'
        rcb_ents = ret_c_base.entities

        c_chunks = partition_wall_modules(c_list)
        total_c_run_w = 0.mm

        c_chunks.each_with_index do |chunk, c_idx|
          if chunk[:type] == :tall
            box = chunk[:box]
            bw = (box['width'] || 600).to_f.mm
            total_c_run_w += bw
            CBXHybridEngine.build_aluminum_foot_frame(
              rcb_ents, { width: bw, depth: 600.mm, x: chunk[:start_x] }, mats
            )
            tall_c = CBXHybridEngine.build_aluminum_top_cabinet(
              rcb_ents,
              { width: bw, height: tall_h - CBXHybridEngine::PROFILE_HEIGHT, depth: 600.mm,
                x: chunk[:start_x], y: 0, z: CBXHybridEngine::PROFILE_HEIGHT,
                has_left_sash: true, has_right_sash: true, end_sash_panel: :acp, door_count: 1,
                door_handle_side: :opening, assembly_role: "Tall_U_Return_Tower_#{bw.to_mm.round}",
                shelves: :none }, mats
            )
            add_tall_interior_shelves(tall_c.entities, bw, tall_h - CBXHybridEngine::PROFILE_HEIGHT, 600.mm, mats)
            tall_c.name = "Unit_U_Return_C_Tall_Tower_#{bw.to_mm.round}"
            tall_c.set_attribute('CBX', 'is_cabinet_box', true)
            tall_c.set_attribute('CBX', 'unit_title', "Wall C Tall Appliance Tower (#{bw.to_mm.round}mm)")
            tall_c.set_attribute('CBX', 'unit_type', 'Tall Appliance & Pantry Tower')
            tall_c.set_attribute('CBX', 'width_mm', bw.to_mm)
            tall_c.set_attribute('CBX', 'height_mm', tall_h.to_mm)
            tall_c.set_attribute('CBX', 'depth_mm', 600.0)
          else
            chunk_w = chunk[:units].sum { |b| (b['width'] || 600).to_f.mm }
            total_c_run_w += chunk_w
            run_units_c = chunk[:units].map do |b|
              bw = (b['width'] || 600).to_f.mm
              b_type = (b['type'] || 'door').to_s
              d_cnt = (b['drawer_count'] || 3).to_i
              if b_type == 'drawers'
                { width: bw, front: :drawers, drawer_count: d_cnt }
              else
                { width: bw, front: :door }
              end
            end

            c_run_grp = CBXHybridEngine.build_aluminum_continuous_base_run(
              rcb_ents,
              {
                width: chunk_w,
                height: base_h,
                depth: 600.mm,
                x: chunk[:start_x],
                y: 0,
                z: 0,
                units: run_units_c,
                left_end_panel: :acp,
                right_end_panel: :none,
                economy: (kitchen_type == 'ECONOMY_FRAME')
              },
              mats
            )
            c_run_grp.name = "Aluminum_Continuous_U_Return_C_Base_Run_#{chunk_w.to_mm.round}mm"
            c_run_grp.set_attribute('CBX', 'is_cabinet_box', true)
            c_run_grp.set_attribute('CBX', 'unit_title', "Wall C Continuous Base Run (#{chunk_w.to_mm.round}mm)")
            c_run_grp.set_attribute('CBX', 'unit_type', 'Continuous Aluminum Carcase Frame Run')
            c_run_grp.set_attribute('CBX', 'width_mm', chunk_w.to_mm)
            c_run_grp.set_attribute('CBX', 'height_mm', base_h.to_mm)
            c_run_grp.set_attribute('CBX', 'depth_mm', 600.0)
            bay_specs_c = chunk[:units].map { |b| { 'width' => (b['width'] || 600).to_f, 'type' => (b['type'] || 'door').to_s, 'drawer_count' => (b['drawer_count'] || 3).to_i } }
            c_run_grp.set_attribute('CBX', 'is_continuous_run', true)
            c_run_grp.set_attribute('CBX', 'bay_units_json', bay_specs_c.to_json)
            c_run_grp.set_attribute('CBX', 'origin_x_mm', chunk[:start_x].to_mm)
            c_run_grp.set_attribute('CBX', 'wall_label', 'Wall C')
          end
        end

        corner_offset_c = BASE_BLIND_RETURN
        place_left_return_run(ret_c_base, total_c_run_w, corner_offset_c)

        # -------------------------------------------------------------
        # 5.5 BUILD WALL C RETURN TOP RUNS (MERGED CONTINUOUS RUNS)
        # -------------------------------------------------------------
        has_corner_on_c = c_list.any? { |b| (b['type'] || '').to_s == 'blind_corner' }
        top_corner_offset_c = has_corner_on_c ? 0.mm : TOP_BLIND_RETURN
        top_bays_c = []
        cur_cx_top = 0.mm
        c_list.each_with_index do |box, c_idx|
          bw = (box['width'] || 600).to_f.mm
          b_type = (box['type'] || 'door').to_s
          has_ovh = (box['overhead'] || 'yes').to_s

          if b_type != 'tall_oven' && b_type != 'tall_pantry' && has_ovh != 'none'
            if has_ovh == 'hood'
              top_bays_c << { width: 600.mm, is_hood: true, is_open: false, x: cur_cx_top }
            else
              top_bays_c << { width: bw, is_hood: false, is_open: (has_ovh == 'open_rack'), x: cur_cx_top }
            end
          end
          cur_cx_top += bw
        end

        if top_bays_c.any?
          ret_c_top = ents.add_group
          ret_c_top.name = 'All_Aluminum_U_Return_C_Tops'
          build_continuous_top_runs_orchestrator(ret_c_top.entities, top_bays_c, top_z, top_h, mats, false, 'Wall C')
          total_c_run_w_top = c_list.sum { |b| (b['width'] || 600).to_f.mm }
          place_left_return_run(ret_c_top, total_c_run_w_top, top_corner_offset_c)
        end
      end

      # -------------------------------------------------------------
      # 6. BUILD ISLAND RUN
      # -------------------------------------------------------------
      isl_list = custom_modules['Island'] || []
      Sketchup.set_status_text("Cabinex AI: Building Island (#{isl_list.length} modules)...") if isl_list.any?
      if isl_list.any?
        isl_grp = ents.add_group
        isl_grp.name = 'Kitchen_Island_Run'
        isl_ents = isl_grp.entities

        isl_chunks = partition_wall_modules(isl_list)
        total_isl_w = isl_list.sum { |b| (b['width'] || 600).to_f.mm }

        isl_chunks.each do |chunk|
          if chunk[:type] != :tall
            chunk_w = chunk[:units].sum { |b| (b['width'] || 600).to_f.mm }
            run_units_isl = chunk[:units].map do |b|
              bw = (b['width'] || 600).to_f.mm
              b_type = (b['type'] || 'door').to_s
              d_cnt = (b['drawer_count'] || 3).to_i
              if b_type == 'drawers'
                { width: bw, front: :drawers, drawer_count: d_cnt }
              else
                { width: bw, front: :door }
              end
            end

            isl_run = CBXHybridEngine.build_aluminum_continuous_base_run(
              isl_ents,
              {
                width: chunk_w,
                height: base_h,
                depth: 600.mm,
                x: chunk[:start_x],
                y: 0,
                z: 0,
                units: run_units_isl,
                left_end_panel: :acp,
                right_end_panel: :acp,
                economy: (kitchen_type == 'ECONOMY_FRAME')
              },
              mats
            )
            isl_run.name = "Aluminum_Island_Base_Run_#{chunk_w.to_mm.round}mm"
            isl_run.set_attribute('CBX', 'is_cabinet_box', true)
            isl_run.set_attribute('CBX', 'unit_title', "Island Base Run (#{chunk_w.to_mm.round}mm)")
            isl_run.set_attribute('CBX', 'unit_type', 'Continuous Aluminum Carcase Frame Run')
            isl_run.set_attribute('CBX', 'width_mm', chunk_w.to_mm)
            isl_run.set_attribute('CBX', 'height_mm', base_h.to_mm)
            isl_run.set_attribute('CBX', 'depth_mm', 600.0)
            bay_specs_isl = chunk[:units].map { |b| { 'width' => (b['width'] || 600).to_f, 'type' => (b['type'] || 'door').to_s, 'drawer_count' => (b['drawer_count'] || 3).to_i } }
            isl_run.set_attribute('CBX', 'is_continuous_run', true)
            isl_run.set_attribute('CBX', 'bay_units_json', bay_specs_isl.to_json)
            isl_run.set_attribute('CBX', 'origin_x_mm', chunk[:start_x].to_mm)
            isl_run.set_attribute('CBX', 'wall_label', 'Island')
          end
        end

        isl_x = [(wall_a - total_isl_w) / 2.0, 0.mm].max
        if wall_c > 0 && wall_b > 0
          mid_u_depth = [wall_b, wall_c].min
          if mid_u_depth >= 2200.mm
            isl_y = -600.mm - 900.mm
          else
            isl_y = -[wall_b, wall_c].max - 1000.mm
          end
        else
          isl_y = -[wall_b, wall_c, 800.mm].max - 1100.mm
        end
        place_island_run(isl_grp, isl_x, isl_y)
      end
    end
  end
end

module CabinexAI
  HybridPlanner = CabinexAI::HybridPlanner
end
