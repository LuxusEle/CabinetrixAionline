# ==============================================================================
# CABINETRIX AI — INTERACTIVE MODULAR BOX BUILDER STUDIO APP (GEMINI MODULE)
# Load in SketchUp Console:
#   load 'c:/Users/asank/Documents/CabinetrixAionline/gemini/run_box_builder_app.rb'
#
# Features:
#   • Interactive UI App with real-time box insertion buttons
#   • Automatic Right-Side Sequential Placement: Each box appears next to the previous
#   • Automatic Continuous Plinth Merging across base and island runs
#   • Full Box Types: Tall Towers, Base Gola Units, Wall Units, Island Run
#   • Full Doors, 45° Sash Glass, 18mm Door Overhangs, Hettich Actro 5D Motion
# ==============================================================================
require 'sketchup.rb'
require 'json'
require_relative 'cabinetrix_box_engine'

module CabinetrixBoxBuilderApp
  @dialog = nil
  @boxes = []
  @current_base_x = 0.0.mm
  @current_tall_x = 0.0.mm
  @current_wall_x = 0.0.mm
  @current_island_x = 0.0.mm
  @max_plinth_stock = 2400.0.mm

  def self.reset_state
    @boxes = []
    @current_base_x = 0.0.mm
    @current_tall_x = 0.0.mm
    @current_wall_x = 0.0.mm
    @current_island_x = 0.0.mm

    model = Sketchup.active_model
    if model
      model.start_operation("Reset Cabinetrix Builder", true)
      model.active_entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Cabinetrix') || g.name.to_s.start_with?('Box_') || g.name.to_s.start_with?('Plinth_') || g.name.to_s.start_with?('Continuous_') || g.name.to_s.start_with?('Island_') }.each { |g| g.erase! }
      model.commit_operation
      model.active_view.zoom_extents if model.active_view
    end
    update_ui_stats
  end

  def self.get_mats
    model = Sketchup.active_model
    CabinetrixLuxuryKitchen.get_materials(model)
  end

  def self.get_root_group
    model = Sketchup.active_model
    root = model.active_entities.grep(Sketchup::Group).find { |g| g.name == "Cabinetrix_Master_Interactive_Run" }
    unless root && root.valid?
      root = model.active_entities.add_group
      root.name = "Cabinetrix_Master_Interactive_Run"
    end
    root
  end

  # ----------------------------------------------------------------------------
  # BOX INSERTION ENGINE
  # ----------------------------------------------------------------------------
  def self.add_box(type, width_mm, opts = {})
    model = Sketchup.active_model
    return unless model

    model.start_operation("Add #{type} (#{width_mm}mm)", true)
    mats = get_mats
    root = get_root_group
    w = width_mm.mm

    box_id_num = @boxes.length + 1
    name = format("Box_%02d_%s_%dW", box_id_num, type.to_s.split('_').map(&:capitalize).join('_'), width_mm)

    case type
    # ------------------ TALL UNITS ------------------
    when :tall_oven_tower, :tall_pantry_larder
      x_pos = @current_tall_x
      CabinetrixBoxEngine.create_cabinet(
        root.entities,
        type,
        { name: name, width: w, depth: 600.mm, height: 2160.mm, mode: :hybrid, front_mat: mats[:front_dark] },
        { x: x_pos, y: 0.mm, z: 100.mm, facing_dir: :front },
        mats
      )
      @current_tall_x += w
      @current_base_x = [@current_base_x, @current_tall_x].max
      @current_wall_x = [@current_wall_x, @current_tall_x].max

    # ------------------ BASE GOLA UNITS ------------------
    when :base_gola_drawers, :base_gola_cooktop, :base_gola_sink, :base_gola_spice, :base_gola_wine
      x_pos = @current_base_x
      CabinetrixBoxEngine.create_cabinet(
        root.entities,
        type,
        { name: name, width: w, depth: 560.mm, height: 720.mm, mode: :hybrid, front_mat: mats[:front_dark] },
        { x: x_pos, y: 0.mm, z: 100.mm, facing_dir: :front },
        mats
      )
      @current_base_x += w
      update_continuous_base_plinth(root.entities, mats)

    # ------------------ WALL UNITS ------------------
    when :wall_glass_display, :wall_cooker_hood
      x_pos = @current_wall_x
      is_left = opts[:is_left_hinged] != false
      CabinetrixBoxEngine.create_cabinet(
        root.entities,
        type,
        { name: name, width: w, depth: 350.mm, height: 720.mm, is_left_hinged: is_left, front_mat: mats[:front_dark] },
        { x: x_pos, y: 0.mm, z: 1440.mm, facing_dir: :front },
        mats
      )
      @current_wall_x += w

    # ------------------ ISLAND UNITS ------------------
    when :island_gola_drawers, :island_gola_sink
      isl_prep_y = -1400.mm
      isl_rear_y = -1960.mm
      x_pos = 1000.mm + @current_island_x
      CabinetrixBoxEngine.create_cabinet(
        root.entities,
        type,
        { name: name, width: w, depth: 560.mm, height: 720.mm, mode: :hybrid, front_mat: mats[:front_cashmere] },
        { x: x_pos, y: isl_prep_y, z: 100.mm, facing_dir: :aisle },
        mats
      )
      @current_island_x += w
      update_continuous_island_plinth(root.entities, mats)
    end

    @boxes << { id: name, type: type, width: width_mm, x: x_pos }
    model.commit_operation
    model.active_view.zoom_extents if model.active_view
    update_ui_stats
  end

  # ----------------------------------------------------------------------------
  # CONTINUOUS MERGED PLINTH RUNNERS
  # ----------------------------------------------------------------------------
  def self.update_continuous_base_plinth(entities, mats)
    entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Plinth_Base_Run') }.each { |g| g.erase! }
    start_x = @current_tall_x > 0 ? @current_tall_x : 0.mm
    total_base_run = @current_base_x - start_x
    return if total_base_run <= 0

    curr_x = start_x + 10.mm
    rem = total_base_run - 20.mm
    idx = 1

    while rem > 0
      len = [rem, @max_plinth_stock].min
      CabinetrixBoxEngine.create_box(entities, [curr_x, -560.mm + 50.mm, 0], [len, 18.mm, 100.mm], mats[:plinth], "Plinth_Base_Run_Section_#{idx}")
      curr_x += len
      rem -= len
      idx += 1
    end
  end

  def self.update_continuous_island_plinth(entities, mats)
    entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Plinth_Island_Run') }.each { |g| g.erase! }
    total_isl_run = @current_island_x
    return if total_isl_run <= 0

    curr_x = 1000.mm + 10.mm
    rem = total_isl_run - 20.mm
    idx = 1

    while rem > 0
      len = [rem, @max_plinth_stock].min
      CabinetrixBoxEngine.create_box(entities, [curr_x, -1400.mm - 560.mm + 50.mm, 0], [len, 18.mm, 100.mm], mats[:plinth], "Plinth_Island_Run_Section_#{idx}")
      curr_x += len
      rem -= len
      idx += 1
    end
  end

  def self.add_countertops_and_pelmets
    model = Sketchup.active_model
    return unless model

    model.start_operation("Add Worktops & Pelmets", true)
    mats = get_mats
    root = get_root_group

    # 1. Main Base Worktop
    start_x = @current_tall_x > 0 ? @current_tall_x : 0.mm
    base_w = @current_base_x - start_x
    if base_w > 0
      CabinetrixBoxEngine.create_box(root.entities, [start_x, -600.mm, 820.mm], [base_w, 600.mm, 20.mm], mats[:marble], "Main_Worktop_Slab")
    end

    # 2. Wall Pelmet
    wall_start = @current_tall_x > 0 ? @current_tall_x : 0.mm
    wall_w = @current_wall_x - wall_start
    if wall_w > 0
      CabinetrixLuxuryKitchen.build_continuous_pelmet(root.entities, wall_start, wall_w, 350.mm, 1440.mm, mats)
    end

    # 3. Island Worktop & Waterfall
    if @current_island_x > 0
      isl_ox = 1000.mm
      isl_w = @current_island_x
      CabinetrixBoxEngine.create_box(root.entities, [isl_ox, -2300.mm, 820.mm], [isl_w, 900.mm, 20.mm], mats[:marble], "Island_Worktop_Slab")
      CabinetrixBoxEngine.create_box(root.entities, [isl_ox - 20.mm, -2300.mm, 0], [20.mm, 900.mm, 840.mm], mats[:marble], "Island_Waterfall_LH")
      CabinetrixBoxEngine.create_box(root.entities, [isl_ox + isl_w, -2300.mm, 0], [20.mm, 900.mm, 840.mm], mats[:marble], "Island_Waterfall_RH")
      CabinetrixBoxEngine.create_box(root.entities, [isl_ox, -1960.mm - 18.mm, 100.mm], [isl_w, 18.mm, 720.mm], mats[:front_cashmere], "Island_Back_Cladding")
    end

    model.commit_operation
    model.active_view.zoom_extents if model.active_view
  end

  # ----------------------------------------------------------------------------
  # UI CONTROLLER & HTML DIALOG
  # ----------------------------------------------------------------------------
  def self.update_ui_stats
    return unless @dialog
    stats = {
      count: @boxes.length,
      tall_w: @current_tall_x.to_mm.round,
      base_w: @current_base_x.to_mm.round,
      wall_w: @current_wall_x.to_mm.round,
      island_w: @current_island_x.to_mm.round,
      boxes: @boxes
    }
    @dialog.execute_script("updateStats(#{stats.to_json});")
  end

  def self.show_app
    if @dialog && @dialog.visible?
      @dialog.bring_to_front
      return
    end

    @dialog = UI::HtmlDialog.new(
      dialog_title: "Cabinetrix AI — Interactive Box Studio",
      preferences_key: "Cabinetrix_Box_Studio_App",
      scrollable: true,
      resizable: true,
      width: 480,
      height: 780,
      left: 100,
      top: 100,
      min_width: 420,
      min_height: 500
    )

    html = <<~HTML
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <style>
          :root { --primary: #2563eb; --dark: #0f172a; --panel: #ffffff; --bg: #f1f5f9; --border: #cbd5e1; --text: #0f172a; }
          * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-size: 13px; }
          body { background: var(--bg); color: var(--text); padding: 16px; }
          .header { background: linear-gradient(135deg, #0f172a, #1e293b); color: white; padding: 16px; border-radius: 8px; margin-bottom: 14px; }
          .header h1 { font-size: 16px; font-weight: bold; color: #fff; }
          .header p { font-size: 11px; color: #94a3b8; margin-top: 4px; }
          .stats { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; margin-bottom: 14px; }
          .stat-box { background: white; padding: 10px; border-radius: 6px; border: 1px solid var(--border); }
          .stat-box .lbl { font-size: 10px; color: #64748b; text-transform: uppercase; font-weight: 600; }
          .stat-box .val { font-size: 15px; font-weight: bold; color: var(--dark); margin-top: 2px; }
          .category { background: white; border-radius: 8px; border: 1px solid var(--border); padding: 12px; margin-bottom: 12px; }
          .category h2 { font-size: 12px; text-transform: uppercase; color: #475569; letter-spacing: 0.5px; margin-bottom: 10px; font-weight: 700; }
          .btn-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
          button { background: #f8fafc; border: 1px solid #cbd5e1; padding: 10px; border-radius: 6px; font-weight: 600; color: #1e293b; cursor: pointer; transition: all 0.15s ease; text-align: left; }
          button:hover { background: #e2e8f0; border-color: #94a3b8; transform: translateY(-1px); }
          button:active { transform: translateY(0); }
          .btn-tall { border-left: 4px solid #8b5cf6; }
          .btn-base { border-left: 4px solid #3b82f6; }
          .btn-wall { border-left: 4px solid #10b981; }
          .btn-island { border-left: 4px solid #f59e0b; }
          .btn-action { background: var(--dark); color: white; border: none; text-align: center; }
          .btn-action:hover { background: #334155; }
          .btn-reset { background: #ef4444; color: white; border: none; text-align: center; }
          .btn-reset:hover { background: #dc2626; }
          .full-btn { grid-column: span 2; }
          .history { max-height: 120px; overflow-y: auto; background: #f8fafc; border: 1px solid var(--border); border-radius: 6px; padding: 8px; font-family: monospace; font-size: 11px; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Cabinetrix AI — Interactive Studio</h1>
          <p>Click any box button to place it sequentially on the right side.</p>
        </div>

        <div class="stats">
          <div class="stat-box"><div class="lbl">Total Boxes</div><div class="val" id="st_count">0</div></div>
          <div class="stat-box"><div class="lbl">Base Run Width</div><div class="val" id="st_base">0 mm</div></div>
          <div class="stat-box"><div class="lbl">Wall Run Width</div><div class="val" id="st_wall">0 mm</div></div>
          <div class="stat-box"><div class="lbl">Island Width</div><div class="val" id="st_island">0 mm</div></div>
        </div>

        <div class="category">
          <h2>1. Tall Towers (600D x 2160H)</h2>
          <div class="btn-grid">
            <button class="btn-tall" onclick="callRuby('add_tall_oven', 600)">+ Oven Tower (600W)</button>
            <button class="btn-tall" onclick="callRuby('add_tall_pantry', 600)">+ Pantry Larder (600W)</button>
          </div>
        </div>

        <div class="category">
          <h2>2. Base Gola Cabinets (560D x 720H)</h2>
          <div class="btn-grid">
            <button class="btn-base" onclick="callRuby('add_base_drawers', 600)">+ 2-Drawers (600W)</button>
            <button class="btn-base" onclick="callRuby('add_base_drawers', 800)">+ 2-Drawers (800W)</button>
            <button class="btn-base" onclick="callRuby('add_base_cooktop', 900)">+ Cooktop (900W)</button>
            <button class="btn-base" onclick="callRuby('add_base_sink', 600)">+ Sink Unit (600W)</button>
            <button class="btn-base" onclick="callRuby('add_base_spice', 300)">+ Spice Pullout (300W)</button>
            <button class="btn-base" onclick="callRuby('add_base_wine', 600)">+ Wine Unit (600W)</button>
          </div>
        </div>

        <div class="category">
          <h2>3. Wall Cabinets (350D x 720H)</h2>
          <div class="btn-grid">
            <button class="btn-wall" onclick="callRuby('add_wall_glass', 300, {is_left_hinged: true})">+ Glass Sash (300W)</button>
            <button class="btn-wall" onclick="callRuby('add_wall_glass', 600, {is_left_hinged: true})">+ Glass Sash (600W LH)</button>
            <button class="btn-wall" onclick="callRuby('add_wall_glass', 600, {is_left_hinged: false})">+ Glass Sash (600W RH)</button>
            <button class="btn-wall" onclick="callRuby('add_wall_hood', 900)">+ Cooker Hood (900W)</button>
          </div>
        </div>

        <div class="category">
          <h2>4. Island Cabinets (560D x 720H)</h2>
          <div class="btn-grid">
            <button class="btn-island" onclick="callRuby('add_island_drawers', 600)">+ Island Drawers (600W)</button>
            <button class="btn-island" onclick="callRuby('add_island_sink', 600)">+ Island Sink (600W)</button>
            <button class="btn-island full-btn" onclick="callRuby('add_island_drawers', 800)">+ Island Multi-Drawers (800W)</button>
          </div>
        </div>

        <div class="category">
          <h2>5. Finishing & Assembly</h2>
          <div class="btn-grid">
            <button class="btn-action full-btn" onclick="callRuby('add_finishes')">✨ Add Worktops, Waterfalls & Pelmets</button>
            <button class="btn-reset full-btn" onclick="callRuby('reset')">🗑️ Clear / Reset Kitchen</button>
          </div>
        </div>

        <script>
          function callRuby(action, param1, param2) {
            sketchup.handleAction({ action: action, val1: param1, val2: param2 });
          }

          function updateStats(data) {
            document.getElementById('st_count').innerText = data.count;
            document.getElementById('st_base').innerText = data.base_w + ' mm';
            document.getElementById('st_wall').innerText = data.wall_w + ' mm';
            document.getElementById('st_island').innerText = data.island_w + ' mm';
          }
        </script>
      </body>
      </html>
    HTML

    @dialog.set_html(html)

    @dialog.add_action_callback("handleAction") do |_ctx, params|
      act = params['action']
      v1  = params['val1']
      v2  = params['val2'] || {}

      case act
      when 'add_tall_oven'
        add_box(:tall_oven_tower, v1)
      when 'add_tall_pantry'
        add_box(:tall_pantry_larder, v1)
      when 'add_base_drawers'
        add_box(:base_gola_drawers, v1)
      when 'add_base_cooktop'
        add_box(:base_gola_cooktop, v1)
      when 'add_base_sink'
        add_box(:base_gola_sink, v1)
      when 'add_base_spice'
        add_box(:base_gola_spice, v1)
      when 'add_base_wine'
        add_box(:base_gola_wine, v1)
      when 'add_wall_glass'
        add_box(:wall_glass_display, v1, is_left_hinged: v2['is_left_hinged'])
      when 'add_wall_hood'
        add_box(:wall_cooker_hood, v1)
      when 'add_island_drawers'
        add_box(:island_gola_drawers, v1)
      when 'add_island_sink'
        add_box(:island_gola_sink, v1)
      when 'add_finishes'
        add_countertops_and_pelmets
      when 'reset'
        reset_state
      end
    end

    @dialog.show
    update_ui_stats
  end
end

# Auto-launch app dialog on load
if defined?(Sketchup) && Sketchup.active_model
  CabinetrixBoxBuilderApp.show_app
end
