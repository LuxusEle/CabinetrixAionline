# =============================================================================
# Cabinex AI Studio â€” Extension Bundle Loader
# (c) 2026 Cabinex AI. All Rights Reserved.
# Icons made by PixelLove (https://www.pixellove.com)
# =============================================================================

require 'sketchup.rb'
require 'json'

module CabinexAI
  CORE_DIR = File.expand_path(File.dirname(__FILE__))

  # CLEANUP: Previous loader versions accidentally created CabinexAI::CBXHybridEngine
  # (a near-empty module holding only nest_2d_sheets) which shadows the real
  # top-level ::CBXHybridEngine for all code inside the CabinexAI namespace.
  # Remove it so unqualified `CBXHybridEngine` references resolve to the real engine.
  remove_const(:CBXHybridEngine) if const_defined?(:CBXHybridEngine, false)

  # 1. Load Cloud Authentication & Licensing Client
  cloud_loader_file = File.join(CORE_DIR, 'cbx_cloud_loader.rb')
  load cloud_loader_file if File.exist?(cloud_loader_file)

  # 2. Load Core Board Extrusion & BOM Engine
  engine_file = File.join(CORE_DIR, 'cbx_hybrid_engine.rb')
  load engine_file if File.exist?(engine_file)

  # 2b. Load Construction Method & Connector Catalog (board master engine)
  method_file = File.join(CORE_DIR, 'cbx_cabinet_method.rb')
  load method_file if File.exist?(method_file)

  # 2c. Load Interactive Open-Front tool + Parts inspector (board QA)
  open_file = File.join(CORE_DIR, 'cbx_open_front.rb')
  load open_file if File.exist?(open_file)
  inspector_file = File.join(CORE_DIR, 'cbx_parts_inspector.rb')
  load inspector_file if File.exist?(inspector_file)

  # 3. Load Planner Orchestrator
  planner_file = File.join(CORE_DIR, 'cbx_hybrid_planner.rb')
  load planner_file if File.exist?(planner_file)

  # 4. Load Submodule Helpers
  hud_file = File.join(CORE_DIR, 'cbx_viewport_hud.rb')
  load hud_file if File.exist?(hud_file)

  editor_file = File.join(CORE_DIR, 'cbx_box_editor.rb')
  load editor_file if File.exist?(editor_file)

  exports_file = File.join(CORE_DIR, 'cbx_exports.rb')
  load exports_file if File.exist?(exports_file)

  # 5. PATCH: Ensure CBXHybridEngine has required attr_accessors
  # Cloud engine may redefine the module without them
  unless CBXHybridEngine.respond_to?(:top_door_style=)
    class << CBXHybridEngine
      attr_accessor :top_door_style, :base_door_style, :tall_unit_style
    end
  end
  CBXHybridEngine.top_door_style  ||= 'glass_sash'
  CBXHybridEngine.base_door_style ||= 'solid_acp'
  CBXHybridEngine.tall_unit_style ||= 'double_oven'

  # 6. PATCH: Fix cloud engine's nest_2d_sheets nil bug
  # Overrides the buggy method from the cloud-streamed engine.
  # IMPORTANT: must be `module ::CBXHybridEngine` (top-level). Writing plain
  # `module CBXHybridEngine` inside `module CabinexAI` would CREATE a new empty
  # CabinexAI::CBXHybridEngine that shadows the real engine and caused
  # "undefined method `build_base_cabinet'" errors in the planner.
  module ::CBXHybridEngine
    class << self
      def nest_2d_sheets(panels, sheet_w = 2440.0, sheet_h = 1220.0, kerf = 4.0, trim = 10.0)
        return { total_sheets: 0, total_panel_sqm: 0.0, total_sheet_sqm: 0.0, waste_pct: 0.0, sheets: [] } if panels.nil? || panels.empty?

        valid_panels = panels.select do |p|
          p.is_a?(Hash) &&
          p[:width_mm].to_f > 0 &&
          p[:height_mm].to_f > 0 &&
          p[:area_sqm].to_f > 0
        end

        return { total_sheets: 0, total_panel_sqm: 0.0, total_sheet_sqm: 0.0, waste_pct: 0.0, sheets: [] } if valid_panels.empty?

        effective_w = sheet_w - (trim * 2)
        effective_h = sheet_h - (trim * 2)

        sorted_panels = valid_panels.sort_by { |p| -(p[:width_mm] * p[:height_mm]) }
        sheets = []

        sorted_panels.each_with_index do |panel, p_idx|
          pw = panel[:width_mm].to_f
          ph = panel[:height_mm].to_f
          panel_area = panel[:area_sqm].to_f
          placed = false

          sheets.each do |sheet|
            free_rects = sheet[:free_rects] ||= []
            next if free_rects.empty?

            free_rects.each_with_index do |rect, r_idx|
              next unless rect.is_a?(Hash) && rect[:w].to_f > 0 && rect[:h].to_f > 0

              rect_w = rect[:w].to_f
              rect_h = rect[:h].to_f

              if pw <= rect_w && ph <= rect_h
                sheet[:cuts] ||= []
                sheet[:cuts] << {
                  id: "PNL-#{p_idx + 1}",
                  name: panel[:name].to_s,
                  x: rect[:x].to_f,
                  y: rect[:y].to_f,
                  w: pw, h: ph, area_sqm: panel_area
                }
                sheet[:used_area_sqm] = (sheet[:used_area_sqm] || 0) + panel_area

                free = free_rects.delete_at(r_idx)
                next unless free

                right_w = free[:w].to_f - pw - kerf
                right_h = ph
                bottom_w = free[:w].to_f
                bottom_h = free[:h].to_f - ph - kerf

                free_rects << { x: free[:x].to_f + pw + kerf, y: free[:y].to_f, w: right_w, h: right_h } if right_w > 50.0 && right_h > 50.0
                free_rects << { x: free[:x].to_f, y: free[:y].to_f + ph + kerf, w: bottom_w, h: bottom_h } if bottom_w > 50.0 && bottom_h > 50.0

                placed = true
                break

              elsif ph <= rect_w && pw <= rect_h
                sheet[:cuts] ||= []
                sheet[:cuts] << {
                  id: "PNL-#{p_idx + 1}",
                  name: panel[:name].to_s,
                  x: rect[:x].to_f,
                  y: rect[:y].to_f,
                  w: ph, h: pw, area_sqm: panel_area,
                  cutouts: panel[:cutouts] || [],
                  rotated: true
                }
                sheet[:used_area_sqm] = (sheet[:used_area_sqm] || 0) + panel_area

                free = free_rects.delete_at(r_idx)
                next unless free

                right_w = free[:w].to_f - ph - kerf
                right_h = pw
                bottom_w = free[:w].to_f
                bottom_h = free[:h].to_f - pw - kerf

                free_rects << { x: free[:x].to_f + ph + kerf, y: free[:y].to_f, w: right_w, h: right_h } if right_w > 50.0 && right_h > 50.0
                free_rects << { x: free[:x].to_f, y: free[:y].to_f + pw + kerf, w: bottom_w, h: bottom_h } if bottom_w > 50.0 && bottom_h > 50.0

                placed = true
                break
              end
            end
            break if placed
          end

          unless placed
            new_sheet = {
              sheet_id: sheets.length + 1,
              sheet_w: sheet_w, sheet_h: sheet_h,
              used_area_sqm: panel_area,
              cuts: [{
                id: "PNL-#{p_idx + 1}",
                name: panel[:name].to_s,
                x: trim, y: trim, w: pw, h: ph, area_sqm: panel_area,
                cutouts: panel[:cutouts] || [], rotated: false
              }],
              free_rects: []
            }
            r_w = effective_w - pw - kerf
            r_h = ph
            b_w = effective_w
            b_h = effective_h - ph - kerf

            new_sheet[:free_rects] << { x: trim + pw + kerf, y: trim, w: r_w, h: r_h } if r_w > 50.0 && r_h > 50.0
            new_sheet[:free_rects] << { x: trim, y: trim + ph + kerf, w: b_w, h: b_h } if b_w > 50.0 && b_h > 50.0

            sheets << new_sheet
          end
        end

        total_sheet_area = sheets.length * ((sheet_w * sheet_h) / 1_000_000.0)
        total_panel_area = valid_panels.sum { |p| p[:area_sqm].to_f }
        waste_pct = total_sheet_area > 0 ? (((total_sheet_area - total_panel_area) / total_sheet_area) * 100.0).round(1) : 0.0

        { total_sheets: sheets.length, total_panel_sqm: total_panel_area.round(2),
          total_sheet_sqm: total_sheet_area.round(2), waste_pct: waste_pct, sheets: sheets }
      end
    end
  end

  def self.check_license!
    saved_key = Sketchup.read_default('CabinexAI', 'license_key', '').to_s.strip
    if saved_key.empty?
      if defined?(CabinexAI::CloudLoader) && CabinexAI::CloudLoader.respond_to?(:show_login_dialog)
        CabinexAI::CloudLoader.show_login_dialog
      elsif defined?(CabinexAI::CloudLoader) && CabinexAI::CloudLoader.respond_to?(:show_login_dialog)
        CabinexAI::CloudLoader.show_login_dialog
      else
        UI.messagebox('CloudLoader is missing. Cannot authenticate.')
      end
      return false
    end
    true
  end

  def self.show_studio
    begin
      return unless check_license!

      # ALWAYS reload local engine & planner to ensure complete method set
      # Cloud engine (if loaded via auth) is a subset and overwrites CBXHybridEngine
      load File.join(CORE_DIR, 'cbx_hybrid_engine.rb')
      load File.join(CORE_DIR, 'cbx_cabinet_method.rb')
      load File.join(CORE_DIR, 'cbx_open_front.rb')
      load File.join(CORE_DIR, 'cbx_parts_inspector.rb')
      load File.join(CORE_DIR, 'cbx_hybrid_planner.rb')
      load File.join(CORE_DIR, 'cbx_viewport_hud.rb')
      load File.join(CORE_DIR, 'cbx_box_editor.rb')
      load File.join(CORE_DIR, 'cbx_exports.rb')

      # Ensure attr_accessors exist
      unless CBXHybridEngine.respond_to?(:top_door_style=)
        class << CBXHybridEngine
          attr_accessor :top_door_style, :base_door_style, :tall_unit_style
        end
      end
      CBXHybridEngine.top_door_style  ||= 'glass_sash'
      CBXHybridEngine.base_door_style ||= 'solid_acp'
      CBXHybridEngine.tall_unit_style ||= 'double_oven'

      # Verify critical methods
      critical = [:build_aluminum_continuous_base_run, :build_aluminum_continuous_wall_run,
                  :build_aluminum_top_cabinet, :build_aluminum_l_corner_tunnel,
                  :build_sash_assembly, :generate_bom_and_nesting]
      missing = critical.reject { |m| CBXHybridEngine.respond_to?(m) }
      if missing.any?
        puts ">> WARNING: Missing engine methods: #{missing.join(', ')}"
      end

      if defined?(CabinexAI::HybridPlanner) && CabinexAI::HybridPlanner.respond_to?(:show_dialog)
        CabinexAI::HybridPlanner.show_dialog
      elsif defined?(CabinexAI::CloudLoader) && CabinexAI::CloudLoader.respond_to?(:show_login_dialog)
        CabinexAI::CloudLoader.show_login_dialog
      else
        UI.messagebox('Cabinex Studio: Failed to load planner.')
      end
    rescue => err
      puts ">> Cabinex Studio Launch Error: #{err.message}\n#{err.backtrace.first(8).join("\n")}"
      UI.messagebox("Cabinex Studio Notice:\n\n#{err.message}\n\nPlease check Ruby Console.")
    end
  end

  # 5. Register Plugins Menu & Native Toolbar
  unless file_loaded?(__FILE__)
    menu = UI.menu('Plugins').add_submenu('Cabinex AI')

    menu.add_item('ðŸ  Cabinex Studio') {
      CabinexAI.show_studio
    }

    menu.add_item('ðŸ”‘ Cloud License & Login') {
      if defined?(CabinexAI::CloudLoader) && CabinexAI::CloudLoader.respond_to?(:show_login_dialog)
        CabinexAI::CloudLoader.show_login_dialog
      end
    }

    menu.add_item('ðŸ“¦ 3D Cabinet Box Editor') {
      return unless CabinexAI.check_license!
      if defined?(CabinexAI::BoxEditor) && CabinexAI::BoxEditor.respond_to?(:show_dialog)
        CabinexAI::BoxEditor.show_dialog
      elsif defined?(CabinexAI::BoxEditor) && CabinexAI::BoxEditor.respond_to?(:show_dialog)
        CabinexAI::BoxEditor.show_dialog
      else
        UI.messagebox('Please launch Cabinex Studio first.')
      end
    }

    menu.add_item('ðŸ“Š Live Viewport HUD') {
      return unless CabinexAI.check_license!
      if defined?(CabinexAI::ViewportHUD) && CabinexAI::ViewportHUD.respond_to?(:toggle)
        CabinexAI::ViewportHUD.toggle
      elsif defined?(CabinexAI::ViewportHUD) && CabinexAI::ViewportHUD.respond_to?(:toggle)
        CabinexAI::ViewportHUD.toggle
      else
        UI.messagebox('Viewport HUD is active with Studio.')
      end
    }

    menu.add_item('ðŸ“‘ Export PDF Workshop Report') {
      return unless CabinexAI.check_license!
      if defined?(CabinexAI::HybridPlanner) && CabinexAI::HybridPlanner.respond_to?(:show_workshop_report)
        CabinexAI::HybridPlanner.show_workshop_report
      elsif defined?(CabinexAI::HybridPlanner) && CabinexAI::HybridPlanner.respond_to?(:show_workshop_report)
        CabinexAI::HybridPlanner.show_workshop_report
      else
        UI.messagebox('Please generate a kitchen first.')
      end
    }

    # -------------------------------------------------------------------------
    # Native Toolbar with PixelLove Professional Construction Line Icons
    # -------------------------------------------------------------------------
    tb = UI::Toolbar.new('Cabinex AI')
    icons_dir = File.join(CORE_DIR, 'icons')

    # 1. Studio Button (Toolbox Icon)
    cmd_studio = UI::Command.new('Cabinex Studio') {
      CabinexAI.show_studio
    }
    cmd_studio.small_icon = File.join(icons_dir, 'studio_24.png')
    cmd_studio.large_icon = File.join(icons_dir, 'studio_48.png')
    cmd_studio.tooltip = 'Launch Cabinex AI Modular Board Kitchen Studio'
    cmd_studio.status_bar_text = 'Design custom Aluminum bar based carcases with optional sash/slab doors and instant BOM.'
    tb.add_item(cmd_studio)

    # 2. Cloud License Button (Set Square Icon)
    cmd_login = UI::Command.new('Cloud License') {
      if defined?(CabinexAI::CloudLoader) && CabinexAI::CloudLoader.respond_to?(:show_login_dialog)
        CabinexAI::CloudLoader.show_login_dialog
      end
    }
    cmd_login.small_icon = File.join(icons_dir, 'login_24.png')
    cmd_login.large_icon = File.join(icons_dir, 'login_48.png')
    cmd_login.tooltip = 'Cabinex Cloud Authentication & Token Manager'
    cmd_login.status_bar_text = 'Manage user licenses, token balances, and in-memory engine streaming.'
    tb.add_item(cmd_login)

    # 3. 3D Box Editor Button (Hammer & Screwdriver Icon)
    cmd_editor = UI::Command.new('Box Editor') {
      if CabinexAI.check_license!
        if defined?(CabinexAI::BoxEditor) && CabinexAI::BoxEditor.respond_to?(:show_dialog)
          CabinexAI::BoxEditor.show_dialog
        elsif defined?(CabinexAI::BoxEditor) && CabinexAI::BoxEditor.respond_to?(:show_dialog)
          CabinexAI::BoxEditor.show_dialog
        else
          CabinexAI.show_studio
        end
      end
    }
    cmd_editor.small_icon = File.join(icons_dir, 'editor_24.png')
    cmd_editor.large_icon = File.join(icons_dir, 'editor_48.png')
    cmd_editor.tooltip = 'Interactive 3D Cabinet Box Click-Editor'
    tb.add_item(cmd_editor)

    # 4. Viewport HUD Button (Spirit Level Icon)
    cmd_hud = UI::Command.new('Viewport HUD') {
      if CabinexAI.check_license!
        if defined?(CabinexAI::ViewportHUD) && CabinexAI::ViewportHUD.respond_to?(:toggle)
          CabinexAI::ViewportHUD.toggle
        elsif defined?(CabinexAI::ViewportHUD) && CabinexAI::ViewportHUD.respond_to?(:toggle)
          CabinexAI::ViewportHUD.toggle
        end
      end
    }
    cmd_hud.small_icon = File.join(icons_dir, 'hud_24.png')
    cmd_hud.large_icon = File.join(icons_dir, 'hud_48.png')
    cmd_hud.tooltip = 'Toggle Live 3D Viewport HUD Overlay'
    tb.add_item(cmd_hud)

    # 5. Workshop Report Button (Ruler & Pencil Icon)
    cmd_report = UI::Command.new('Workshop Report') {
      if CabinexAI.check_license!
        if defined?(CabinexAI::HybridPlanner) && CabinexAI::HybridPlanner.respond_to?(:show_workshop_report)
          CabinexAI::HybridPlanner.show_workshop_report
        elsif defined?(CabinexAI::HybridPlanner) && CabinexAI::HybridPlanner.respond_to?(:show_workshop_report)
          CabinexAI::HybridPlanner.show_workshop_report
        else
          CabinexAI.show_studio
        end
      end
    }
    cmd_report.small_icon = File.join(icons_dir, 'report_24.png')
    cmd_report.large_icon = File.join(icons_dir, 'report_48.png')
    cmd_report.tooltip = 'Export Workshop PDF & Technical Cutting Lists'
    tb.add_item(cmd_report)

    tb.show if tb.get_last_state == TB_VISIBLE || tb.get_last_state == TB_NEVER_SHOWN

    # Auto-Prompt for License on Startup
    UI.start_timer(1.0, false) do
      CabinexAI.check_license!
    end

    file_loaded?(__FILE__)
  end
end
