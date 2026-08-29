# ==============================================================================
# CABINETRIX AI — INTERACTIVE MODULAR BOX BUILDER STUDIO APP (GEMINI MODULE)
# Load in SketchUp Console:
#   load 'c:/Users/asank/Documents/CabinetrixAionline/gemini/run_box_builder_app.rb'
# ==============================================================================
require 'sketchup.rb'
require 'json'
require_relative 'cabinetrix_box_engine'
require_relative 'cabinetrix_wardrobe_engine'

module CabinetrixBoxBuilderApp
  @dialog = nil
  @boxes = []
  @base_boxes = []
  @wardrobe_boxes = []
  @island_boxes = []
  @current_main_x    = 0.0.mm
  @current_wardrobe_x= 0.0.mm
  @current_wall_x    = 0.0.mm
  @current_island_x  = 0.0.mm
  @max_plinth_stock  = 2400.0.mm
  @max_gola_stock    = 3000.0.mm

  def self.reset_state
    @boxes = []
    @base_boxes = []
    @wardrobe_boxes = []
    @island_boxes = []
    @current_main_x     = 0.0.mm
    @current_wardrobe_x = 0.0.mm
    @current_wall_x     = 0.0.mm
    @current_island_x   = 0.0.mm

    model = Sketchup.active_model
    if model
      model.start_operation("Reset Cabinetrix Builder", true)
      model.active_entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Cabinetrix') || g.name.to_s.start_with?('Box_') || g.name.to_s.start_with?('Wardrobe_') || g.name.to_s.start_with?('Plinth_') || g.name.to_s.start_with?('Continuous_') || g.name.to_s.start_with?('Gola_Continuous_') || g.name.to_s.start_with?('Island_') }.each { |g| g.erase! }
      model.commit_operation
      model.active_view.zoom_extents if model.active_view
    end
    update_ui_stats
  end

  def self.get_mats
    model = Sketchup.active_model
    mats = model.materials

    carcase_mat = mats['CBX_Melamine_White'] || mats.add('CBX_Melamine_White')
    carcase_mat.color = Sketchup::Color.new(245, 245, 242)

    front_dark = mats['CBX_Front_Anthracite'] || mats.add('CBX_Front_Anthracite')
    front_dark.color = Sketchup::Color.new(42, 45, 50)

    front_cashmere = mats['CBX_Front_Cashmere'] || mats.add('CBX_Front_Cashmere')
    front_cashmere.color = Sketchup::Color.new(215, 208, 198)

    alu_black = mats['CBX_Alu_Black_Anodized'] || mats.add('CBX_Alu_Black_Anodized')
    alu_black.color = Sketchup::Color.new(25, 27, 30)

    marble_mat = mats['CBX_Calacatta_Marble'] || mats.add('CBX_Calacatta_Marble')
    marble_mat.color = Sketchup::Color.new(248, 246, 242)

    glass_mat = mats['CBX_Clear_Glass'] || mats.add('CBX_Clear_Glass')
    glass_mat.color = Sketchup::Color.new(210, 235, 245)
    glass_mat.alpha = 0.35

    cam_mat = mats['CBX_Minifix_Zinc'] || mats.add('CBX_Minifix_Zinc')
    cam_mat.color = Sketchup::Color.new(180, 185, 190)

    steel_mat = mats['CBX_Stainless_Steel'] || mats.add('CBX_Stainless_Steel')
    steel_mat.color = Sketchup::Color.new(140, 145, 155)

    wood_mat = mats['CBX_Natural_Birch'] || mats.add('CBX_Natural_Birch')
    wood_mat.color = Sketchup::Color.new(225, 212, 190)

    dowel_mat = mats['CBX_Beech_Dowel'] || mats.add('CBX_Beech_Dowel')
    dowel_mat.color = Sketchup::Color.new(215, 160, 95)

    hole_mat = mats['CBX_CNC_Bore_Dark'] || mats.add('CBX_CNC_Bore_Dark')
    hole_mat.color = Sketchup::Color.new(20, 20, 20)

    accent_mat = mats['CBX_Indicator_Orange'] || mats.add('CBX_Indicator_Orange')
    accent_mat.color = Sketchup::Color.new(240, 80, 20)

    led_mat = mats['CBX_LED_Warm_Glow'] || mats.add('CBX_LED_Warm_Glow')
    led_mat.color = Sketchup::Color.new(255, 245, 210)

    diffuser_mat = mats['CBX_LED_Frosted_Diffuser'] || mats.add('CBX_LED_Frosted_Diffuser')
    diffuser_mat.color = Sketchup::Color.new(250, 250, 245)
    diffuser_mat.alpha = 0.85

    plinth_mat = mats['CBX_Plinth_Black'] || mats.add('CBX_Plinth_Black')
    plinth_mat.color = Sketchup::Color.new(30, 32, 35)

    {
      carcase: carcase_mat, front_dark: front_dark, front_cashmere: front_cashmere,
      gola: alu_black, marble: marble_mat, glass: glass_mat, cam: cam_mat,
      steel: steel_mat, wood: wood_mat, dowel: dowel_mat, hole: hole_mat,
      accent: accent_mat, led: led_mat, diffuser: diffuser_mat, plinth: plinth_mat
    }
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
  # BOX & WARDROBE INSERTION ENGINE
  # ----------------------------------------------------------------------------
  def self.add_wardrobe_box(type, width_mm)
    model = Sketchup.active_model
    return unless model

    model.start_operation("Add Wardrobe #{type} (#{width_mm}mm)", true)
    mats = get_mats
    root = get_root_group
    w = width_mm.mm

    robe_idx = @wardrobe_boxes.length + 1
    name = format("Wardrobe_%02d_%s_%dW", robe_idx, type.to_s.split('_').map(&:capitalize).join('_'), width_mm)
    x_pos = @current_wardrobe_x

    CabinetrixWardrobeEngine.build_wardrobe(
      root.entities,
      type,
      { name: name, width: w, depth: 600.mm, height: 2160.mm, mode: :hybrid },
      { x: x_pos, y: -2500.mm, z: 100.mm },
      mats
    )

    @wardrobe_boxes << { id: name, type: type, width: width_mm, x: x_pos, w: w }
    @current_wardrobe_x += w
    update_continuous_wardrobe_plinth(root.entities, mats)

    model.commit_operation
    model.active_view.zoom_extents if model.active_view
    update_ui_stats
  end

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
    # ------------------ TALL TOWERS ------------------
    when :tall_oven_tower, :tall_pantry_larder
      x_pos = @current_main_x
      CabinetrixBoxEngine.create_cabinet(
        root.entities,
        type,
        { name: name, width: w, depth: 600.mm, height: 2160.mm, mode: :hybrid, front_mat: mats[:front_dark] },
        { x: x_pos, y: 0.mm, z: 100.mm, facing_dir: :front },
        mats
      )
      @current_main_x += w
      @current_wall_x = [@current_wall_x, @current_main_x].max

    # ------------------ BASE GOLA & CORNERS ------------------
    when :base_gola_drawers, :base_gola_cooktop, :base_gola_sink, :base_gola_spice, :base_gola_wine, :base_blind_corner, :base_l_corner_easy_reach
      x_pos = @current_main_x
      is_corner = (type == :base_blind_corner || type == :base_l_corner_easy_reach)
      CabinetrixBoxEngine.create_cabinet(
        root.entities,
        type,
        { name: name, width: w, depth: 560.mm, height: 720.mm, mode: :hybrid, front_mat: mats[:front_dark], include_gola: false },
        { x: x_pos, y: 0.mm, z: 100.mm, facing_dir: :front },
        mats
      )
      @base_boxes << { x: x_pos, w: w, is_corner: is_corner }
      @current_main_x += w
      update_exact_base_golas(root.entities, mats)
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
      x_pos = 1000.mm + @current_island_x
      CabinetrixBoxEngine.create_cabinet(
        root.entities,
        type,
        { name: name, width: w, depth: 560.mm, height: 720.mm, mode: :hybrid, front_mat: mats[:front_cashmere], include_gola: false },
        { x: x_pos, y: isl_prep_y, z: 100.mm, facing_dir: :aisle },
        mats
      )
      @island_boxes << { x: x_pos, w: w }
      @current_island_x += w
      update_exact_island_golas(root.entities, mats)
      update_continuous_island_plinth(root.entities, mats)
    end

    @boxes << { id: name, type: type, width: width_mm, x: x_pos }
    model.commit_operation
    model.active_view.zoom_extents if model.active_view
    update_ui_stats
  end

  # ----------------------------------------------------------------------------
  # EXACT GOLA PROFILES (MERGES CONTINUOUSLY ACROSS CONNECTED BASE BOXES ONLY)
  # ----------------------------------------------------------------------------
  def self.update_exact_base_golas(entities, mats)
    entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Gola_Continuous_Base_') }.each { |g| g.erase! }
    return if @base_boxes.empty?

    runs = []
    current_run = nil

    @base_boxes.each do |b|
      next if b[:is_corner]
      if current_run.nil? || (current_run[:x] + current_run[:w] != b[:x])
        runs << current_run if current_run
        current_run = { x: b[:x], w: b[:w] }
      else
        current_run[:w] += b[:w]
      end
    end
    runs << current_run if current_run

    runs.each_with_index do |run, idx|
      curr_x = run[:x]
      rem    = run[:w]
      sec    = 1
      while rem > 0
        len = [rem, @max_gola_stock].min
        l_grp = CabinetrixBoxEngine.build_gola_profile(entities, :l, len, Geom::Point3d.new(curr_x, -560.mm + 26.mm, 100.mm + 720.mm - 59.mm), mats, facing_dir: :front)
        l_grp.name = "Gola_Continuous_Base_L_Run#{idx+1}_Sec#{sec}"

        c_grp = CabinetrixBoxEngine.build_gola_profile(entities, :c, len, Geom::Point3d.new(curr_x, -560.mm + 26.mm, 100.mm + 330.mm), mats, facing_dir: :front)
        c_grp.name = "Gola_Continuous_Base_C_Run#{idx+1}_Sec#{sec}"

        curr_x += len
        rem -= len
        sec += 1
      end
    end
  end

  def self.update_exact_island_golas(entities, mats)
    entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Gola_Continuous_Island_') }.each { |g| g.erase! }
    return if @island_boxes.empty?

    total_len = @current_island_x
    curr_x = 1000.mm
    rem = total_len
    sec = 1

    while rem > 0
      len = [rem, @max_gola_stock].min
      l_grp = CabinetrixBoxEngine.build_gola_profile(entities, :l, len, Geom::Point3d.new(curr_x, -1400.mm - 26.mm, 100.mm + 720.mm - 59.mm), mats, facing_dir: :aisle)
      l_grp.name = "Gola_Continuous_Island_L_Sec#{sec}"

      c_grp = CabinetrixBoxEngine.build_gola_profile(entities, :c, len, Geom::Point3d.new(curr_x, -1400.mm - 26.mm, 100.mm + 330.mm), mats, facing_dir: :aisle)
      c_grp.name = "Gola_Continuous_Island_C_Sec#{sec}"

      curr_x += len
      rem -= len
      sec += 1
    end
  end

  # ----------------------------------------------------------------------------
  # CONTINUOUS MERGED PLINTH RUNNERS
  # ----------------------------------------------------------------------------
  def self.update_continuous_base_plinth(entities, mats)
    entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Plinth_Base_Run') }.each { |g| g.erase! }
    return if @base_boxes.empty?

    start_x = @base_boxes.first[:x] + 10.mm
    end_x   = @base_boxes.last[:x] + @base_boxes.last[:w] - 10.mm
    total_len = end_x - start_x
    return if total_len <= 0

    curr_x = start_x
    rem = total_len
    idx = 1
    while rem > 0
      len = [rem, @max_plinth_stock].min
      CabinetrixBoxEngine.create_box(entities, [curr_x, -560.mm + 50.mm, 0], [len, 18.mm, 100.mm], mats[:plinth], "Plinth_Base_Run_Section_#{idx}")
      curr_x += len
      rem -= len
      idx += 1
    end
  end

  def self.update_continuous_wardrobe_plinth(entities, mats)
    entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Plinth_Wardrobe_Run') }.each { |g| g.erase! }
    return if @wardrobe_boxes.empty?

    start_x = @wardrobe_boxes.first[:x] + 10.mm
    end_x   = @wardrobe_boxes.last[:x] + @wardrobe_boxes.last[:w] - 10.mm
    total_w_run = end_x - start_x
    return if total_w_run <= 0

    curr_x = start_x
    rem = total_w_run
    idx = 1
    while rem > 0
      len = [rem, @max_plinth_stock].min
      CabinetrixBoxEngine.create_box(entities, [curr_x, -2500.mm - 600.mm + 50.mm, 0], [len, 18.mm, 100.mm], mats[:plinth], "Plinth_Wardrobe_Run_Section_#{idx}")
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

    if @base_boxes.any?
      start_x = @base_boxes.first[:x]
      end_x   = @base_boxes.last[:x] + @base_boxes.last[:w]
      base_w  = end_x - start_x
      CabinetrixBoxEngine.create_box(root.entities, [start_x, -600.mm, 820.mm], [base_w, 600.mm, 20.mm], mats[:marble], "Main_Worktop_Slab")
    end

    if @boxes.any? { |b| b[:type].to_s.start_with?('wall') }
      wall_boxes = @boxes.select { |b| b[:type].to_s.start_with?('wall') }
      wall_start = wall_boxes.first[:x]
      wall_end   = wall_boxes.last[:x] + wall_boxes.last[:width].mm
      wall_w     = wall_end - wall_start
      if wall_w > 0
        pelmet_z = 1440.mm - 18.mm
        cover_y_front = -350.mm + 25.mm
        cover_d = 350.mm - 25.mm - 15.mm
        CabinetrixBoxEngine.create_box(root.entities, [wall_start, cover_y_front, pelmet_z], [wall_w, cover_d, 18.mm], mats[:carcase], "Continuous_Pelmet_Board")
        CabinetrixBoxEngine.create_box(root.entities, [wall_start, -15.mm, pelmet_z], [wall_w, 15.mm, 12.mm], mats[:gola], "Continuous_Alu_LED_Housing")
        CabinetrixBoxEngine.create_box(root.entities, [wall_start + 1.mm, -13.5.mm, pelmet_z - 1.5.mm], [wall_w - 2.mm, 12.mm, 2.mm], mats[:diffuser], "Continuous_LED_Diffuser")
      end
    end

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
      count: @boxes.length + @wardrobe_boxes.length,
      main_w: @current_main_x.to_mm.round,
      wardrobe_w: @current_wardrobe_x.to_mm.round,
      island_w: @current_island_x.to_mm.round
    }
    @dialog.execute_script("updateStats(#{stats.to_json});")
  end

  def self.show_app
    if @dialog && @dialog.visible?
      @dialog.bring_to_front
      return
    end

    @dialog = UI::HtmlDialog.new(
      dialog_title: "Cabinetrix AI — Interactive Studio",
      preferences_key: "Cabinetrix_Box_Studio_App",
      scrollable: true,
      resizable: true,
      width: 520,
      height: 860,
      left: 80,
      top: 60,
      min_width: 440,
      min_height: 520
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
          .stat-box { background: white; padding: 8px; border-radius: 6px; border: 1px solid var(--border); }
          .stat-box .lbl { font-size: 10px; color: #64748b; text-transform: uppercase; font-weight: 600; }
          .stat-box .val { font-size: 14px; font-weight: bold; color: var(--dark); margin-top: 2px; }
          .category { background: white; border-radius: 8px; border: 1px solid var(--border); padding: 12px; margin-bottom: 12px; }
          .category h2 { font-size: 12px; text-transform: uppercase; color: #475569; letter-spacing: 0.5px; margin-bottom: 10px; font-weight: 700; }
          .btn-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
          button { background: #f8fafc; border: 1px solid #cbd5e1; padding: 10px; border-radius: 6px; font-weight: 600; color: #1e293b; cursor: pointer; transition: all 0.15s ease; text-align: left; }
          button:hover { background: #e2e8f0; border-color: #94a3b8; transform: translateY(-1px); }
          button:active { transform: translateY(0); }
          .btn-tall { border-left: 4px solid #8b5cf6; }
          .btn-wardrobe { border-left: 4px solid #ec4899; }
          .btn-base { border-left: 4px solid #3b82f6; }
          .btn-corner { border-left: 4px solid #06b6d4; }
          .btn-wall { border-left: 4px solid #10b981; }
          .btn-island { border-left: 4px solid #f59e0b; }
          .btn-action { background: var(--dark); color: white; border: none; text-align: center; }
          .btn-action:hover { background: #334155; }
          .btn-reset { background: #ef4444; color: white; border: none; text-align: center; }
          .btn-reset:hover { background: #dc2626; }
          .full-btn { grid-column: span 2; }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>Cabinetrix AI — Interactive Studio</h1>
          <p>Full Kitchen & Architectural Wardrobe Engine</p>
        </div>

        <div class="stats">
          <div class="stat-box"><div class="lbl">Total Units Placed</div><div class="val" id="st_count">0</div></div>
          <div class="stat-box"><div class="lbl">Kitchen Main Run</div><div class="val" id="st_main">0 mm</div></div>
          <div class="stat-box"><div class="lbl">Wardrobe Run</div><div class="val" id="st_wardrobe">0 mm</div></div>
          <div class="stat-box"><div class="lbl">Island Run</div><div class="val" id="st_island">0 mm</div></div>
        </div>

        <div class="category">
          <h2>1. Architectural Wardrobes (600D x 2160H)</h2>
          <div class="btn-grid">
            <button class="btn-wardrobe" onclick="callRuby('add_wardrobe', 'single_hang', 600)">+ Single Hang (600W)</button>
            <button class="btn-wardrobe" onclick="callRuby('add_wardrobe', 'single_hang', 900)">+ Single Hang (900W)</button>
            <button class="btn-wardrobe" onclick="callRuby('add_wardrobe', 'double_hang', 900)">+ Double Hang (900W)</button>
            <button class="btn-wardrobe" onclick="callRuby('add_wardrobe', 'linen_tower', 600)">+ Linen Tower (600W)</button>
            <button class="btn-wardrobe" onclick="callRuby('add_wardrobe', 'drawers_combo', 900)">+ Drawers Combo (900W)</button>
            <button class="btn-wardrobe" onclick="callRuby('add_wardrobe', 'trouser_rack', 900)">+ Trouser Pullout (900W)</button>
          </div>
        </div>

        <div class="category">
          <h2>2. Kitchen Base Gola Cabinets (560D x 720H)</h2>
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
          <h2>3. Kitchen Corner Units</h2>
          <div class="btn-grid">
            <button class="btn-corner" onclick="callRuby('add_base_blind', 1100)">+ Blind LeMans (1100W)</button>
            <button class="btn-corner" onclick="callRuby('add_base_l_corner', 900)">+ L-Corner 90° (900x900)</button>
          </div>
        </div>

        <div class="category">
          <h2>4. Kitchen Tall Towers (600D x 2160H)</h2>
          <div class="btn-grid">
            <button class="btn-tall" onclick="callRuby('add_tall_oven', 600)">+ Oven Tower (600W)</button>
            <button class="btn-tall" onclick="callRuby('add_tall_pantry', 600)">+ Pantry Larder (600W)</button>
          </div>
        </div>

        <div class="category">
          <h2>5. Wall Cabinets (350D x 720H)</h2>
          <div class="btn-grid">
            <button class="btn-wall" onclick="callRuby('add_wall_glass', 300, {is_left_hinged: true})">+ Glass Sash (300W)</button>
            <button class="btn-wall" onclick="callRuby('add_wall_glass', 600, {is_left_hinged: true})">+ Glass Sash (600W LH)</button>
            <button class="btn-wall" onclick="callRuby('add_wall_glass', 600, {is_left_hinged: false})">+ Glass Sash (600W RH)</button>
            <button class="btn-wall" onclick="callRuby('add_wall_hood', 900)">+ Cooker Hood (900W)</button>
          </div>
        </div>

        <div class="category">
          <h2>6. Island Cabinets (560D x 720H)</h2>
          <div class="btn-grid">
            <button class="btn-island" onclick="callRuby('add_island_drawers', 600)">+ Island Drawers (600W)</button>
            <button class="btn-island" onclick="callRuby('add_island_sink', 600)">+ Island Sink (600W)</button>
            <button class="btn-island full-btn" onclick="callRuby('add_island_drawers', 800)">+ Island Multi-Drawers (800W)</button>
          </div>
        </div>

        <div class="category">
          <h2>7. Finishing & Assembly</h2>
          <div class="btn-grid">
            <button class="btn-action full-btn" onclick="callRuby('add_finishes')">✨ Add Worktops, Waterfalls & Pelmets</button>
            <button class="btn-reset full-btn" onclick="callRuby('reset')">🗑️ Clear / Reset Studio</button>
          </div>
        </div>

        <script>
          function callRuby(action, param1, param2) {
            sketchup.handleAction({ action: action, val1: param1, val2: param2 });
          }

          function updateStats(data) {
            document.getElementById('st_count').innerText = data.count;
            document.getElementById('st_main').innerText = data.main_w + ' mm';
            document.getElementById('st_wardrobe').innerText = data.wardrobe_w + ' mm';
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
      when 'add_wardrobe'
        add_wardrobe_box(v1.to_sym, v2.to_i > 0 ? v2.to_i : 900)
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
      when 'add_base_blind'
        add_box(:base_blind_corner, v1)
      when 'add_base_l_corner'
        add_box(:base_l_corner_easy_reach, v1)
      when 'add_tall_oven'
        add_box(:tall_oven_tower, v1)
      when 'add_tall_pantry'
        add_box(:tall_pantry_larder, v1)
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
