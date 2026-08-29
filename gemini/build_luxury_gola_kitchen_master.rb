# ==============================================================================
# CABINETRIX AI — SUPERIOR PRODUCTION LUXURY GOLA KITCHEN MASTER (GEMINI MODULE)
# Driven by Pure Function API: CabinetrixBoxEngine.create_cabinet(...)
# ==============================================================================
require 'sketchup.rb'
require 'json'
require_relative 'cabinetrix_box_engine'

module CabinetrixLuxuryKitchen
  # ----------------------------------------------------------------------------
  # 1. MATERIAL DEFINITIONS
  # ----------------------------------------------------------------------------
  def self.get_materials(model)
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

  # ----------------------------------------------------------------------------
  # 2. CONTINUOUS UNDER-CABINET PELMET & UTILITIES
  # ----------------------------------------------------------------------------
  def self.build_continuous_pelmet(parent_ents, ox, total_w, depth, wall_bottom_z, mats)
    group = parent_ents.add_group
    group.name = "Continuous_Under_Cabinet_Pelmet_#{total_w.to_mm.round}mm"
    pelmet_z = wall_bottom_z - 18.mm
    finger_pull_setback = 25.0.mm
    led_channel_w       = 15.0.mm
    led_channel_d       = 12.0.mm

    cover_y_front = -depth + finger_pull_setback
    cover_d       = depth - finger_pull_setback - led_channel_w
    CabinetrixBoxEngine.create_box(group.entities, [ox, cover_y_front, pelmet_z], [total_w, cover_d, 18.mm], mats[:carcase], "Continuous_Pelmet_Board")

    led_y = -led_channel_w
    CabinetrixBoxEngine.create_box(group.entities, [ox, led_y, pelmet_z], [total_w, led_channel_w, led_channel_d], mats[:gola], "Alu_LED_Housing_Channel")
    CabinetrixBoxEngine.create_box(group.entities, [ox + 1.mm, led_y + 1.5.mm, pelmet_z - 1.5.mm], [total_w - 2.mm, led_channel_w - 3.mm, 2.0.mm], mats[:diffuser], "LED_Frosted_Diffuser")
    CabinetrixBoxEngine.create_box(group.entities, [ox + 5.mm, led_y + 4.mm, pelmet_z + 2.mm], [total_w - 10.mm, 7.mm, 2.0.mm], mats[:led], "LED_Emitter_Strip")
    group
  end

  # ----------------------------------------------------------------------------
  # 3. MASTER KITCHEN GENERATION ROUTINE
  # ----------------------------------------------------------------------------
  def self.build_full_kitchen(parent_ents, mats, mode: :hybrid)
    kitchen_master = parent_ents.add_group
    kitchen_master.name = "Cabinetrix_Master_Luxury_Kitchen"

    main_oz = 100.mm
    wall_z0 = 1440.mm

    # ==========================================================================
    # ZONE 1: MAIN WALL RUN (FUNCTION CALL -> BOX TYPE -> PARAMS -> LOCATION)
    # ==========================================================================

    # Box 01: Tall Double Oven Tower (600W x 600D x 2160H)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :tall_oven_tower,
      { name: "Box_01_Tall_Oven_Tower_600W", width: 600.mm, depth: 600.mm, height: 2160.mm, mode: mode, front_mat: mats[:front_dark] },
      { x: 0.mm, y: 0.mm, z: main_oz, facing_dir: :front },
      mats
    )

    # Box 02: Tall Pantry Larder (600W x 600D x 2160H)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :tall_pantry_larder,
      { name: "Box_02_Tall_Pantry_Larder_600W", width: 600.mm, depth: 600.mm, height: 2160.mm, mode: mode },
      { x: 600.mm, y: 0.mm, z: main_oz, facing_dir: :front },
      mats
    )

    # Box 03: Base Spice Pullout (300W x 560D x 720H)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :base_gola_spice,
      { name: "Box_03_Base_Spice_300W", width: 300.mm, depth: 560.mm, height: 720.mm, mode: mode, front_mat: mats[:front_dark] },
      { x: 1200.mm, y: 0.mm, z: main_oz, facing_dir: :front },
      mats
    )

    # Box 04: Base Cooktop (900W x 560D x 720H)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :base_gola_cooktop,
      { name: "Box_04_Base_Cooktop_900W", width: 900.mm, depth: 560.mm, height: 720.mm, mode: mode, front_mat: mats[:front_dark] },
      { x: 1500.mm, y: 0.mm, z: main_oz, facing_dir: :front },
      mats
    )

    # Box 05: Base Utility Drawers (600W x 560D x 720H)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :base_gola_drawers,
      { name: "Box_05_Base_Utility_600W", width: 600.mm, depth: 560.mm, height: 720.mm, mode: mode, front_mat: mats[:front_dark] },
      { x: 2400.mm, y: 0.mm, z: main_oz, facing_dir: :front },
      mats
    )

    # Box 06: Base Wine Unit (600W x 560D x 720H)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :base_gola_wine,
      { name: "Box_06_Base_Wine_600W", width: 600.mm, depth: 560.mm, height: 720.mm, mode: mode, front_mat: mats[:front_dark] },
      { x: 3000.mm, y: 0.mm, z: main_oz, facing_dir: :front },
      mats
    )

    # Main Worktop (20mm Calacatta Marble) & Induction Cooktop
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [1200.mm, -600.mm, main_oz + 720.mm], [2400.mm, 600.mm, 20.mm], mats[:marble], "Main_Marble_Worktop")
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [1550.mm, -520.mm, main_oz + 720.mm + 20.mm], [800.mm, 480.mm, 6.mm], mats[:gola], "Induction_Hob_Glass")
    [[1700.mm, -400.mm], [2100.mm, -400.mm], [1750.mm, -240.mm], [2050.mm, -240.mm]].each do |hx, hy|
      CabinetrixBoxEngine.create_cylinder(kitchen_master.entities, Geom::Point3d.new(hx, hy, main_oz + 720.mm + 20.mm + 6.5.mm), Geom::Vector3d.new(0, 0, 1), 75.mm, 0.5.mm, mats[:accent], 20)
    end

    # --------------------------------------------------------------------------
    # UPPER WALL SECTION (INDIVIDUAL DISCRETE BOXES)
    # --------------------------------------------------------------------------
    # Box 07: Wall Glass Left (300W x 350D x 720H)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :wall_glass_display,
      { name: "Box_07_Wall_Glass_Left_300W", width: 300.mm, depth: 350.mm, height: 720.mm, is_left_hinged: true },
      { x: 1200.mm, y: 0.mm, z: wall_z0, facing_dir: :front },
      mats
    )

    # Box 08: Wall Cooker Hood Unit (900W x 350D x 720H) — 100% aligned with Cooktop below
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :wall_cooker_hood,
      { name: "Box_08_Wall_Cooker_Hood_900W", width: 900.mm, depth: 350.mm, height: 720.mm, front_mat: mats[:front_dark] },
      { x: 1500.mm, y: 0.mm, z: wall_z0, facing_dir: :front },
      mats
    )

    # Box 09: Wall Glass Mid (600W x 350D x 720H)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :wall_glass_display,
      { name: "Box_09_Wall_Glass_Mid_600W", width: 600.mm, depth: 350.mm, height: 720.mm, is_left_hinged: true },
      { x: 2400.mm, y: 0.mm, z: wall_z0, facing_dir: :front },
      mats
    )

    # Box 10: Wall Glass Right (600W x 350D x 720H)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :wall_glass_display,
      { name: "Box_10_Wall_Glass_Right_600W", width: 600.mm, depth: 350.mm, height: 720.mm, is_left_hinged: false },
      { x: 3000.mm, y: 0.mm, z: wall_z0, facing_dir: :front },
      mats
    )

    # Continuous Under-Cabinet Light Pelmets
    build_continuous_pelmet(kitchen_master.entities, 1200.mm, 300.mm, 350.mm, wall_z0, mats)
    build_continuous_pelmet(kitchen_master.entities, 2400.mm, 1200.mm, 350.mm, wall_z0, mats)

    # ==========================================================================
    # ZONE 2: LUXURY KITCHEN ISLAND (FUNCTION CALL -> BOX TYPE -> PARAMS -> LOCATION)
    # ==========================================================================
    isl_ox = 1000.0.mm
    isl_prep_y = -1400.0.mm
    isl_rear_y = -1960.0.mm
    isl_worktop_back_y = -2300.0.mm
    isl_w  = 2000.0.mm
    isl_d  = 900.0.mm

    # Box 11: Island Left 2-Drawer Bank (600W)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :island_gola_drawers,
      { name: "Box_11_Island_Drawer_Bank_600W", width: 600.mm, depth: 560.mm, height: 720.mm, mode: mode, front_mat: mats[:front_cashmere] },
      { x: isl_ox, y: isl_prep_y, z: main_oz, facing_dir: :aisle },
      mats
    )

    # Box 12: Island Center Sink Base (600W)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :island_gola_sink,
      { name: "Box_12_Island_Sink_Base_600W", width: 600.mm, depth: 560.mm, height: 720.mm, mode: mode, front_mat: mats[:front_cashmere] },
      { x: isl_ox + 600.mm, y: isl_prep_y, z: main_oz, facing_dir: :aisle },
      mats
    )

    # Box 13: Island Right Multi-Drawer Bank (800W)
    CabinetrixBoxEngine.create_cabinet(
      kitchen_master.entities,
      :island_gola_drawers,
      { name: "Box_13_Island_Multi_Drawers_800W", width: 800.mm, depth: 560.mm, height: 720.mm, mode: mode, front_mat: mats[:front_cashmere] },
      { x: isl_ox + 1200.mm, y: isl_prep_y, z: main_oz, facing_dir: :aisle },
      mats
    )

    # Island Back Cladding Panel & Marble Waterfall Countertop
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [isl_ox, isl_rear_y - 18.mm, main_oz], [isl_w, 18.mm, 720.mm], mats[:front_cashmere], "Island_Back_Cladding")
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [isl_ox, isl_worktop_back_y, main_oz + 720.mm], [isl_w, isl_d, 20.mm], mats[:marble], "Island_Worktop_Slab")
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [isl_ox - 20.mm, isl_worktop_back_y, 0], [20.mm, isl_d, main_oz + 720.mm + 20.mm], mats[:marble], "Waterfall_Gable_LH")
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [isl_ox + isl_w, isl_worktop_back_y, 0], [20.mm, isl_d, main_oz + 720.mm + 20.mm], mats[:marble], "Waterfall_Gable_RH")

    # Undermount Double Basin Sink & Faucet
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [isl_ox + 650.mm, isl_prep_y - 480.mm, main_oz + 720.mm - 180.mm], [500.mm, 400.mm, 180.mm], mats[:steel], "Undermount_Sink_Body")
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [isl_ox + 665.mm, isl_prep_y - 465.mm, main_oz + 720.mm - 170.mm], [220.mm, 370.mm, 170.mm], mats[:hole], "Sink_Left_Basin")
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [isl_ox + 905.mm, isl_prep_y - 465.mm, main_oz + 720.mm - 170.mm], [220.mm, 370.mm, 170.mm], mats[:hole], "Sink_Right_Basin")

    faucet_base = Geom::Point3d.new(isl_ox + 900.mm, isl_prep_y - 520.mm, main_oz + 720.mm + 20.mm)
    CabinetrixBoxEngine.create_cylinder(kitchen_master.entities, faucet_base, Geom::Vector3d.new(0, 0, 1), 22.mm, 350.mm, mats[:gola], 16)
    CabinetrixBoxEngine.create_cylinder(kitchen_master.entities, Geom::Point3d.new(faucet_base.x, faucet_base.y, faucet_base.z + 350.mm), Geom::Vector3d.new(0, 1, 0), 12.mm, 180.mm, mats[:gola], 16)
    CabinetrixBoxEngine.create_cylinder(kitchen_master.entities, Geom::Point3d.new(faucet_base.x, faucet_base.y + 180.mm, faucet_base.z + 350.mm), Geom::Vector3d.new(0, 0, -1), 10.mm, 90.mm, mats[:steel], 16)

    # 2x Breakfast Bar Stools
    [isl_ox + 500.mm, isl_ox + 1500.mm].each do |sx|
      CabinetrixBoxEngine.create_cylinder(kitchen_master.entities, Geom::Point3d.new(sx, isl_worktop_back_y - 200.mm, 650.mm), Geom::Vector3d.new(0, 0, 1), 180.mm, 50.mm, mats[:front_dark], 24)
      CabinetrixBoxEngine.create_cylinder(kitchen_master.entities, Geom::Point3d.new(sx, isl_worktop_back_y - 200.mm, 0), Geom::Vector3d.new(0, 0, 1), 200.mm, 15.mm, mats[:gola], 24)
      CabinetrixBoxEngine.create_cylinder(kitchen_master.entities, Geom::Point3d.new(sx, isl_worktop_back_y - 200.mm, 15.mm), Geom::Vector3d.new(0, 0, 1), 25.mm, 635.mm, mats[:gola], 16)
    end

    # Plinths
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [1200.mm + 10.mm, -560.mm + 50.mm, 0], [2380.mm, 18.mm, 100.mm], mats[:plinth], "Plinth_Main_Run")
    CabinetrixBoxEngine.create_box(kitchen_master.entities, [isl_ox + 10.mm, isl_prep_y - 560.mm + 50.mm, 0], [isl_w - 20.mm, 18.mm, 100.mm], mats[:plinth], "Plinth_Island")

    kitchen_master
  end

  # ----------------------------------------------------------------------------
  # 4. CONTROLLER & RUNNER
  # ----------------------------------------------------------------------------
  def self.build(mode: :hybrid)
    model = Sketchup.active_model
    raise 'No active SketchUp model found.' unless model

    model.start_operation("Build Luxury Gola Kitchen (Gemini)", true)

    begin
      entities = model.active_entities
      entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Cabinetrix') || g.name.to_s.start_with?('CG_') || g.name.to_s.start_with?('Box_') || g.name.to_s.start_with?('Kitchen') || g.name.to_s.start_with?('Continuous_') }.each { |g| g.erase! }
      entities.grep(Sketchup::Text).each { |t| t.erase! }

      mats = get_materials(model)
      build_full_kitchen(entities, mats, mode: mode)

      model.active_view.zoom_extents if model.active_view
      model.commit_operation

      puts "=========================================================================="
      puts " ✅ [GEMINI] Master Luxury Gola Kitchen generated via CabinetrixBoxEngine!"
      puts "    • Standardized API: CabinetrixBoxEngine.create_cabinet(parent, type, params, location, mats)"
      puts "    • Wall unit doors extend +18mm over bottom panel for handleless finger grip!"
      puts "    • 100% discrete gables & atomic grouping across all components!"
      puts "=========================================================================="
    rescue => e
      model.abort_operation
      puts "Error in Gemini Kitchen builder: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end

# Auto-execute on load
if defined?(Sketchup) && Sketchup.active_model
  CabinetrixLuxuryKitchen.build(mode: :hybrid)
end
