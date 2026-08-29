# ==============================================================================
# CABINETRIX - 2x DRAWER BANK BASE UNIT WITH GOLA & MINIFIX JOINERY
# 
# Features:
#   • 2x 600mm Modular Drawer Banks (Total Width: 1200mm)
#   • Integrated Gola Handleless Profile System (Top L-Gola + Mid C-Gola)
#   • 16x Minifix 15mm Eccentric Cams + Connecting Bolts (Bottom + Top Rails)
#   • Fluted Beech Alignment Dowels (Ø8 x 30mm)
#   • CNC Gola Side Pockets (59mm L-cutout, 73.5mm C-cutout, 26mm deep)
#   • Realistic 3D Drawer Boxes with Soft-Close Concealed Runners
#   • Multiple Viewing Modes:
#       1. Hybrid View (Left Bank Open, Right Bank Closed) -> Shows both joinery & exterior!
#       2. Carcase Joinery Inspection (Drawers Hidden) -> 100% Minifix visibility!
#       3. Exploded Assembly View -> Shows all bolts, dowels & bore holes in space!
# ==============================================================================
require 'sketchup.rb'

module CabinetrixGolaDrawerBank
  # ----------------------------------------------------------------------------
  # 1. CORE DIMENSIONS & SPECIFICATIONS
  # ----------------------------------------------------------------------------
  BOARD_THK         = 18.0.mm   # 18mm carcase board thickness
  DRAWER_FRONT_THK  = 18.0.mm   # 18mm drawer front thickness
  BACK_THK          = 6.0.mm    # 6mm back panel
  
  BANK_COUNT        = 2         # 2 drawer banks
  BANK_WIDTH        = 600.0.mm  # Width per bank
  TOTAL_WIDTH       = (BANK_COUNT * BANK_WIDTH) # 1200mm total width
  TOTAL_HEIGHT      = 820.0.mm  # Carcase (720mm) + Plinth (100mm)
  CARCASE_HEIGHT    = 720.0.mm  # Standard European carcase height
  CARCASE_DEPTH     = 560.0.mm  # Standard base carcase depth
  PLINTH_HEIGHT     = 100.0.mm  # 100mm toe kick
  PLINTH_SETBACK    = 50.0.mm   # 50mm front setback for toe kick

  # Gola Profile Parameters (SCILM / Häfele Standard)
  GOLA_DEPTH        = 26.0.mm   # Side panel notch depth
  L_GOLA_HEIGHT     = 59.0.mm   # Undertop L-Gola notch height
  C_GOLA_HEIGHT     = 73.5.mm   # Mid-drawer C-Gola notch height
  GOLA_WALL         = 1.5.mm    # Aluminum profile wall thickness
  GOLA_PROFILE_D    = 27.2.mm   # Aluminum extrusion depth
  L_PROFILE_H       = 56.5.mm   # L-profile total height
  C_PROFILE_H       = 73.0.mm   # C-profile total height

  # Minifix 15 Joinery Standards
  MINIFIX_CAM_D     = 15.0.mm
  MINIFIX_CAM_DEPTH = 12.5.mm
  MINIFIX_B_DIST    = 34.0.mm   # 34mm drilling distance
  DOWEL_D           = 8.0.mm
  DOWEL_LEN         = 30.0.mm

  # ----------------------------------------------------------------------------
  # 2. MATERIAL DEFINITIONS
  # ----------------------------------------------------------------------------
  def self.get_materials(model)
    mats = model.materials

    carcase_mat = mats['CBX_Carcase_White'] || mats.add('CBX_Carcase_White')
    carcase_mat.color = Sketchup::Color.new(242, 240, 235)

    front_mat = mats['CBX_Front_Anthracite'] || mats.add('CBX_Front_Anthracite')
    front_mat.color = Sketchup::Color.new(50, 53, 58)

    gola_mat = mats['CBX_Gola_Black_Anodized'] || mats.add('CBX_Gola_Black_Anodized')
    gola_mat.color = Sketchup::Color.new(30, 32, 35)

    drawer_box_mat = mats['CBX_Drawer_Birch'] || mats.add('CBX_Drawer_Birch')
    drawer_box_mat.color = Sketchup::Color.new(228, 215, 192)

    cam_mat = mats['CBX_Minifix_Zinc'] || mats.add('CBX_Minifix_Zinc')
    cam_mat.color = Sketchup::Color.new(175, 180, 185)

    steel_mat = mats['CBX_Hardware_Steel'] || mats.add('CBX_Hardware_Steel')
    steel_mat.color = Sketchup::Color.new(80, 95, 120)

    dowel_mat = mats['CBX_Beech_Dowel'] || mats.add('CBX_Beech_Dowel')
    dowel_mat.color = Sketchup::Color.new(212, 160, 102)

    hole_mat = mats['CBX_Drill_Hole'] || mats.add('CBX_Drill_Hole')
    hole_mat.color = Sketchup::Color.new(30, 28, 25)

    accent_mat = mats['CBX_Minifix_Indicator'] || mats.add('CBX_Minifix_Indicator')
    accent_mat.color = Sketchup::Color.new(235, 75, 30)

    plinth_mat = mats['CBX_Plinth_Black'] || mats.add('CBX_Plinth_Black')
    plinth_mat.color = Sketchup::Color.new(40, 42, 45)

    {
      carcase: carcase_mat,
      front: front_mat,
      gola: gola_mat,
      drawer_box: drawer_box_mat,
      cam: cam_mat,
      steel: steel_mat,
      dowel: dowel_mat,
      hole: hole_mat,
      accent: accent_mat,
      plinth: plinth_mat
    }
  end

  # ----------------------------------------------------------------------------
  # 3. GEOMETRY HELPERS
  # ----------------------------------------------------------------------------
  def self.create_box(entities, origin, size, material = nil)
    group = entities.add_group
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
  # 4. HIGH-VISIBILITY MINIFIX 15 JOINT BUILDER
  # ----------------------------------------------------------------------------
  def self.build_minifix_joint(parent_ents, bolt_center, dir_vector, mats, face_z_offset = 9.0.mm)
    group = parent_ents.add_group
    group.name = "Minifix 15 Joint (Cam + Bolt + Dowel)"

    inv_vector = dir_vector.reverse

    # 1. Connecting Bolt (Steel)
    create_cylinder(group.entities, bolt_center, inv_vector, 2.5.mm, 11.0.mm, mats[:steel], 12)
    create_cylinder(group.entities, bolt_center, dir_vector, 3.5.mm, 1.5.mm, mats[:steel], 12)
    pin_start = Geom::Point3d.new(
      bolt_center.x + dir_vector.x * 1.5.mm,
      bolt_center.y + dir_vector.y * 1.5.mm,
      bolt_center.z + dir_vector.z * 1.5.mm
    )
    create_cylinder(group.entities, pin_start, dir_vector, 3.2.mm, 32.5.mm, mats[:steel], 12)

    # 2. Minifix Cam Housing & Cam Lock
    cam_x = bolt_center.x + dir_vector.x * MINIFIX_B_DIST
    cam_y = bolt_center.y + dir_vector.y * MINIFIX_B_DIST
    cam_z = bolt_center.z

    cam_top_z = cam_z + face_z_offset
    cam_top_pt = Geom::Point3d.new(cam_x, cam_y, cam_top_z + 0.2.mm)

    c_ring = group.entities.add_circle(cam_top_pt, Geom::Vector3d.new(0, 0, 1), (MINIFIX_CAM_D / 2.0) + 0.3.mm, 20)
    f_ring = group.entities.add_face(c_ring)
    f_ring.material = mats[:hole] if f_ring

    create_cylinder(group.entities, cam_top_pt, Geom::Vector3d.new(0, 0, -1), MINIFIX_CAM_D / 2.0, MINIFIX_CAM_DEPTH, mats[:cam], 20)

    slot_w = 1.4.mm
    slot_l = 7.5.mm
    cz = cam_top_pt.z + 0.15.mm
    f_cross1 = group.entities.add_face([
      Geom::Point3d.new(cam_x - slot_l/2, cam_y - slot_w/2, cz),
      Geom::Point3d.new(cam_x + slot_l/2, cam_y - slot_w/2, cz),
      Geom::Point3d.new(cam_x + slot_l/2, cam_y + slot_w/2, cz),
      Geom::Point3d.new(cam_x - slot_l/2, cam_y + slot_w/2, cz)
    ])
    f_cross1.material = mats[:hole] if f_cross1

    f_cross2 = group.entities.add_face([
      Geom::Point3d.new(cam_x - slot_w/2, cam_y - slot_l/2, cz),
      Geom::Point3d.new(cam_x + slot_w/2, cam_y - slot_l/2, cz),
      Geom::Point3d.new(cam_x + slot_w/2, cam_y + slot_l/2, cz),
      Geom::Point3d.new(cam_x - slot_w/2, cam_y + slot_l/2, cz)
    ])
    f_cross2.material = mats[:hole] if f_cross2

    arr_dx = -dir_vector.x * 3.5.mm
    f_arrow = group.entities.add_face([
      Geom::Point3d.new(cam_x + arr_dx, cam_y, cz),
      Geom::Point3d.new(cam_x - (dir_vector.x * 1.0.mm), cam_y - 2.0.mm, cz),
      Geom::Point3d.new(cam_x - (dir_vector.x * 1.0.mm), cam_y + 2.0.mm, cz)
    ])
    f_arrow.material = mats[:accent] if f_arrow

    dowel_start = Geom::Point3d.new(
      bolt_center.x - dir_vector.x * 10.mm,
      bolt_center.y + 32.mm - dir_vector.y * 10.mm,
      bolt_center.z - dir_vector.z * 10.mm
    )
    create_cylinder(group.entities, dowel_start, dir_vector, DOWEL_D / 2.0, DOWEL_LEN, mats[:dowel], 16)

    group
  end

  # ----------------------------------------------------------------------------
  # 5. GOLA SIDE PANEL WITH CNC NOTCHES
  # ----------------------------------------------------------------------------
  def self.build_gola_side_panel(parent_ents, ox, oy, oz, c_gola_z_bottom, mats)
    panel_group = parent_ents.add_group
    panel_group.name = "Gola Machined Side Panel (18mm)"

    w = BOARD_THK
    d = CARCASE_DEPTH
    h = CARCASE_HEIGHT

    l_z0 = h - L_GOLA_HEIGHT
    l_z1 = h

    c_z0 = c_gola_z_bottom
    c_z1 = c_gola_z_bottom + C_GOLA_HEIGHT

    pts = [
      Geom::Point3d.new(ox, oy, oz),
      Geom::Point3d.new(ox, oy - d, oz),
      Geom::Point3d.new(ox, oy - d, oz + c_z0),
      Geom::Point3d.new(ox, oy - d + GOLA_DEPTH, oz + c_z0),
      Geom::Point3d.new(ox, oy - d + GOLA_DEPTH, oz + c_z1),
      Geom::Point3d.new(ox, oy - d, oz + c_z1),
      Geom::Point3d.new(ox, oy - d, oz + l_z0),
      Geom::Point3d.new(ox, oy - d + GOLA_DEPTH, oz + l_z0),
      Geom::Point3d.new(ox, oy - d + GOLA_DEPTH, oz + l_z1),
      Geom::Point3d.new(ox, oy, oz + l_z1)
    ]

    face = panel_group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.x < 0
      face.pushpull(w)
    end

    panel_group.material = mats[:carcase]
    panel_group
  end

  # ----------------------------------------------------------------------------
  # 6. GOLA ALUMINUM PROFILES (Extruded L & C Shapes)
  # ----------------------------------------------------------------------------
  def self.build_gola_profile(parent_ents, profile_type, length, origin, mats)
    group = parent_ents.add_group
    group.name = "Gola #{profile_type.to_s.upcase} Profile (#{length.to_mm.round}mm)"

    ox, oy, oz = origin.x, origin.y, origin.z

    yz = if profile_type == :l
           [
             [0, 0], [GOLA_WALL, 0], [GOLA_WALL, 44.mm],
             [2.mm, 48.mm], [5.mm, 51.mm], [9.mm, 53.mm],
             [GOLA_PROFILE_D, 53.mm],
             [GOLA_PROFILE_D, L_PROFILE_H],
             [8.mm, L_PROFILE_H], [4.mm, 55.mm],
             [1.mm, 52.mm], [0, 48.mm]
           ]
         else
           [
             [GOLA_PROFILE_D, 0], [GOLA_PROFILE_D, 3.5.mm],
             [9.mm, 3.5.mm], [5.mm, 5.mm], [2.mm, 8.mm],
             [GOLA_WALL, 12.mm],
             [GOLA_WALL, C_PROFILE_H - 12.mm],
             [2.mm, C_PROFILE_H - 8.mm],
             [5.mm, C_PROFILE_H - 5.mm],
             [9.mm, C_PROFILE_H - 3.5.mm],
             [GOLA_PROFILE_D, C_PROFILE_H - 3.5.mm],
             [GOLA_PROFILE_D, C_PROFILE_H],
             [8.mm, C_PROFILE_H],
             [4.mm, C_PROFILE_H - 1.5.mm],
             [1.mm, C_PROFILE_H - 4.5.mm],
             [0, C_PROFILE_H - 9.mm],
             [0, 9.mm], [1.mm, 4.5.mm], [4.mm, 1.5.mm], [8.mm, 0]
           ]
         end

    yz = yz.map { |y, z| [GOLA_PROFILE_D - y, z] }
    if profile_type == :l
      yz = yz.map { |y, z| [y, L_PROFILE_H - z] }
    end

    pts = yz.map { |y, z| Geom::Point3d.new(ox, oy - y, oz + z) }
    face = group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.x < 0
      face.pushpull(length)
    end

    group.material = mats[:gola]
    group
  end

  # ----------------------------------------------------------------------------
  # 7. 3D DRAWER BOX WITH CONCEALED RUNNERS
  # ----------------------------------------------------------------------------
  def self.build_drawer_box(parent_ents, origin, width, depth, height, front_h, pull_offset, mats)
    drawer_group = parent_ents.add_group
    drawer_group.name = "Drawer Unit (#{width.to_mm.round}W x #{front_h.to_mm.round}H)"

    ox = origin.x
    oy = origin.y - pull_offset
    oz = origin.z

    front_group = create_box(
      drawer_group.entities,
      [ox, oy - DRAWER_FRONT_THK, oz],
      [width, DRAWER_FRONT_THK, front_h],
      mats[:front]
    )
    front_group.name = "Drawer Front (18mm Anthracite)"

    box_side_thk = 15.0.mm
    box_w = width - (2 * 12.5.mm)
    box_d = depth - 40.0.mm
    box_h = [height, front_h - 40.mm].min
    box_ox = ox + 12.5.mm
    box_oy = oy
    box_oz = oz + 15.0.mm

    create_box(drawer_group.entities, [box_ox, box_oy, box_oz], [box_side_thk, box_d, box_h], mats[:drawer_box])
    create_box(drawer_group.entities, [box_ox + box_w - box_side_thk, box_oy, box_oz], [box_side_thk, box_d, box_h], mats[:drawer_box])
    create_box(drawer_group.entities, [box_ox + box_side_thk, box_oy, box_oz], [box_w - 2*box_side_thk, box_side_thk, box_h], mats[:drawer_box])
    create_box(drawer_group.entities, [box_ox + box_side_thk, box_oy + box_d - box_side_thk, box_oz], [box_w - 2*box_side_thk, box_side_thk, box_h], mats[:drawer_box])
    create_box(drawer_group.entities, [box_ox, box_oy, box_oz], [box_w, box_d, 12.0.mm], mats[:drawer_box])

    runner_w = 10.0.mm
    runner_h = 24.0.mm
    runner_l = box_d
    create_box(drawer_group.entities, [ox + 1.mm, oy, oz + 4.mm], [runner_w, runner_l, runner_h], mats[:steel])
    create_box(drawer_group.entities, [ox + width - runner_w - 1.mm, oy, oz + 4.mm], [runner_w, runner_l, runner_h], mats[:steel])

    drawer_group
  end

  # ----------------------------------------------------------------------------
  # 8. MASTER GENERATOR: 2x DRAWER BANK BASE UNIT
  # ----------------------------------------------------------------------------
  def self.build_2x_drawer_bank(parent_ents, origin, mats, mode: :hybrid)
    unit_group = parent_ents.add_group
    unit_group.name = "Cabinetrix - 2x Drawer Bank with Gola & Minifix"

    ox = origin.x
    oy = origin.y
    oz = origin.z + PLINTH_HEIGHT

    c_gola_z0 = 330.0.mm
    gap = (mode == :exploded) ? 40.0.mm : 0.0.mm

    # --------------------------------------------------------------------------
    # A. 3x MACHINED GOLA VERTICAL PANELS
    # --------------------------------------------------------------------------
    build_gola_side_panel(unit_group.entities, ox - gap, oy, oz, c_gola_z0, mats)
    build_gola_side_panel(unit_group.entities, ox + BANK_WIDTH - (BOARD_THK / 2.0), oy, oz, c_gola_z0, mats)
    build_gola_side_panel(unit_group.entities, ox + TOTAL_WIDTH - BOARD_THK + gap, oy, oz, c_gola_z0, mats)

    # --------------------------------------------------------------------------
    # B. 2x BOTTOM PANELS WITH 8x MINIFIX JOINERY SETS
    # --------------------------------------------------------------------------
    bay_internal_w = BANK_WIDTH - (1.5 * BOARD_THK)
    b1_ox = ox + BOARD_THK
    b2_ox = ox + BANK_WIDTH + (BOARD_THK / 2.0)

    create_box(unit_group.entities, [b1_ox, oy - CARCASE_DEPTH, oz], [bay_internal_w, CARCASE_DEPTH, BOARD_THK], mats[:carcase])
    create_box(unit_group.entities, [b2_ox, oy - CARCASE_DEPTH, oz], [bay_internal_w, CARCASE_DEPTH, BOARD_THK], mats[:carcase])

    [b1_ox, b2_ox].each do |bay_x|
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x, oy - 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x, oy - CARCASE_DEPTH + 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x + bay_internal_w, oy - 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x + bay_internal_w, oy - CARCASE_DEPTH + 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, BOARD_THK/2.0)
    end

    # --------------------------------------------------------------------------
    # C. TOP REAR & FRONT STRETCHERS WITH 8x MINIFIX JOINERY SETS
    # --------------------------------------------------------------------------
    rail_h = 80.0.mm
    [b1_ox, b2_ox].each do |bay_x|
      stretcher_z = oz + CARCASE_HEIGHT - BOARD_THK
      create_box(unit_group.entities, [bay_x, oy - rail_h, stretcher_z], [bay_internal_w, rail_h, BOARD_THK], mats[:carcase])

      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x, oy - (rail_h / 2.0), stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, -BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x + bay_internal_w, oy - (rail_h / 2.0), stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, -BOARD_THK/2.0)

      front_rail_y = oy - CARCASE_DEPTH + GOLA_DEPTH + 80.mm
      create_box(unit_group.entities, [bay_x, front_rail_y - 80.mm, stretcher_z], [bay_internal_w, 80.mm, BOARD_THK], mats[:carcase])

      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x, front_rail_y - 40.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, -BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x + bay_internal_w, front_rail_y - 40.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, -BOARD_THK/2.0)
    end

    # --------------------------------------------------------------------------
    # D. SOLID BACK PANELS (6mm)
    # --------------------------------------------------------------------------
    [b1_ox, b2_ox].each do |bay_x|
      create_box(
        unit_group.entities,
        [bay_x, oy - 18.mm, oz + BOARD_THK],
        [bay_internal_w, BACK_THK, CARCASE_HEIGHT - BOARD_THK - 10.mm],
        mats[:carcase]
      )
    end

    # --------------------------------------------------------------------------
    # E. CONTINUOUS GOLA ALUMINUM PROFILES
    # --------------------------------------------------------------------------
    gola_length = TOTAL_WIDTH
    build_gola_profile(
      unit_group.entities,
      :l,
      gola_length,
      Geom::Point3d.new(ox, oy - CARCASE_DEPTH + GOLA_DEPTH, oz + CARCASE_HEIGHT - L_GOLA_HEIGHT),
      mats
    )

    build_gola_profile(
      unit_group.entities,
      :c,
      gola_length,
      Geom::Point3d.new(ox, oy - CARCASE_DEPTH + GOLA_DEPTH, oz + c_gola_z0),
      mats
    )

    # --------------------------------------------------------------------------
    # F. 4x DRAWER UNITS
    # --------------------------------------------------------------------------
    unless mode == :joinery
      drawer_front_w = BANK_WIDTH - 3.0.mm
      upper_front_h  = 305.0.mm
      lower_front_h  = 315.0.mm

      [0, 1].each do |bank_idx|
        d_ox = ox + (bank_idx * BANK_WIDTH) + 1.5.mm

        pull_dist_upper = 0.0.mm
        pull_dist_lower = 0.0.mm
        if mode == :hybrid
          pull_dist_upper = (bank_idx == 0) ? 220.0.mm : 0.0.mm
          pull_dist_lower = (bank_idx == 0) ? 350.0.mm : 0.0.mm
        elsif mode == :open
          pull_dist_upper = 220.0.mm
          pull_dist_lower = 350.0.mm
        end

        build_drawer_box(
          unit_group.entities,
          Geom::Point3d.new(d_ox, oy - CARCASE_DEPTH, oz + 12.mm),
          drawer_front_w,
          CARCASE_DEPTH,
          220.0.mm,
          lower_front_h,
          pull_dist_lower,
          mats
        )

        build_drawer_box(
          unit_group.entities,
          Geom::Point3d.new(d_ox, oy - CARCASE_DEPTH, oz + c_gola_z0 + C_GOLA_HEIGHT + 6.mm),
          drawer_front_w,
          CARCASE_DEPTH,
          150.0.mm,
          upper_front_h,
          pull_dist_upper,
          mats
        )
      end
    end

    # --------------------------------------------------------------------------
    # G. RECESSED TOE KICK / PLINTH (100mm)
    # --------------------------------------------------------------------------
    create_box(
      unit_group.entities,
      [ox + 10.mm, oy - CARCASE_DEPTH + PLINTH_SETBACK, origin.z],
      [TOTAL_WIDTH - 20.mm, BOARD_THK, PLINTH_HEIGHT],
      mats[:plinth]
    )

    # --------------------------------------------------------------------------
    # H. 3D TECHNICAL LABELS & POINTERS
    # --------------------------------------------------------------------------
    label_grp = unit_group.entities.add_group
    label_grp.name = "Technical Labels"
    
    title_pos = Geom::Point3d.new(ox, oy - CARCASE_DEPTH - 70.mm, oz + CARCASE_HEIGHT + 35.mm)
    lbl = label_grp.entities.add_group
    lbl.entities.add_3d_text("2x 600mm GOLA DRAWER UNIT (16x MINIFIX 15 JOINTS)", TextAlignLeft, "Arial", true, false, 18.mm, 0.0, 0.5.mm, true, 0)
    lbl.transform!(Geom::Transformation.new(title_pos))

    specs_lines = [
      "• Total 16x Minifix 15 Cams (8 on Bottom Panels + 8 on Top Stretchers)",
      "• Connecting Bolts & Ø8x30mm Fluted Beech Alignment Dowels",
      "• Continuous Black Anodized Gola Aluminum (L-Profile Top + C-Profile Mid)",
      "• CNC Machined Side & Division Pockets (26mm Inset Depth)",
      "• Left Bank Shown Open: Demonstrating Full Internal Minifix & Runner System"
    ]
    
    specs_lines.each_with_index do |line, idx|
      line_g = label_grp.entities.add_group
      line_g.entities.add_3d_text(line, TextAlignLeft, "Arial", false, false, 8.5.mm, 0.0, 0.3.mm, true, 0)
      line_g.transform!(Geom::Transformation.new(Geom::Point3d.new(ox, oy - CARCASE_DEPTH - 70.mm, oz + CARCASE_HEIGHT - (idx * 13.mm))))
    end

    unit_group
  end

  # ----------------------------------------------------------------------------
  # 9. SCENE RUNNER
  # ----------------------------------------------------------------------------
  def self.create_scene(mode: :hybrid)
    model = Sketchup.active_model
    model.start_operation("Create 2x Drawer Bank with Gola & Minifix", true)

    begin
      entities = model.active_entities
      mats = get_materials(model)

      build_2x_drawer_bank(entities, Geom::Point3d.new(0, 0, 0), mats, mode: mode)

      model.active_view.zoom_extents if model.active_view
      model.commit_operation
      puts "================================================================="
      puts " Cabinetrix 2x Drawer Bank (Gola + 16x Minifix Joints) created!"
      puts " Mode: #{mode.to_s.upcase}"
      puts "================================================================="
    rescue => e
      model.abort_operation
      puts "Error creating 2x Drawer Bank: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end

if defined?(UI) && UI.respond_to?(:menu)
  unless file_loaded?(__FILE__)
    plugins_menu = UI.menu('Plugins')
    cbx_menu = plugins_menu.add_submenu('Cabinetrix Gola System')
    
    cbx_menu.add_item('2x Drawer Bank with Gola & Minifix (Hybrid Open/Closed)') do
      CabinetrixGolaDrawerBank.create_scene(mode: :hybrid)
    end

    cbx_menu.add_item('2x Drawer Bank Carcase (Joinery Inspection / No Drawers)') do
      CabinetrixGolaDrawerBank.create_scene(mode: :joinery)
    end

    cbx_menu.add_item('2x Drawer Bank (All Drawers Pulled Open)') do
      CabinetrixGolaDrawerBank.create_scene(mode: :open)
    end

    cbx_menu.add_item('2x Drawer Bank (All Drawers Closed)') do
      CabinetrixGolaDrawerBank.create_scene(mode: :closed)
    end

    cbx_menu.add_item('2x Drawer Bank (Exploded Joint View)') do
      CabinetrixGolaDrawerBank.create_scene(mode: :exploded)
    end

    file_loaded(__FILE__)
  end
end

unless defined?(CABINETRIX_NO_AUTORUN) && CABINETRIX_NO_AUTORUN
  CabinetrixGolaDrawerBank.create_scene(mode: :hybrid) if defined?(Sketchup) && Sketchup.active_model
end
