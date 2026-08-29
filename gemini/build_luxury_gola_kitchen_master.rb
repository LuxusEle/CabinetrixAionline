# ==============================================================================
# CABINETRIX AI — SUPERIOR PRODUCTION LUXURY GOLA KITCHEN MASTER (GEMINI MODULE)
# Advanced Production Architecture (v3.0 Unified Base & Island Structural Engine):
#   • UNIFIED BASE & ISLAND CARCASE STRUCTURAL ENGINE (build_base_gola_box_structure):
#     - Applied identically to both Main Base Run (Box_03 to 06) and Island Run (Box_11 to 13).
#     - Independent Gable_LH & Gable_RH (no shared gables).
#     - Structural Bottom Panel (18mm) with Minifix 15 + Dowels.
#     - Top Front Gola Sub-Stretcher (80mm Horizontal) with Minifix 15.
#     - Mid C-Gola Tie-Stretcher (60mm Horizontal) with Minifix 15.
#     - Top & Bottom 100mm Vertical Rear Cleats.
#     - Captured 6mm Grooved Back Sheet in 5mm rebates.
#     - Modular L-Gola & C-Gola Aluminum Profiles.
#   • STRICT 100% MODULAR GABLE RULEBOOK:
#     - Box_01 through Box_13 all have discrete, complete Gable_LH and Gable_RH.
#   • WALL CABINET CARCASE ROOF & STRETCHER SEATING:
#     - Top Panel (Roof) spans full depth to back wall (Y: -350mm to 0).
#     - Top Rear 100mm Vertical Cleat sits directly UNDER the top panel.
#     - Solid box bottoms between gables.
#   • SEPARATE CONTINUOUS UNDER-CABINET COVER PANEL (LIGHT SHIELD / BOTTOM PELMET):
#     - Continuous 18mm panel mounted underneath the wall run at Z: wall_z0 - 18mm.
#     - 25mm front finger-pull groove for Hettich handleless access.
#     - 15mm continuous extruded aluminum LED channel with frosted diffuser.
#   • 100% ATOMIC GROUPING: All gables, stretchers, panels & hardware isolated in groups.
# ==============================================================================
require 'sketchup.rb'
require 'json'

module CabinetrixLuxuryKitchen
  # ----------------------------------------------------------------------------
  # 1. PARAMETERS & METRIC STANDARDS (System 32 Metric Standard)
  # ----------------------------------------------------------------------------
  BOARD_THK         = 18.0.mm   # 18mm carcase & stretcher thickness
  FRONT_THK         = 18.0.mm   # 18mm drawer & door fronts
  DRAWER_BOX_THK    = 15.0.mm   # 15mm birch / MFC drawer box sides
  BACK_THK          = 6.0.mm    # 6mm solid back panel
  BACK_GROOVE       = 5.0.mm    # 5mm rebate depth
  WORKTOP_THK       = 20.0.mm   # 20mm Calacatta Marble worktop
  
  PLINTH_HEIGHT     = 100.0.mm  # 100mm recessed toe-kick
  PLINTH_SETBACK    = 50.0.mm   # 50mm plinth setback
  BASE_CARCASE_H    = 720.0.mm  # Base carcase height (Total base = 100 + 720 = 820mm)
  BASE_DEPTH        = 560.0.mm  # Base carcase depth
  WORKTOP_DEPTH     = 600.0.mm  # Base countertop depth
  
  WALL_CARCASE_H    = 720.0.mm  # Wall carcase height
  WALL_DEPTH        = 350.0.mm  # Wall carcase depth
  WALL_MOUNT_Z      = 1440.0.mm # Bottom of wall units
  
  TALL_CARCASE_H    = 2160.0.mm # Tall unit total height
  TALL_DEPTH        = 600.0.mm  # Tall unit depth
  BASE_DATUM_Z      = (PLINTH_HEIGHT + BASE_CARCASE_H) # 820mm structural alignment datum

  # Gola Dimensions & Machined Notches (SCILM Standard)
  GOLA_DEPTH        = 26.0.mm   # Cutout depth into side gables
  L_GOLA_H          = 59.0.mm   # Top L-Gola cutout height (Z: 661 to 720mm)
  C_GOLA_H          = 73.5.mm   # Mid C-Gola cutout height (Z: 330 to 403.5mm)
  C_GOLA_Z0         = 330.0.mm  # Bottom of C-notch

  # Minifix 15 & Dowel Standards
  MINIFIX_CAM_D     = 15.0.mm
  MINIFIX_CAM_DEPTH = 12.5.mm
  MINIFIX_B_DIST    = 34.0.mm
  DOWEL_D           = 8.0.mm
  DOWEL_LEN         = 30.0.mm

  # Drawer Front Heights with Exact Gola Overlaps
  UPPER_FRONT_H     = 310.0.mm
  LOWER_FRONT_H     = 355.0.mm

  # ----------------------------------------------------------------------------
  # 2. MATERIAL DEFINITIONS
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
  # 3. ATOMIC GEOMETRIC BUILDERS
  # ----------------------------------------------------------------------------
  def self.create_box(entities, origin, size, material = nil, name = nil)
    group = entities.add_group
    group.name = name if name
    x, y, z = size
    ox, oy, oz = origin

    pts = [
      Geom::Point3d.new(ox, oy, oz),
      Geom::Point3d.new(ox + x, oy, oz),
      Geom::Point3d.new(ox + x, oy + y, oz),
      Geom::Point3d.new(ox, oy + y, oz)
    ]
    face = group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.z < 0
      face.pushpull(z)
    end
    group.material = material if material
    group
  end

  def self.create_machined_gola_gable(entities, origin_x, base_depth, z_origin, height, material, name = "Gable_Machined_Gola", facing_dir: :front)
    group = entities.add_group
    group.name = name

    pts = if facing_dir == :front
            [
              Geom::Point3d.new(origin_x, 0, z_origin),
              Geom::Point3d.new(origin_x, -base_depth, z_origin),
              Geom::Point3d.new(origin_x, -base_depth, z_origin + C_GOLA_Z0),
              Geom::Point3d.new(origin_x, -base_depth + GOLA_DEPTH, z_origin + C_GOLA_Z0),
              Geom::Point3d.new(origin_x, -base_depth + GOLA_DEPTH, z_origin + C_GOLA_Z0 + C_GOLA_H),
              Geom::Point3d.new(origin_x, -base_depth, z_origin + C_GOLA_Z0 + C_GOLA_H),
              Geom::Point3d.new(origin_x, -base_depth, z_origin + height - L_GOLA_H),
              Geom::Point3d.new(origin_x, -base_depth + GOLA_DEPTH, z_origin + height - L_GOLA_H),
              Geom::Point3d.new(origin_x, -base_depth + GOLA_DEPTH, z_origin + height),
              Geom::Point3d.new(origin_x, 0, z_origin + height)
            ]
          else
            prep_y = base_depth[0]
            rear_y = base_depth[1]
            [
              Geom::Point3d.new(origin_x, rear_y, z_origin),
              Geom::Point3d.new(origin_x, prep_y, z_origin),
              Geom::Point3d.new(origin_x, prep_y, z_origin + C_GOLA_Z0),
              Geom::Point3d.new(origin_x, prep_y - GOLA_DEPTH, z_origin + C_GOLA_Z0),
              Geom::Point3d.new(origin_x, prep_y - GOLA_DEPTH, z_origin + C_GOLA_Z0 + C_GOLA_H),
              Geom::Point3d.new(origin_x, prep_y, z_origin + C_GOLA_Z0 + C_GOLA_H),
              Geom::Point3d.new(origin_x, prep_y, z_origin + height - L_GOLA_H),
              Geom::Point3d.new(origin_x, prep_y - GOLA_DEPTH, z_origin + height - L_GOLA_H),
              Geom::Point3d.new(origin_x, prep_y - GOLA_DEPTH, z_origin + height),
              Geom::Point3d.new(origin_x, rear_y, z_origin + height)
            ]
          end

    face = group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.x < 0
      face.pushpull(BOARD_THK)
    end
    group.material = material if material
    group
  end

  def self.create_cylinder(entities, center, normal, radius, height, material = nil, num_segments = 16)
    return nil if radius <= 0 || height <= 0
    group = entities.add_group
    circle = group.entities.add_circle(center, normal, radius, num_segments)
    face = group.entities.add_face(circle)
    if face
      face.reverse! if face.normal.dot(normal) < 0
      face.pushpull(height)
    end
    group.material = material if material
    group
  end

  # ----------------------------------------------------------------------------
  # 4. SHOTGUN V2 GROOVED BACK SHEET & REAR WALL CLEATS ENGINE
  # ----------------------------------------------------------------------------
  def self.build_shotgun_grooved_back(parent_ents, name_prefix, origin_x, width, base_z, top_z, mats, has_mid_cleat: false, mid_cleat_z: nil)
    group = parent_ents.add_group
    group.name = "#{name_prefix}_Back_System"

    groove = BACK_GROOVE
    back_t = BACK_THK
    thk    = BOARD_THK
    cleat_h = 100.0.mm

    inner_w = width - (2 * thk)
    stretcher_w = inner_w
    sheet_w = inner_w + (2 * groove)
    sheet_h = top_z - base_z - (2 * thk) + (2 * groove)

    # 1. 6mm Grooved Back Sheet
    sheet_ox = origin_x + thk - groove
    sheet_oy = -thk - back_t
    sheet_oz = base_z + thk - groove
    create_box(group.entities, [sheet_ox, sheet_oy, sheet_oz], [sheet_w, back_t, sheet_h], mats[:carcase], "#{name_prefix}_Grooved_Back_Sheet")

    # 2. Top Vertical Wall-Mount Cleat
    create_box(group.entities, [origin_x + thk, -thk, top_z - thk - cleat_h], [stretcher_w, thk, cleat_h], mats[:carcase], "#{name_prefix}_Rear_Top_Vertical_Cleat")

    # 3. Bottom Vertical Wall-Mount Cleat
    create_box(group.entities, [origin_x + thk, -thk, base_z + thk], [stretcher_w, thk, cleat_h], mats[:carcase], "#{name_prefix}_Rear_Bottom_Vertical_Cleat")

    # 4. Optional Mid Structural Cleat (for Tall Units)
    if has_mid_cleat && mid_cleat_z
      create_box(group.entities, [origin_x + thk, -thk, mid_cleat_z - cleat_h], [stretcher_w, thk, cleat_h], mats[:carcase], "#{name_prefix}_Rear_Mid_Vertical_Cleat")
    end

    group
  end

  # ----------------------------------------------------------------------------
  # 5. PARAMETRIC SHELF LOGIC (18mm THICKNESS, INNER WIDTH - 1mm)
  # ----------------------------------------------------------------------------
  def self.build_structural_shelf(parent_ents, name, origin_x, width, depth, z_pos, mats, cam_normal: Geom::Vector3d.new(0, 0, 1), full_depth_to_wall: false, y_origin: 0)
    group = parent_ents.add_group
    group.name = name
    inner_w = width - (2 * BOARD_THK)
    shelf_d = full_depth_to_wall ? depth : (depth - BOARD_THK)
    y_start = y_origin - depth

    create_box(group.entities, [origin_x + BOARD_THK, y_start, z_pos], [inner_w, shelf_d, BOARD_THK], mats[:carcase], "Shelf_Panel")

    build_minifix_joint(group.entities, Geom::Point3d.new(origin_x + BOARD_THK, y_origin - 70.mm, z_pos + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, cam_normal: cam_normal, bounds_y: [y_start, y_start + shelf_d])
    build_minifix_joint(group.entities, Geom::Point3d.new(origin_x + BOARD_THK, y_start + 70.mm, z_pos + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, cam_normal: cam_normal, bounds_y: [y_start, y_start + shelf_d])
    build_minifix_joint(group.entities, Geom::Point3d.new(origin_x + width - BOARD_THK, y_origin - 70.mm, z_pos + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, cam_normal: cam_normal, bounds_y: [y_start, y_start + shelf_d])
    build_minifix_joint(group.entities, Geom::Point3d.new(origin_x + width - BOARD_THK, y_start + 70.mm, z_pos + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, cam_normal: cam_normal, bounds_y: [y_start, y_start + shelf_d])

    group
  end

  def self.build_adjustable_shelf(parent_ents, name, origin_x, width, depth, z_pos, mats, is_glass: false)
    group = parent_ents.add_group
    group.name = name

    inner_w = width - (2 * BOARD_THK)
    shelf_w = inner_w - 1.0.mm
    shelf_d = depth - 20.0.mm - (BOARD_THK + BACK_THK)
    sh_x    = origin_x + BOARD_THK + 0.5.mm
    sh_y    = -depth + 20.0.mm

    shelf_thk = is_glass ? 8.0.mm : BOARD_THK
    mat = is_glass ? mats[:glass] : mats[:carcase]
    create_box(group.entities, [sh_x, sh_y, z_pos], [shelf_w, shelf_d, shelf_thk], mat, is_glass ? "Glass_Shelf_Slab" : "Wood_Shelf_Slab")

    pin_y1 = sh_y + 37.mm
    pin_y2 = sh_y + shelf_d - 37.mm
    [pin_y1, pin_y2].each do |py|
      create_cylinder(group.entities, Geom::Point3d.new(origin_x + BOARD_THK, py, z_pos - 1.mm), Geom::Vector3d.new(1, 0, 0), 2.5.mm, 6.0.mm, mats[:steel], 12)
      create_cylinder(group.entities, Geom::Point3d.new(origin_x + width - BOARD_THK, py, z_pos - 1.mm), Geom::Vector3d.new(-1, 0, 0), 2.5.mm, 6.0.mm, mats[:steel], 12)
    end

    group
  end

  # ----------------------------------------------------------------------------
  # 6. UNIFIED BASE & ISLAND CARCASE STRUCTURAL BUILDER
  # ----------------------------------------------------------------------------
  def self.build_base_gola_box_structure(box_grp, box_id, bx, bw, main_oz, mats, facing_dir: :front, front_y: -560.mm, rear_y: 0.mm)
    inner_w = bw - (2 * BOARD_THK)
    depth = (front_y - rear_y).abs
    stretcher_z = main_oz + BASE_CARCASE_H - BOARD_THK
    mid_stretcher_z = main_oz + C_GOLA_Z0 + C_GOLA_H - BOARD_THK

    # 1. Independent Discrete Gables (LH & RH)
    if facing_dir == :front
      create_machined_gola_gable(box_grp.entities, bx, depth, main_oz, BASE_CARCASE_H, mats[:carcase], "Gable_LH", facing_dir: :front)
      create_machined_gola_gable(box_grp.entities, bx + bw - BOARD_THK, depth, main_oz, BASE_CARCASE_H, mats[:carcase], "Gable_RH", facing_dir: :front)
    else
      create_machined_gola_gable(box_grp.entities, bx, [front_y, rear_y], main_oz, BASE_CARCASE_H, mats[:carcase], "Gable_LH", facing_dir: :aisle)
      create_machined_gola_gable(box_grp.entities, bx + bw - BOARD_THK, [front_y, rear_y], main_oz, BASE_CARCASE_H, mats[:carcase], "Gable_RH", facing_dir: :aisle)
    end

    # 2. Structural Bottom Panel with Minifix 15 + Dowels
    if facing_dir == :front
      build_structural_shelf(box_grp.entities, "Bottom_Panel", bx, bw, depth, main_oz, mats)
      build_shotgun_grooved_back(box_grp.entities, box_id, bx, bw, main_oz, main_oz + BASE_CARCASE_H, mats)
    else
      # Island bottom panel
      create_box(box_grp.entities, [bx + BOARD_THK, rear_y, main_oz], [inner_w, depth, BOARD_THK], mats[:carcase], "Bottom_Panel")
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, rear_y + 70.mm, main_oz + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, bounds_y: [rear_y, front_y])
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, front_y - 70.mm, main_oz + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, bounds_y: [rear_y, front_y])
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + bw - BOARD_THK, rear_y + 70.mm, main_oz + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, bounds_y: [rear_y, front_y])
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + bw - BOARD_THK, front_y - 70.mm, main_oz + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, bounds_y: [rear_y, front_y])

      # Island Top & Bottom Rear Vertical Cleats (100mm)
      create_box(box_grp.entities, [bx + BOARD_THK, rear_y, main_oz + BASE_CARCASE_H - 100.mm], [inner_w, BOARD_THK, 100.mm], mats[:carcase], "Top_Rear_Vertical_Cleat")
      create_box(box_grp.entities, [bx + BOARD_THK, rear_y, main_oz + BOARD_THK], [inner_w, BOARD_THK, 100.mm], mats[:carcase], "Bottom_Rear_Vertical_Cleat")
      create_box(box_grp.entities, [bx + BOARD_THK, rear_y + BOARD_THK, main_oz + BOARD_THK], [inner_w, BACK_THK, BASE_CARCASE_H - 2*BOARD_THK], mats[:carcase], "Back_Sheet")
    end

    # 3. Top Front Gola Sub-Stretcher (80mm Horizontal) & Mid C-Gola Stretcher (60mm Horizontal)
    if facing_dir == :front
      front_sub_y = -depth + GOLA_DEPTH
      create_box(box_grp.entities, [bx + BOARD_THK, front_sub_y, stretcher_z], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Front_Gola_Stretcher")
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, front_sub_y + 40.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [front_sub_y, front_sub_y + 80.mm])
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + bw - BOARD_THK, front_sub_y + 40.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [front_sub_y, front_sub_y + 80.mm])

      create_box(box_grp.entities, [bx + BOARD_THK, front_sub_y, mid_stretcher_z], [inner_w, 60.mm, BOARD_THK], mats[:carcase], "Mid_C_Gola_Stretcher")
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, front_sub_y + 30.mm, mid_stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [front_sub_y, front_sub_y + 60.mm])
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + bw - BOARD_THK, front_sub_y + 30.mm, mid_stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [front_sub_y, front_sub_y + 60.mm])

      # Modular Gola Extrusions
      build_gola_profile(box_grp.entities, :l, bw, Geom::Point3d.new(bx, -depth + GOLA_DEPTH, main_oz + BASE_CARCASE_H - L_GOLA_H), mats, facing_dir: :front)
      build_gola_profile(box_grp.entities, :c, bw, Geom::Point3d.new(bx, -depth + GOLA_DEPTH, main_oz + C_GOLA_Z0), mats, facing_dir: :front)
    else
      front_sub_y = front_y - GOLA_DEPTH - 80.mm
      create_box(box_grp.entities, [bx + BOARD_THK, front_sub_y, stretcher_z], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Front_Gola_Stretcher")
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, front_sub_y + 40.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [front_sub_y, front_sub_y + 80.mm])
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + bw - BOARD_THK, front_sub_y + 40.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [front_sub_y, front_sub_y + 80.mm])

      mid_sub_y = front_y - GOLA_DEPTH - 60.mm
      create_box(box_grp.entities, [bx + BOARD_THK, mid_sub_y, mid_stretcher_z], [inner_w, 60.mm, BOARD_THK], mats[:carcase], "Mid_C_Gola_Stretcher")
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, mid_sub_y + 30.mm, mid_stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [mid_sub_y, mid_sub_y + 60.mm])
      build_minifix_joint(box_grp.entities, Geom::Point3d.new(bx + bw - BOARD_THK, mid_sub_y + 30.mm, mid_stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [mid_sub_y, mid_sub_y + 60.mm])

      # Modular Gola Extrusions
      build_gola_profile(box_grp.entities, :l, bw, Geom::Point3d.new(bx, front_y - GOLA_DEPTH, main_oz + BASE_CARCASE_H - L_GOLA_H), mats, facing_dir: :aisle)
      build_gola_profile(box_grp.entities, :c, bw, Geom::Point3d.new(bx, front_y - GOLA_DEPTH, main_oz + C_GOLA_Z0), mats, facing_dir: :aisle)
    end
  end

  # ----------------------------------------------------------------------------
  # 7. SEPARATE CONTINUOUS UNDER-CABINET COVER PANEL (LIGHT SHIELD / BOTTOM PELMET)
  # ----------------------------------------------------------------------------
  def self.build_continuous_under_cabinet_pelmet(parent_ents, ox, total_width, depth, wall_bottom_z, mats)
    group = parent_ents.add_group
    group.name = "Continuous_Under_Cabinet_Bottom_Pelmet_#{total_width.to_mm.round}mm"

    pelmet_z = wall_bottom_z - BOARD_THK
    finger_pull_setback = 25.0.mm
    led_channel_w       = 15.0.mm
    led_channel_d       = 12.0.mm

    cover_y_front = -depth + finger_pull_setback
    cover_d       = depth - finger_pull_setback - led_channel_w
    create_box(group.entities, [ox, cover_y_front, pelmet_z], [total_width, cover_d, BOARD_THK], mats[:carcase], "Continuous_Pelmet_Cover_Board")

    led_y = -led_channel_w
    create_box(group.entities, [ox, led_y, pelmet_z], [total_width, led_channel_w, led_channel_d], mats[:gola], "Continuous_Alu_LED_Housing_Channel")
    create_box(group.entities, [ox + 1.mm, led_y + 1.5.mm, pelmet_z - 1.5.mm], [total_width - 2.mm, led_channel_w - 3.mm, 2.0.mm], mats[:diffuser], "Continuous_LED_Frosted_Diffuser")
    create_box(group.entities, [ox + 5.mm, led_y + 4.mm, pelmet_z + 2.mm], [total_width - 10.mm, 7.mm, 2.0.mm], mats[:led], "Continuous_LED_Emitter_Strip")

    group
  end

  # ----------------------------------------------------------------------------
  # 8. KD JOINERY MATRIX (MINIFIX 15 + FLUTED DOWELS)
  # ----------------------------------------------------------------------------
  def self.build_minifix_joint(parent_ents, bolt_center, dir_vector, mats, cam_normal: Geom::Vector3d.new(0, 0, 1), cam_offset_dist: 9.0.mm, bounds_y: nil)
    group = parent_ents.add_group
    group.name = "Minifix_15_Joint_Set"

    inv_vector = dir_vector.reverse

    create_cylinder(group.entities, bolt_center, inv_vector, 2.5.mm, 11.0.mm, mats[:steel], 12)
    create_cylinder(group.entities, bolt_center, dir_vector, 3.75.mm, 1.5.mm, mats[:steel], 12)
    pin_start = Geom::Point3d.new(
      bolt_center.x + dir_vector.x * 1.5.mm,
      bolt_center.y + dir_vector.y * 1.5.mm,
      bolt_center.z + dir_vector.z * 1.5.mm
    )
    create_cylinder(group.entities, pin_start, dir_vector, 3.25.mm, 32.5.mm, mats[:steel], 12)

    cam_x = bolt_center.x + dir_vector.x * MINIFIX_B_DIST
    cam_y = bolt_center.y + dir_vector.y * MINIFIX_B_DIST
    cam_z = bolt_center.z + dir_vector.z * MINIFIX_B_DIST

    cam_face_pt = Geom::Point3d.new(
      cam_x + cam_normal.x * cam_offset_dist,
      cam_y + cam_normal.y * cam_offset_dist,
      cam_z + cam_normal.z * cam_offset_dist
    )

    vis_pt = Geom::Point3d.new(
      cam_face_pt.x + cam_normal.x * 0.3.mm,
      cam_face_pt.y + cam_normal.y * 0.3.mm,
      cam_face_pt.z + cam_normal.z * 0.3.mm
    )

    c_rim = group.entities.add_circle(vis_pt, cam_normal, (MINIFIX_CAM_D / 2.0) + 0.3.mm, 18)
    f_rim = group.entities.add_face(c_rim)
    f_rim.material = mats[:hole] if f_rim

    create_cylinder(group.entities, vis_pt, cam_normal.reverse, MINIFIX_CAM_D / 2.0, MINIFIX_CAM_DEPTH, mats[:cam], 18)

    slot_w = 1.4.mm
    slot_l = 7.5.mm
    cz = vis_pt.z + (cam_normal.z * 0.2.mm)
    cx = vis_pt.x
    cy = vis_pt.y

    f_c1 = group.entities.add_face([
      Geom::Point3d.new(cx - slot_l/2, cy - slot_w/2, cz),
      Geom::Point3d.new(cx + slot_l/2, cy - slot_w/2, cz),
      Geom::Point3d.new(cx + slot_l/2, cy + slot_w/2, cz),
      Geom::Point3d.new(cx - slot_l/2, cy + slot_w/2, cz)
    ])
    f_c1.material = mats[:hole] if f_c1

    f_c2 = group.entities.add_face([
      Geom::Point3d.new(cx - slot_w/2, cy - slot_l/2, cz),
      Geom::Point3d.new(cx + slot_w/2, cy - slot_l/2, cz),
      Geom::Point3d.new(cx + slot_w/2, cy + slot_l/2, cz),
      Geom::Point3d.new(cx - slot_w/2, cy + slot_l/2, cz)
    ])
    f_c2.material = mats[:hole] if f_c2

    arr_dx = -dir_vector.x * 3.5.mm
    f_arr = group.entities.add_face([
      Geom::Point3d.new(cx + arr_dx, cy, cz),
      Geom::Point3d.new(cx - (dir_vector.x * 0.8.mm), cy - 2.2.mm, cz),
      Geom::Point3d.new(cx - (dir_vector.x * 0.8.mm), cy + 2.2.mm, cz)
    ])
    f_arr.material = mats[:accent] if f_arr

    if bounds_y
      min_y, max_y = [bounds_y[0], bounds_y[1]].min, [bounds_y[0], bounds_y[1]].max
      dowel_y = if (bolt_center.y + 32.0.mm) <= (max_y - 12.0.mm)
                  bolt_center.y + 32.0.mm
                elsif (bolt_center.y - 32.0.mm) >= (min_y + 12.0.mm)
                  bolt_center.y - 32.0.mm
                else
                  nil
                end

      if dowel_y
        dowel_start = Geom::Point3d.new(
          bolt_center.x - dir_vector.x * 10.0.mm,
          dowel_y,
          bolt_center.z
        )
        create_cylinder(group.entities, dowel_start, dir_vector, DOWEL_D / 2.0, DOWEL_LEN, mats[:dowel], 16)
      end
    end

    group
  end

  # ----------------------------------------------------------------------------
  # 9. GOLA ALUMINUM PROFILES
  # ----------------------------------------------------------------------------
  def self.build_gola_profile(parent_ents, profile_type, length, origin, mats, facing_dir: :front)
    group = parent_ents.add_group
    group.name = "Gola_Profile_#{profile_type.to_s.upcase}_#{length.to_mm.round}mm"

    ox, oy, oz = origin.x, origin.y, origin.z

    yz = if profile_type == :l
           [
             [0, 0], [1.5.mm, 0], [1.5.mm, 45.mm],
             [3.mm, 49.mm], [6.mm, 52.mm], [10.mm, 54.mm],
             [GOLA_DEPTH, 54.mm], [GOLA_DEPTH, 56.5.mm],
             [8.mm, 56.5.mm], [3.mm, 54.mm], [0, 48.mm]
           ]
         else
           [
             [GOLA_DEPTH, 0], [GOLA_DEPTH, 3.5.mm],
             [10.mm, 3.5.mm], [5.mm, 6.mm], [1.5.mm, 12.mm],
             [1.5.mm, 61.mm], [5.mm, 67.mm], [10.mm, 69.5.mm],
             [GOLA_DEPTH, 69.5.mm], [GOLA_DEPTH, 73.0.mm],
             [8.mm, 73.0.mm], [3.mm, 70.mm], [0, 64.mm],
             [0, 9.mm], [3.mm, 3.mm], [8.mm, 0]
           ]
         end

    if facing_dir == :front
      pts = yz.map { |y, z| Geom::Point3d.new(ox, oy - y, oz + z) }
    else
      pts = yz.map { |y, z| Geom::Point3d.new(ox, oy + y, oz + z) }
    end

    face = group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.x < 0
      face.pushpull(length)
    end

    group.material = mats[:gola]
    group
  end

  # ----------------------------------------------------------------------------
  # 10. AUTHENTIC HETTICH ACTRO 5D UNDERMOUNT DRAWER BOX
  # ----------------------------------------------------------------------------
  def self.build_hettich_undermount_drawer(parent_ents, box_origin, width, depth, box_height, front_h, front_z_offset, pull_offset, mats, front_mat, dir_y: -1)
    drawer_unit = parent_ents.add_group
    drawer_unit.name = "Hettich_Undermount_Drawer_#{width.to_mm.round}x#{front_h.to_mm.round}"

    ox = box_origin.x
    oy = box_origin.y + (dir_y * pull_offset)
    oz = box_origin.z

    front_oz = oz + front_z_offset
    if dir_y == -1
      create_box(drawer_unit.entities, [ox, oy - FRONT_THK, front_oz], [width, FRONT_THK, front_h], front_mat, "Drawer_Front_Face")
    else
      create_box(drawer_unit.entities, [ox, oy, front_oz], [width, FRONT_THK, front_h], front_mat, "Island_Drawer_Front_Face")
    end

    box_w = width - (2 * 12.5.mm)
    box_d = depth - 30.0.mm
    box_ox = ox + 12.5.mm
    box_oz = oz + 15.0.mm

    if dir_y == -1
      box_oy = oy
      create_box(drawer_unit.entities, [box_ox, box_oy, box_oz], [DRAWER_BOX_THK, box_d, box_height], mats[:wood], "Drawer_Side_LH")
      create_box(drawer_unit.entities, [box_ox + box_w - DRAWER_BOX_THK, box_oy, box_oz], [DRAWER_BOX_THK, box_d, box_height], mats[:wood], "Drawer_Side_RH")
      inner_w = box_w - (2 * DRAWER_BOX_THK)
      create_box(drawer_unit.entities, [box_ox + DRAWER_BOX_THK, box_oy, box_oz], [inner_w, DRAWER_BOX_THK, box_height], mats[:wood], "Drawer_Sub_Front")
      create_box(drawer_unit.entities, [box_ox + DRAWER_BOX_THK, box_oy + box_d - DRAWER_BOX_THK, box_oz], [inner_w, DRAWER_BOX_THK, box_height], mats[:wood], "Drawer_Back_Panel")
      create_box(drawer_unit.entities, [box_ox + DRAWER_BOX_THK, box_oy, box_oz + 12.mm], [inner_w, box_d - DRAWER_BOX_THK, 16.0.mm], mats[:wood], "Drawer_Bottom_Panel")

      runner_w = 11.0.mm
      runner_h = 24.0.mm
      create_box(drawer_unit.entities, [ox + 1.0.mm, oy, oz + 2.mm], [runner_w, box_d, runner_h], mats[:steel], "Hettich_Actro5D_Slide_LH")
      create_box(drawer_unit.entities, [ox + width - runner_w - 1.0.mm, oy, oz + 2.mm], [runner_w, box_d, runner_h], mats[:steel], "Hettich_Actro5D_Slide_RH")

      create_box(drawer_unit.entities, [ox + 12.mm, oy - 2.mm, oz + 2.mm], [20.mm, 35.mm, 12.mm], mats[:cam], "Hettich_Catch_LH")
      create_box(drawer_unit.entities, [ox + width - 32.mm, oy - 2.mm, oz + 2.mm], [20.mm, 35.mm, 12.mm], mats[:cam], "Hettich_Catch_RH")

      create_cylinder(drawer_unit.entities, Geom::Point3d.new(ox - 0.2.mm, oy + 37.mm, oz + 12.mm), Geom::Vector3d.new(-1, 0, 0), 2.5.mm, 4.0.mm, mats[:hole], 12)
      create_cylinder(drawer_unit.entities, Geom::Point3d.new(ox + width + 0.2.mm, oy + 37.mm, oz + 12.mm), Geom::Vector3d.new(1, 0, 0), 2.5.mm, 4.0.mm, mats[:hole], 12)
    else
      box_oy = oy - box_d
      create_box(drawer_unit.entities, [box_ox, box_oy, box_oz], [DRAWER_BOX_THK, box_d, box_height], mats[:wood], "Drawer_Side_LH")
      create_box(drawer_unit.entities, [box_ox + box_w - DRAWER_BOX_THK, box_oy, box_oz], [DRAWER_BOX_THK, box_d, box_height], mats[:wood], "Drawer_Side_RH")
      inner_w = box_w - (2 * DRAWER_BOX_THK)
      create_box(drawer_unit.entities, [box_ox + DRAWER_BOX_THK, oy - DRAWER_BOX_THK, box_oz], [inner_w, DRAWER_BOX_THK, box_height], mats[:wood], "Drawer_Sub_Front")
      create_box(drawer_unit.entities, [box_ox + DRAWER_BOX_THK, box_oy, box_oz], [inner_w, DRAWER_BOX_THK, box_height], mats[:wood], "Drawer_Back_Panel")
      create_box(drawer_unit.entities, [box_ox + DRAWER_BOX_THK, box_oy + DRAWER_BOX_THK, box_oz + 12.mm], [inner_w, box_d - DRAWER_BOX_THK, 16.0.mm], mats[:wood], "Drawer_Bottom_Panel")

      runner_w = 11.0.mm
      runner_h = 24.0.mm
      create_box(drawer_unit.entities, [ox + 1.0.mm, box_oy, oz + 2.mm], [runner_w, box_d, runner_h], mats[:steel], "Hettich_Actro5D_Slide_LH")
      create_box(drawer_unit.entities, [ox + width - runner_w - 1.0.mm, box_oy, oz + 2.mm], [runner_w, box_d, runner_h], mats[:steel], "Hettich_Actro5D_Slide_RH")

      create_box(drawer_unit.entities, [ox + 12.mm, oy - 33.mm, oz + 2.mm], [20.mm, 35.mm, 12.mm], mats[:cam], "Hettich_Catch_LH")
      create_box(drawer_unit.entities, [ox + width - 32.mm, oy - 33.mm, oz + 2.mm], [20.mm, 35.mm, 12.mm], mats[:cam], "Hettich_Catch_RH")
    end

    drawer_unit
  end

  # ----------------------------------------------------------------------------
  # 11. EXACT SENIOR DEV 45° MITER HOLLOW ALU SASH FRAME & ASSEMBLY
  # ----------------------------------------------------------------------------
  def self.create_senior_sash_bar(parent_ents, bar_length, alu_mat, hole_mat, is_hinged = false)
    group = parent_ents.add_group
    group.material = alu_mat

    outer = [
      [21.2, 0], [0, 0], [0, 10], [3.5, 10], [3.5, 8.5],
      [1.5, 8.5], [1.5, 1.5], [5.0, 1.5], [5.0, 45], [21.2, 45]
    ].reverse
    inner = [[6.5, 1.5], [19.7, 1.5], [19.7, 43.5], [6.5, 43.5]].reverse

    start_outer = outer.map { |y, z| Geom::Point3d.new(z.mm, y.mm, z.mm) }
    end_outer = outer.map { |y, z| Geom::Point3d.new(bar_length - z.mm, y.mm, z.mm) }
    start_inner = inner.map { |y, z| Geom::Point3d.new(z.mm, y.mm, z.mm) }
    end_inner = inner.map { |y, z| Geom::Point3d.new(bar_length - z.mm, y.mm, z.mm) }

    start_face = group.entities.add_face(start_outer)
    start_hole = group.entities.add_face(start_inner)
    start_hole.erase! if start_hole && start_hole.valid?
    end_face = group.entities.add_face(end_outer)
    end_hole = group.entities.add_face(end_inner)
    end_hole.erase! if end_hole && end_hole.valid?

    outer.length.times do |index|
      nxt = (index + 1) % outer.length
      group.entities.add_face(start_outer[index], start_outer[nxt], end_outer[nxt], end_outer[index])
    end
    inner.length.times do |index|
      nxt = (index + 1) % inner.length
      group.entities.add_face(start_inner[index], end_inner[index], end_inner[nxt], start_inner[nxt])
    end

    if is_hinged && bar_length > 200.mm
      [100.mm, bar_length - 100.mm].each_with_index do |hinge_x, index|
        marker = group.entities.add_group
        marker.material = hole_mat
        circle = marker.entities.add_circle(
          Geom::Point3d.new(hinge_x, 21.2.mm, 22.5.mm),
          Geom::Vector3d.new(0, 1, 0),
          17.5.mm,
          24
        )
        face = marker.entities.add_face(circle)
        face.pushpull(-13.mm) if face
      end
    end

    group
  end

  def self.build_senior_sash_door(parent_ents, ox, oy, oz, door_w, door_h, mats, is_left_hinged: true)
    group = parent_ents.add_group
    group.name = "Alu_Sash_Door_#{door_w.to_mm.round}x#{door_h.to_mm.round}"
    sub = group.entities
    transform = Geom::Transformation.translation([ox, oy, oz])

    bottom = create_senior_sash_bar(sub, door_w, mats[:gola], mats[:hole], false)
    bottom.transform!(transform)

    top = create_senior_sash_bar(sub, door_w, mats[:gola], mats[:hole], false)
    top.transform!(Geom::Transformation.scaling(1, 1, -1))
    top.transform!(Geom::Transformation.translation([0, 0, door_h]))
    top.transform!(transform)

    left = create_senior_sash_bar(sub, door_h, mats[:gola], mats[:hole], is_left_hinged)
    left.transform!(Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], -90.degrees))
    left.transform!(Geom::Transformation.scaling(-1, 1, 1))
    left.transform!(transform)

    right = create_senior_sash_bar(sub, door_h, mats[:gola], mats[:hole], !is_left_hinged)
    right.transform!(Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], -90.degrees))
    right.transform!(Geom::Transformation.translation([door_w, 0, 0]))
    right.transform!(transform)

    pane = sub.add_group
    pane.name = "Infill_Glass_Pane"
    pane_thickness = 3.0.mm
    pane_y0 = 1.75.mm
    pane_face = pane.entities.add_face(
      [10.mm, pane_y0, 10.mm],
      [door_w - 10.mm, pane_y0, 10.mm],
      [door_w - 10.mm, pane_y0 + pane_thickness, 10.mm],
      [10.mm, pane_y0 + pane_thickness, 10.mm]
    )
    pane_face.pushpull(door_h - 20.mm) if pane_face
    pane.material = mats[:glass]
    pane.transform!(transform)

    group
  end

  # ----------------------------------------------------------------------------
  # 12. MASTER KITCHEN GENERATION ROUTINE (INDIVIDUAL MODULAR BOXES)
  # ----------------------------------------------------------------------------
  def self.build_full_kitchen(parent_ents, mats, mode: :hybrid)
    kitchen_master = parent_ents.add_group
    kitchen_master.name = "Cabinetrix_Master_Luxury_Kitchen"

    main_oz = PLINTH_HEIGHT

    # ==========================================================================
    # ZONE 1: MAIN WALL RUN (X: 0 to 3600mm, Y: 0 to -560mm)
    # ==========================================================================

    # --------------------------------------------------------------------------
    # BOX 01: ADVANCED TALL DOUBLE OVEN TOWER (600W x 600D x 2160H)
    # --------------------------------------------------------------------------
    box01 = kitchen_master.entities.add_group
    box01.name = "Box_01_Tall_Oven_Tower_600W"
    b1_w = 600.mm

    create_box(box01.entities, [0, -TALL_DEPTH, 0], [BOARD_THK, TALL_DEPTH, TALL_CARCASE_H], mats[:carcase], "Gable_LH")
    create_box(box01.entities, [b1_w - BOARD_THK, -TALL_DEPTH, 0], [BOARD_THK, TALL_DEPTH, TALL_CARCASE_H], mats[:carcase], "Gable_RH")

    build_structural_shelf(box01.entities, "Bottom_Panel", 0, b1_w, TALL_DEPTH, main_oz, mats)
    build_structural_shelf(box01.entities, "Structural_Base_Datum_Shelf", 0, b1_w, TALL_DEPTH, BASE_DATUM_Z, mats)
    build_structural_shelf(box01.entities, "Upper_Appliance_Shelf", 0, b1_w, TALL_DEPTH, BASE_DATUM_Z + 885.mm, mats)
    build_structural_shelf(box01.entities, "Roof_Panel", 0, b1_w, TALL_DEPTH, TALL_CARCASE_H - BOARD_THK, mats, cam_normal: Geom::Vector3d.new(0, 0, -1), full_depth_to_wall: true)

    build_shotgun_grooved_back(box01.entities, "Box_01", 0, b1_w, main_oz, TALL_CARCASE_H, mats, has_mid_cleat: true, mid_cleat_z: BASE_DATUM_Z)

    b1_iw = b1_w - (2 * BOARD_THK)
    oven = create_box(box01.entities, [BOARD_THK + 5.mm, -TALL_DEPTH - 20.mm, BASE_DATUM_Z + BOARD_THK + 5.mm], [b1_iw - 10.mm, TALL_DEPTH - 20.mm, 875.mm], mats[:steel], "Double_Oven_Appliance")
    create_box(oven.entities, [BOARD_THK + 15.mm, -TALL_DEPTH - 25.mm, BASE_DATUM_Z + 25.mm], [b1_iw - 30.mm, 5.mm, 410.mm], mats[:glass], "Oven_Lower_Door_Glass")
    create_box(oven.entities, [BOARD_THK + 15.mm, -TALL_DEPTH - 25.mm, BASE_DATUM_Z + 465.mm], [b1_iw - 30.mm, 5.mm, 410.mm], mats[:glass], "Oven_Upper_Door_Glass")

    upper_door_h = TALL_CARCASE_H - (BASE_DATUM_Z + 885.mm + BOARD_THK) - 6.mm
    create_box(box01.entities, [1.5.mm, -TALL_DEPTH - FRONT_THK, BASE_DATUM_Z + 885.mm + BOARD_THK + 3.mm], [b1_w - 3.mm, FRONT_THK, upper_door_h], mats[:front_dark], "Upper_Cupboard_Door")

    build_hettich_undermount_drawer(box01.entities, Geom::Point3d.new(BOARD_THK + 1.5.mm, -TALL_DEPTH, main_oz + 12.mm), b1_iw - 3.mm, TALL_DEPTH, 200.mm, 355.mm, 0.mm, 0.mm, mats, mats[:front_dark], dir_y: -1)
    build_hettich_undermount_drawer(box01.entities, Geom::Point3d.new(BOARD_THK + 1.5.mm, -TALL_DEPTH, main_oz + 380.mm), b1_iw - 3.mm, TALL_DEPTH, 200.mm, 335.mm, 0.mm, (mode == :hybrid ? 250.mm : 0.mm), mats, mats[:front_dark], dir_y: -1)

    # --------------------------------------------------------------------------
    # BOX 02: ADVANCED TALL PANTRY / LARDER (600W x 600D x 2160H)
    # --------------------------------------------------------------------------
    box02 = kitchen_master.entities.add_group
    box02.name = "Box_02_Tall_Pantry_Larder_600W"
    b2_ox = 600.mm

    create_box(box02.entities, [b2_ox, -TALL_DEPTH, 0], [BOARD_THK, TALL_DEPTH, TALL_CARCASE_H], mats[:carcase], "Gable_LH")
    create_box(box02.entities, [b2_ox + b1_w - BOARD_THK, -TALL_DEPTH, 0], [BOARD_THK, TALL_DEPTH, TALL_CARCASE_H], mats[:carcase], "Gable_RH")

    build_structural_shelf(box02.entities, "Bottom_Panel", b2_ox, b1_w, TALL_DEPTH, main_oz, mats)
    build_structural_shelf(box02.entities, "Larder_Mid_Structural_Shelf", b2_ox, b1_w, TALL_DEPTH, 1200.mm, mats)
    build_structural_shelf(box02.entities, "Roof_Panel", b2_ox, b1_w, TALL_DEPTH, TALL_CARCASE_H - BOARD_THK, mats, cam_normal: Geom::Vector3d.new(0, 0, -1), full_depth_to_wall: true)

    build_shotgun_grooved_back(box02.entities, "Box_02", b2_ox, b1_w, main_oz, TALL_CARCASE_H, mats, has_mid_cleat: true, mid_cleat_z: 1200.mm)

    [main_oz + 20.mm, main_oz + 230.mm, main_oz + 440.mm, main_oz + 650.mm, main_oz + 860.mm].each_with_index do |dz, i|
      pull_dist = (mode == :hybrid && i == 1) ? 300.mm : 0.mm
      d_box = build_hettich_undermount_drawer(box02.entities, Geom::Point3d.new(b2_ox + BOARD_THK + 1.5.mm, -TALL_DEPTH + 20.mm, dz), b1_iw - 3.mm, TALL_DEPTH - 40.mm, 140.mm, 160.mm, 0.mm, pull_dist, mats, mats[:carcase], dir_y: -1)
      create_box(d_box.entities, [b2_ox + BOARD_THK + 35.mm, -TALL_DEPTH + 20.mm - (i==1 ? pull_dist : 0.mm) - 1.5.mm, dz + 20.mm], [b1_iw - 70.mm, 4.mm, 100.mm], mats[:glass], "Glass_Insert")
    end

    build_adjustable_shelf(box02.entities, "Adjustable_Shelf_1", b2_ox, b1_w, TALL_DEPTH, 1200.mm + BOARD_THK + 250.mm, mats)
    build_adjustable_shelf(box02.entities, "Adjustable_Shelf_2", b2_ox, b1_w, TALL_DEPTH, 1200.mm + BOARD_THK + 550.mm, mats)

    build_senior_sash_door(box02.entities, b2_ox + 1.5.mm, -TALL_DEPTH - 21.2.mm, main_oz, 597.mm, TALL_CARCASE_H - main_oz - 3.mm, mats, is_left_hinged: true)

    # --------------------------------------------------------------------------
    # BASE COOKING RUN WITH GOLA (X: 1200 to 3600mm, Total Width: 2400mm)
    # Built using unified build_base_gola_box_structure
    # --------------------------------------------------------------------------
    base_bays = [
      { id: "Box_03_Base_Spice_300W", x: 1200.mm, w: 300.mm, type: :spice },
      { id: "Box_04_Base_Cooktop_900W", x: 1500.mm, w: 900.mm, type: :cooktop },
      { id: "Box_05_Base_Utility_600W", x: 2400.mm, w: 600.mm, type: :drawers },
      { id: "Box_06_Base_Wine_600W", x: 3000.mm, w: 600.mm, type: :wine }
    ]

    base_bays.each do |bay|
      box_grp = kitchen_master.entities.add_group
      box_grp.name = bay[:id]
      bx = bay[:x]
      bw = bay[:w]
      build_base_gola_box_structure(box_grp, bay[:id], bx, bw, main_oz, mats, facing_dir: :front, front_y: -BASE_DEPTH, rear_y: 0.mm)

      front_w = bw - 3.mm

      case bay[:type]
      when :spice
        create_box(box_grp.entities, [bx + 1.5.mm, -BASE_DEPTH - FRONT_THK, main_oz + 3.mm], [front_w, FRONT_THK, BASE_CARCASE_H - 38.mm], mats[:front_dark], "Spice_Pullout_Front")
        create_box(box_grp.entities, [bx + 20.mm, -BASE_DEPTH + 20.mm, main_oz + 30.mm], [bw - 40.mm, BASE_DEPTH - 50.mm, 580.mm], mats[:steel], "Chrome_2Tier_Wire_Basket")
      when :cooktop
        build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + 1.5.mm, -BASE_DEPTH, main_oz + 12.mm), front_w, BASE_DEPTH, 200.mm, LOWER_FRONT_H, -9.mm, (mode == :hybrid ? 320.mm : 0.mm), mats, mats[:front_dark], dir_y: -1)
        build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + 1.5.mm, -BASE_DEPTH, main_oz + 390.mm), front_w, BASE_DEPTH, 140.mm, UPPER_FRONT_H, -15.mm, (mode == :hybrid ? 200.mm : 0.mm), mats, mats[:front_dark], dir_y: -1)
      when :drawers
        build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + 1.5.mm, -BASE_DEPTH, main_oz + 12.mm), front_w, BASE_DEPTH, 200.mm, LOWER_FRONT_H, -9.mm, 0.mm, mats, mats[:front_dark], dir_y: -1)
        build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + 1.5.mm, -BASE_DEPTH, main_oz + 390.mm), front_w, BASE_DEPTH, 140.mm, UPPER_FRONT_H, -15.mm, 0.mm, mats, mats[:front_dark], dir_y: -1)
      when :wine
        create_box(box_grp.entities, [bx + 1.5.mm, -BASE_DEPTH - FRONT_THK, main_oz + 3.mm], [front_w, FRONT_THK, LOWER_FRONT_H], mats[:front_dark], "Lower_Front")
        create_box(box_grp.entities, [bx + 1.5.mm, -BASE_DEPTH - FRONT_THK, main_oz + 375.mm], [front_w, FRONT_THK, UPPER_FRONT_H], mats[:front_dark], "Upper_Front")
      end
    end

    # Main Worktop (20mm Calacatta Marble)
    create_box(kitchen_master.entities, [1200.mm, -WORKTOP_DEPTH, main_oz + BASE_CARCASE_H], [2400.mm, WORKTOP_DEPTH, WORKTOP_THK], mats[:marble], "Main_Marble_Worktop")

    # Induction Hob (Centered at X: 1500->2400mm)
    create_box(kitchen_master.entities, [1550.mm, -520.mm, main_oz + BASE_CARCASE_H + WORKTOP_THK], [800.mm, 480.mm, 6.mm], mats[:gola], "Induction_Hob_Glass")
    [[1700.mm, -400.mm], [2100.mm, -400.mm], [1750.mm, -240.mm], [2050.mm, -240.mm]].each do |hx, hy|
      create_cylinder(kitchen_master.entities, Geom::Point3d.new(hx, hy, main_oz + BASE_CARCASE_H + WORKTOP_THK + 6.5.mm), Geom::Vector3d.new(0, 0, 1), 75.mm, 0.5.mm, mats[:accent], 20)
    end

    # --------------------------------------------------------------------------
    # UPPER WALL SECTION — DISCRETE MODULAR INDIVIDUAL BOXES (MAX 900W)
    # --------------------------------------------------------------------------
    wall_z0 = WALL_MOUNT_Z

    # Box 07: Left Glass Wall Unit (300W)
    box07 = kitchen_master.entities.add_group
    box07.name = "Box_07_Wall_Glass_Left_300W"
    create_box(box07.entities, [1200.mm, -WALL_DEPTH, wall_z0], [BOARD_THK, WALL_DEPTH, WALL_CARCASE_H], mats[:carcase], "Gable_LH")
    create_box(box07.entities, [1500.mm - BOARD_THK, -WALL_DEPTH, wall_z0], [BOARD_THK, WALL_DEPTH, WALL_CARCASE_H], mats[:carcase], "Gable_RH")
    build_structural_shelf(box07.entities, "Top_Panel", 1200.mm, 300.mm, WALL_DEPTH, wall_z0 + WALL_CARCASE_H - BOARD_THK, mats, cam_normal: Geom::Vector3d.new(0, 0, -1), full_depth_to_wall: true)
    build_structural_shelf(box07.entities, "Bottom_Panel", 1200.mm, 300.mm, WALL_DEPTH, wall_z0, mats)
    build_shotgun_grooved_back(box07.entities, "Box_07", 1200.mm, 300.mm, wall_z0, wall_z0 + WALL_CARCASE_H, mats)

    build_adjustable_shelf(box07.entities, "Glass_Shelf_1", 1200.mm, 300.mm, WALL_DEPTH, wall_z0 + 240.mm, mats, is_glass: true)
    build_adjustable_shelf(box07.entities, "Glass_Shelf_2", 1200.mm, 300.mm, WALL_DEPTH, wall_z0 + 480.mm, mats, is_glass: true)
    build_senior_sash_door(box07.entities, 1200.mm + 1.5.mm, -WALL_DEPTH - 21.2.mm, wall_z0, 297.mm, WALL_CARCASE_H, mats, is_left_hinged: true)

    # Box 08: Center Cooker Hood Unit (900W)
    box08 = kitchen_master.entities.add_group
    box08.name = "Box_08_Wall_Cooker_Hood_900W"
    create_box(box08.entities, [1500.mm, -WALL_DEPTH, wall_z0], [BOARD_THK, WALL_DEPTH, WALL_CARCASE_H], mats[:carcase], "Gable_LH")
    create_box(box08.entities, [2400.mm - BOARD_THK, -WALL_DEPTH, wall_z0], [BOARD_THK, WALL_DEPTH, WALL_CARCASE_H], mats[:carcase], "Gable_RH")
    build_structural_shelf(box08.entities, "Top_Panel", 1500.mm, 900.mm, WALL_DEPTH, wall_z0 + WALL_CARCASE_H - BOARD_THK, mats, cam_normal: Geom::Vector3d.new(0, 0, -1), full_depth_to_wall: true)
    build_structural_shelf(box08.entities, "Hood_Chamber_Shelf", 1500.mm, 900.mm, WALL_DEPTH, wall_z0 + 160.mm, mats)
    build_shotgun_grooved_back(box08.entities, "Box_08", 1500.mm, 900.mm, wall_z0 + 160.mm, wall_z0 + WALL_CARCASE_H, mats)

    create_box(box08.entities, [1510.mm, -WALL_DEPTH + 10.mm, wall_z0], [880.mm, WALL_DEPTH - 20.mm, 150.mm], mats[:steel], "Extractor_Hood_Body")
    create_box(box08.entities, [1530.mm, -WALL_DEPTH + 20.mm, wall_z0 - 2.mm], [840.mm, WALL_DEPTH - 40.mm, 4.mm], mats[:gola], "Grease_Baffle_Filters")
    create_box(box08.entities, [1550.mm, -WALL_DEPTH + 50.mm, wall_z0 - 4.mm], [800.mm, 20.mm, 4.mm], mats[:led], "Task_Downlights")

    hood_door_h = WALL_CARCASE_H - 160.mm - 3.mm
    create_box(box08.entities, [1500.mm + 1.5.mm, -WALL_DEPTH - FRONT_THK, wall_z0 + 160.mm + 3.mm], [897.mm, FRONT_THK, hood_door_h], mats[:front_dark], "Upper_Hood_Door")

    # Box 09: Discrete Mid Glass Wall Unit (600W at X: 2400->3000mm)
    box09 = kitchen_master.entities.add_group
    box09.name = "Box_09_Wall_Glass_Mid_600W"
    create_box(box09.entities, [2400.mm, -WALL_DEPTH, wall_z0], [BOARD_THK, WALL_DEPTH, WALL_CARCASE_H], mats[:carcase], "Gable_LH")
    create_box(box09.entities, [3000.mm - BOARD_THK, -WALL_DEPTH, wall_z0], [BOARD_THK, WALL_DEPTH, WALL_CARCASE_H], mats[:carcase], "Gable_RH")
    build_structural_shelf(box09.entities, "Top_Panel", 2400.mm, 600.mm, WALL_DEPTH, wall_z0 + WALL_CARCASE_H - BOARD_THK, mats, cam_normal: Geom::Vector3d.new(0, 0, -1), full_depth_to_wall: true)
    build_structural_shelf(box09.entities, "Bottom_Panel", 2400.mm, 600.mm, WALL_DEPTH, wall_z0, mats)
    build_shotgun_grooved_back(box09.entities, "Box_09", 2400.mm, 600.mm, wall_z0, wall_z0 + WALL_CARCASE_H, mats)

    build_adjustable_shelf(box09.entities, "Glass_Shelf_1", 2400.mm, 600.mm, WALL_DEPTH, wall_z0 + 240.mm, mats, is_glass: true)
    build_adjustable_shelf(box09.entities, "Glass_Shelf_2", 2400.mm, 600.mm, WALL_DEPTH, wall_z0 + 480.mm, mats, is_glass: true)
    build_senior_sash_door(box09.entities, 2400.mm + 1.5.mm, -WALL_DEPTH - 21.2.mm, wall_z0, 597.mm, WALL_CARCASE_H, mats, is_left_hinged: true)

    # Box 10: Discrete Right Glass Wall Unit (600W at X: 3000->3600mm)
    box10 = kitchen_master.entities.add_group
    box10.name = "Box_10_Wall_Glass_Right_600W"
    create_box(box10.entities, [3000.mm, -WALL_DEPTH, wall_z0], [BOARD_THK, WALL_DEPTH, WALL_CARCASE_H], mats[:carcase], "Gable_LH")
    create_box(box10.entities, [3600.mm - BOARD_THK, -WALL_DEPTH, wall_z0], [BOARD_THK, WALL_DEPTH, WALL_CARCASE_H], mats[:carcase], "Gable_RH")
    build_structural_shelf(box10.entities, "Top_Panel", 3000.mm, 600.mm, WALL_DEPTH, wall_z0 + WALL_CARCASE_H - BOARD_THK, mats, cam_normal: Geom::Vector3d.new(0, 0, -1), full_depth_to_wall: true)
    build_structural_shelf(box10.entities, "Bottom_Panel", 3000.mm, 600.mm, WALL_DEPTH, wall_z0, mats)
    build_shotgun_grooved_back(box10.entities, "Box_10", 3000.mm, 600.mm, wall_z0, wall_z0 + WALL_CARCASE_H, mats)

    build_adjustable_shelf(box10.entities, "Glass_Shelf_1", 3000.mm, 600.mm, WALL_DEPTH, wall_z0 + 240.mm, mats, is_glass: true)
    build_adjustable_shelf(box10.entities, "Glass_Shelf_2", 3000.mm, 600.mm, WALL_DEPTH, wall_z0 + 480.mm, mats, is_glass: true)
    build_senior_sash_door(box10.entities, 3000.mm + 1.5.mm, -WALL_DEPTH - 21.2.mm, wall_z0, 597.mm, WALL_CARCASE_H, mats, is_left_hinged: false)

    # --------------------------------------------------------------------------
    # SEPARATE CONTINUOUS UNDER-CABINET BOTTOM PELMET (LIGHT SHIELD + LED)
    # --------------------------------------------------------------------------
    build_continuous_under_cabinet_pelmet(kitchen_master.entities, 1200.mm, 300.mm, WALL_DEPTH, wall_z0, mats)
    build_continuous_under_cabinet_pelmet(kitchen_master.entities, 2400.mm, 1200.mm, WALL_DEPTH, wall_z0, mats)

    # ==========================================================================
    # ZONE 2: LUXURY KITCHEN ISLAND (Boxes 11, 12, 13 + Marble Waterfall)
    # Built using unified build_base_gola_box_structure
    # ==========================================================================
    isl_ox = 1000.0.mm
    isl_prep_y = -1400.0.mm
    isl_rear_y = -1960.0.mm
    isl_worktop_back_y = -2300.0.mm
    isl_w  = 2000.0.mm
    isl_d  = 900.0.mm
    isl_oz = PLINTH_HEIGHT

    # Box 11: Island Left 2-Drawer Bank (600W)
    box11 = kitchen_master.entities.add_group
    box11.name = "Box_11_Island_Drawer_Bank_600W"
    build_base_gola_box_structure(box11, "Box_11", isl_ox, 600.mm, isl_oz, mats, facing_dir: :aisle, front_y: isl_prep_y, rear_y: isl_rear_y)
    build_hettich_undermount_drawer(box11.entities, Geom::Point3d.new(isl_ox + 1.5.mm, isl_prep_y, isl_oz + 12.mm), 597.mm, BASE_DEPTH, 200.mm, LOWER_FRONT_H, -9.mm, (mode == :hybrid ? 280.mm : 0.mm), mats, mats[:front_cashmere], dir_y: +1)
    build_hettich_undermount_drawer(box11.entities, Geom::Point3d.new(isl_ox + 1.5.mm, isl_prep_y, isl_oz + 390.mm), 597.mm, BASE_DEPTH, 140.mm, UPPER_FRONT_H, -15.mm, (mode == :hybrid ? 180.mm : 0.mm), mats, mats[:front_cashmere], dir_y: +1)

    # Box 12: Island Center Sink Base with Waste Bin Pullout (600W)
    box12 = kitchen_master.entities.add_group
    box12.name = "Box_12_Island_Sink_Base_600W"
    build_base_gola_box_structure(box12, "Box_12", isl_ox + 600.mm, 600.mm, isl_oz, mats, facing_dir: :aisle, front_y: isl_prep_y, rear_y: isl_rear_y)
    create_box(box12.entities, [isl_ox + 600.mm + 1.5.mm, isl_prep_y, isl_oz + 375.mm], [597.mm, FRONT_THK, UPPER_FRONT_H], mats[:front_cashmere], "Sink_False_Front")
    build_hettich_undermount_drawer(box12.entities, Geom::Point3d.new(isl_ox + 600.mm + 1.5.mm, isl_prep_y, isl_oz + 12.mm), 597.mm, BASE_DEPTH, 200.mm, LOWER_FRONT_H, -9.mm, (mode == :hybrid ? 300.mm : 0.mm), mats, mats[:front_cashmere], dir_y: +1)
    create_box(box12.entities, [isl_ox + 630.mm, isl_prep_y - 250.mm, isl_oz + 30.mm], [240.mm, 200.mm, 280.mm], mats[:cam], "Cargo_Waste_Bin_1")
    create_box(box12.entities, [isl_ox + 900.mm, isl_prep_y - 250.mm, isl_oz + 30.mm], [240.mm, 200.mm, 280.mm], mats[:gola], "Cargo_Waste_Bin_2")

    # Box 13: Island Right Multi-Drawer Bank (800W)
    box13 = kitchen_master.entities.add_group
    box13.name = "Box_13_Island_Multi_Drawers_800W"
    build_base_gola_box_structure(box13, "Box_13", isl_ox + 1200.mm, 800.mm, isl_oz, mats, facing_dir: :aisle, front_y: isl_prep_y, rear_y: isl_rear_y)
    build_hettich_undermount_drawer(box13.entities, Geom::Point3d.new(isl_ox + 1200.mm + 1.5.mm, isl_prep_y, isl_oz + 12.mm), 797.mm, BASE_DEPTH, 200.mm, LOWER_FRONT_H, -9.mm, 0.mm, mats, mats[:front_cashmere], dir_y: +1)
    build_hettich_undermount_drawer(box13.entities, Geom::Point3d.new(isl_ox + 1200.mm + 1.5.mm, isl_prep_y, isl_oz + 390.mm), 797.mm, BASE_DEPTH, 140.mm, UPPER_FRONT_H, -15.mm, 0.mm, mats, mats[:front_cashmere], dir_y: +1)

    # Island Back Cladding Panel
    create_box(kitchen_master.entities, [isl_ox, isl_rear_y - FRONT_THK, isl_oz], [isl_w, FRONT_THK, BASE_CARCASE_H], mats[:front_cashmere], "Island_Back_Cladding")

    # Island Calacatta Gold Marble Worktop with Waterfall End Gables
    create_box(kitchen_master.entities, [isl_ox, isl_worktop_back_y, isl_oz + BASE_CARCASE_H], [isl_w, isl_d, WORKTOP_THK], mats[:marble], "Island_Worktop_Slab")
    create_box(kitchen_master.entities, [isl_ox - WORKTOP_THK, isl_worktop_back_y, 0], [WORKTOP_THK, isl_d, isl_oz + BASE_CARCASE_H + WORKTOP_THK], mats[:marble], "Waterfall_Gable_LH")
    create_box(kitchen_master.entities, [isl_ox + isl_w, isl_worktop_back_y, 0], [WORKTOP_THK, isl_d, isl_oz + BASE_CARCASE_H + WORKTOP_THK], mats[:marble], "Waterfall_Gable_RH")

    # Undermount Double Basin Sink
    create_box(kitchen_master.entities, [isl_ox + 650.mm, isl_prep_y - 480.mm, isl_oz + BASE_CARCASE_H - 180.mm], [500.mm, 400.mm, 180.mm], mats[:steel], "Undermount_Sink_Body")
    create_box(kitchen_master.entities, [isl_ox + 665.mm, isl_prep_y - 465.mm, isl_oz + BASE_CARCASE_H - 170.mm], [220.mm, 370.mm, 170.mm], mats[:hole], "Sink_Left_Basin")
    create_box(kitchen_master.entities, [isl_ox + 905.mm, isl_prep_y - 465.mm, isl_oz + BASE_CARCASE_H - 170.mm], [220.mm, 370.mm, 170.mm], mats[:hole], "Sink_Right_Basin")

    # Matte Black Gooseneck Faucet
    faucet_base = Geom::Point3d.new(isl_ox + 900.mm, isl_prep_y - 520.mm, isl_oz + BASE_CARCASE_H + WORKTOP_THK)
    create_cylinder(kitchen_master.entities, faucet_base, Geom::Vector3d.new(0, 0, 1), 22.mm, 350.mm, mats[:gola], 16)
    create_cylinder(kitchen_master.entities, Geom::Point3d.new(faucet_base.x, faucet_base.y, faucet_base.z + 350.mm), Geom::Vector3d.new(0, 1, 0), 12.mm, 180.mm, mats[:gola], 16)
    create_cylinder(kitchen_master.entities, Geom::Point3d.new(faucet_base.x, faucet_base.y + 180.mm, faucet_base.z + 350.mm), Geom::Vector3d.new(0, 0, -1), 10.mm, 90.mm, mats[:steel], 16)

    # 2x Modern Breakfast Bar Stools
    [isl_ox + 500.mm, isl_ox + 1500.mm].each_with_index do |sx, idx|
      create_cylinder(kitchen_master.entities, Geom::Point3d.new(sx, isl_worktop_back_y - 200.mm, 650.mm), Geom::Vector3d.new(0, 0, 1), 180.mm, 50.mm, mats[:front_dark], 24)
      create_cylinder(kitchen_master.entities, Geom::Point3d.new(sx, isl_worktop_back_y - 200.mm, 0), Geom::Vector3d.new(0, 0, 1), 200.mm, 15.mm, mats[:gola], 24)
      create_cylinder(kitchen_master.entities, Geom::Point3d.new(sx, isl_worktop_back_y - 200.mm, 15.mm), Geom::Vector3d.new(0, 0, 1), 25.mm, 635.mm, mats[:gola], 16)
    end

    # Plinth Base
    create_box(kitchen_master.entities, [1200.mm + 10.mm, -BASE_DEPTH + PLINTH_SETBACK, 0], [2380.mm, BOARD_THK, PLINTH_HEIGHT], mats[:plinth], "Plinth_Main_Run")
    create_box(kitchen_master.entities, [isl_ox + 10.mm, isl_prep_y - BASE_DEPTH + PLINTH_SETBACK, 0], [isl_w - 20.mm, BOARD_THK, PLINTH_HEIGHT], mats[:plinth], "Plinth_Island")

    kitchen_master
  end

  # ----------------------------------------------------------------------------
  # 13. CONTROLLER & RUNNER
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
      puts " ✅ [GEMINI] Master Luxury Gola Kitchen generated successfully!"
      puts "    • Unified Base Carcase Engine (build_base_gola_box_structure) called"
      puts "      identically on both Main Base run and Island Base boxes!"
      puts "    • All island boxes have discrete gables, 80mm Top Gola stretcher, 60mm Mid"
      puts "      C-stretcher, 100mm vertical rear cleats, 6mm back, and Minifix joints!"
      puts "    • 100% Atomic Grouping across all components!"
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
