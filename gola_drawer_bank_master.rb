# ==============================================================================
# CABINETRIX AI — MASTER 2x DRAWER BANK WITH GOLA & MINIFIX 15 JOINERY
# Complete Production Unit + Full Minifix Joinery + Interactive Workshop Report
# ==============================================================================
require 'sketchup.rb'
require 'json'

module CabinetrixMasterGola
  # ----------------------------------------------------------------------------
  # 1. PARAMETERS & DIMENSIONS (System 32 Standard)
  # ----------------------------------------------------------------------------
  BOARD_THK         = 18.0.mm   # 18mm carcase & stretcher thickness
  DRAWER_FRONT_THK  = 18.0.mm   # 18mm drawer fronts
  BACK_THK          = 6.0.mm    # 6mm back panel
  
  BANK_COUNT        = 2         # 2 drawer banks
  BANK_WIDTH        = 600.0.mm  # 600mm width per bay
  TOTAL_WIDTH       = (BANK_COUNT * BANK_WIDTH) # 1200mm total width
  CARCASE_HEIGHT    = 720.0.mm  # Standard European carcase height
  CARCASE_DEPTH     = 560.0.mm  # Standard base carcase depth
  PLINTH_HEIGHT     = 100.0.mm  # 100mm plinth/toe-kick
  PLINTH_SETBACK    = 50.0.mm   # 50mm front toe-kick setback

  # Gola Profile Parameters (SCILM / Häfele Standard)
  GOLA_DEPTH        = 26.0.mm   # Side panel notch depth from front
  L_GOLA_HEIGHT     = 59.0.mm   # Top L-Gola cutout height
  C_GOLA_HEIGHT     = 73.5.mm   # Mid C-Gola cutout height
  GOLA_WALL         = 1.5.mm    # Aluminum wall thickness
  GOLA_PROFILE_D    = 27.2.mm   # Aluminum extrusion depth
  L_PROFILE_H       = 56.5.mm   # L-profile height
  C_PROFILE_H       = 73.0.mm   # C-profile height

  # Minifix 15 Standards (Häfele System 32)
  MINIFIX_CAM_D     = 15.0.mm
  MINIFIX_CAM_DEPTH = 12.5.mm
  MINIFIX_B_DIST    = 34.0.mm   # 34mm standard drilling distance from edge
  DOWEL_D           = 8.0.mm
  DOWEL_LEN         = 30.0.mm

  # ----------------------------------------------------------------------------
  # 2. MATERIAL DEFINITIONS
  # ----------------------------------------------------------------------------
  def self.get_materials(model)
    mats = model.materials

    carcase_mat = mats['CBX_Carcase_White'] || mats.add('CBX_Carcase_White')
    carcase_mat.color = Sketchup::Color.new(245, 245, 242)

    stretcher_mat = mats['CBX_Stretcher_Wood'] || mats.add('CBX_Stretcher_Wood')
    stretcher_mat.color = Sketchup::Color.new(230, 226, 218)

    front_mat = mats['CBX_Front_Anthracite'] || mats.add('CBX_Front_Anthracite')
    front_mat.color = Sketchup::Color.new(45, 48, 54)

    gola_mat = mats['CBX_Gola_Black_Anodized'] || mats.add('CBX_Gola_Black_Anodized')
    gola_mat.color = Sketchup::Color.new(25, 27, 30)

    drawer_box_mat = mats['CBX_Drawer_Birch'] || mats.add('CBX_Drawer_Birch')
    drawer_box_mat.color = Sketchup::Color.new(225, 212, 190)

    # Vivid Hardware Colors
    cam_mat = mats['CBX_Minifix_Zinc'] || mats.add('CBX_Minifix_Zinc')
    cam_mat.color = Sketchup::Color.new(180, 185, 190)

    steel_mat = mats['CBX_Hardware_Steel'] || mats.add('CBX_Hardware_Steel')
    steel_mat.color = Sketchup::Color.new(70, 85, 110)

    dowel_mat = mats['CBX_Beech_Dowel'] || mats.add('CBX_Beech_Dowel')
    dowel_mat.color = Sketchup::Color.new(215, 160, 95)

    hole_mat = mats['CBX_Drill_Hole'] || mats.add('CBX_Drill_Hole')
    hole_mat.color = Sketchup::Color.new(20, 20, 20)

    indicator_mat = mats['CBX_Indicator_Orange'] || mats.add('CBX_Indicator_Orange')
    indicator_mat.color = Sketchup::Color.new(240, 80, 20)

    plinth_mat = mats['CBX_Plinth_Black'] || mats.add('CBX_Plinth_Black')
    plinth_mat.color = Sketchup::Color.new(35, 36, 38)

    {
      carcase: carcase_mat,
      stretcher: stretcher_mat,
      front: front_mat,
      gola: gola_mat,
      drawer_box: drawer_box_mat,
      cam: cam_mat,
      steel: steel_mat,
      dowel: dowel_mat,
      hole: hole_mat,
      indicator: indicator_mat,
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
  # 4. HIGH-PRECISION MINIFIX 15 JOINT GENERATOR
  # ----------------------------------------------------------------------------
  def self.build_minifix_joint(parent_ents, bolt_center, dir_vector, mats, cam_normal = Geom::Vector3d.new(0, 0, 1), cam_offset_dist = 9.0.mm)
    group = parent_ents.add_group
    group.name = "Minifix 15 Set"

    inv_vector = dir_vector.reverse

    # 1. Connecting Bolt (Steel)
    create_cylinder(group.entities, bolt_center, inv_vector, 2.5.mm, 11.0.mm, mats[:steel], 12)
    create_cylinder(group.entities, bolt_center, dir_vector, 3.75.mm, 1.5.mm, mats[:steel], 12)
    pin_start = Geom::Point3d.new(
      bolt_center.x + dir_vector.x * 1.5.mm,
      bolt_center.y + dir_vector.y * 1.5.mm,
      bolt_center.z + dir_vector.z * 1.5.mm
    )
    create_cylinder(group.entities, pin_start, dir_vector, 3.25.mm, 32.5.mm, mats[:steel], 12)

    # 2. Minifix Cam Housing & Cam Lock
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

    c_rim = group.entities.add_circle(vis_pt, cam_normal, (MINIFIX_CAM_D / 2.0) + 0.3.mm, 20)
    f_rim = group.entities.add_face(c_rim)
    f_rim.material = mats[:hole] if f_rim

    cam_inward_dir = cam_normal.reverse
    create_cylinder(group.entities, vis_pt, cam_inward_dir, MINIFIX_CAM_D / 2.0, MINIFIX_CAM_DEPTH, mats[:cam], 20)

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

    arr_dir_x = -dir_vector.x * 3.5.mm
    f_arr = group.entities.add_face([
      Geom::Point3d.new(cx + arr_dir_x, cy, cz),
      Geom::Point3d.new(cx - (dir_vector.x * 0.8.mm), cy - 2.2.mm, cz),
      Geom::Point3d.new(cx - (dir_vector.x * 0.8.mm), cy + 2.2.mm, cz)
    ])
    f_arr.material = mats[:indicator] if f_arr

    dowel_start = Geom::Point3d.new(
      bolt_center.x - dir_vector.x * 10.mm,
      bolt_center.y + (32.mm * (bolt_center.y > -280.mm ? -1 : 1)) - dir_vector.y * 10.mm,
      bolt_center.z
    )
    create_cylinder(group.entities, dowel_start, dir_vector, DOWEL_D / 2.0, DOWEL_LEN, mats[:dowel], 16)

    group
  end

  # ----------------------------------------------------------------------------
  # 5. GOLA SIDE & DIVISION PANELS (WITH ACCURATE CNC NOTCHES)
  # ----------------------------------------------------------------------------
  def self.build_gola_side_panel(parent_ents, ox, oy, oz, c_gola_z0, mats)
    panel_group = parent_ents.add_group
    panel_group.name = "Gola Machined Side Panel (18mm)"

    w = BOARD_THK
    d = CARCASE_DEPTH
    h = CARCASE_HEIGHT

    l_z0 = h - L_GOLA_HEIGHT
    l_z1 = h

    c_z0 = c_gola_z0
    c_z1 = c_gola_z0 + C_GOLA_HEIGHT

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
  # 6. GOLA ALUMINUM PROFILES
  # ----------------------------------------------------------------------------
  def self.build_gola_profile(parent_ents, profile_type, length, origin, mats)
    group = parent_ents.add_group
    group.name = "Gola #{profile_type.to_s.upcase} Aluminum Profile (#{length.to_mm.round}mm)"

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
    front_group.name = "Drawer Front"

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
  # 8. MASTER 2x DRAWER BANK GENERATOR WITH ALL 20x MINIFIX STRETCHERS
  # ----------------------------------------------------------------------------
  def self.build_complete_system(parent_ents, origin, mats, mode: :hybrid)
    unit_group = parent_ents.add_group
    unit_group.name = "Cabinetrix - Master 2x Drawer Bank (Gola & Minifix 15)"

    ox = origin.x
    oy = origin.y
    oz = origin.z + PLINTH_HEIGHT

    c_gola_z0 = 330.0.mm
    bay_internal_w = BANK_WIDTH - (1.5 * BOARD_THK)
    b1_ox = ox + BOARD_THK
    b2_ox = ox + BANK_WIDTH + (BOARD_THK / 2.0)

    # A. 3x Machined Gola Vertical Panels
    build_gola_side_panel(unit_group.entities, ox, oy, oz, c_gola_z0, mats)
    build_gola_side_panel(unit_group.entities, ox + BANK_WIDTH - (BOARD_THK / 2.0), oy, oz, c_gola_z0, mats)
    build_gola_side_panel(unit_group.entities, ox + TOTAL_WIDTH - BOARD_THK, oy, oz, c_gola_z0, mats)

    # B. 2x Bottom Panels with 8x Minifix Sets
    create_box(unit_group.entities, [b1_ox, oy - CARCASE_DEPTH, oz], [bay_internal_w, CARCASE_DEPTH, BOARD_THK], mats[:carcase])
    create_box(unit_group.entities, [b2_ox, oy - CARCASE_DEPTH, oz], [bay_internal_w, CARCASE_DEPTH, BOARD_THK], mats[:carcase])

    [b1_ox, b2_ox].each do |bay_x|
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x, oy - 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, Geom::Vector3d.new(0, 0, 1), BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x, oy - CARCASE_DEPTH + 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, Geom::Vector3d.new(0, 0, 1), BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x + bay_internal_w, oy - 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, Geom::Vector3d.new(0, 0, 1), BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x + bay_internal_w, oy - CARCASE_DEPTH + 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, Geom::Vector3d.new(0, 0, 1), BOARD_THK/2.0)
    end

    # C. Top Rear Stretchers (18x100mm) with 4x Minifix Sets
    stretcher_w = 100.0.mm
    stretcher_z = oz + CARCASE_HEIGHT - BOARD_THK
    [b1_ox, b2_ox].each do |bay_x|
      create_box(unit_group.entities, [bay_x, oy - stretcher_w, stretcher_z], [bay_internal_w, stretcher_w, BOARD_THK], mats[:stretcher])
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x, oy - (stretcher_w / 2.0), stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, Geom::Vector3d.new(0, 0, -1), BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x + bay_internal_w, oy - (stretcher_w / 2.0), stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, Geom::Vector3d.new(0, 0, -1), BOARD_THK/2.0)
    end

    # D. Top Front L-Gola Sub-Stretchers (18x80mm) with 4x Minifix Sets
    front_sub_y = oy - CARCASE_DEPTH + GOLA_DEPTH
    [b1_ox, b2_ox].each do |bay_x|
      create_box(unit_group.entities, [bay_x, front_sub_y, stretcher_z], [bay_internal_w, 80.mm, BOARD_THK], mats[:stretcher])
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x, front_sub_y + 40.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, Geom::Vector3d.new(0, 0, -1), BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x + bay_internal_w, front_sub_y + 40.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, Geom::Vector3d.new(0, 0, -1), BOARD_THK/2.0)
    end

    # E. Mid C-Gola Structural Tie Stretchers (18x60mm) with 4x Minifix Sets
    mid_stretcher_z = oz + c_gola_z0 + C_GOLA_HEIGHT - BOARD_THK
    [b1_ox, b2_ox].each do |bay_x|
      create_box(unit_group.entities, [bay_x, front_sub_y, mid_stretcher_z], [bay_internal_w, 60.mm, BOARD_THK], mats[:stretcher])
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x, front_sub_y + 30.mm, mid_stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, Geom::Vector3d.new(0, 0, -1), BOARD_THK/2.0)
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bay_x + bay_internal_w, front_sub_y + 30.mm, mid_stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, Geom::Vector3d.new(0, 0, -1), BOARD_THK/2.0)
    end

    # F. Solid Back Panels (6mm)
    [b1_ox, b2_ox].each do |bay_x|
      create_box(
        unit_group.entities,
        [bay_x, oy - 18.mm, oz + BOARD_THK],
        [bay_internal_w, BACK_THK, CARCASE_HEIGHT - BOARD_THK - 10.mm],
        mats[:carcase]
      )
    end

    # G. Continuous Gola Aluminum Profiles
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

    # H. 4x Drawer Units
    unless mode == :carcase_only
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
        elsif mode == :all_open
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

    # I. Plinth
    create_box(
      unit_group.entities,
      [ox + 10.mm, oy - CARCASE_DEPTH + PLINTH_SETBACK, origin.z],
      [TOTAL_WIDTH - 20.mm, BOARD_THK, PLINTH_HEIGHT],
      mats[:plinth]
    )

    # J. 3D Technical Annotations
    label_grp = unit_group.entities.add_group
    label_grp.name = "Technical Labels"
    
    title_pos = Geom::Point3d.new(ox, oy - CARCASE_DEPTH - 70.mm, oz + CARCASE_HEIGHT + 40.mm)
    lbl = label_grp.entities.add_group
    lbl.entities.add_3d_text("CABINETRIX 2x 600mm GOLA DRAWER BANK (20x MINIFIX JOINTS)", TextAlignLeft, "Arial", true, false, 18.mm, 0.0, 0.5.mm, true, 0)
    lbl.transform!(Geom::Transformation.new(title_pos))

    specs_lines = [
      "• Total 20x Minifix 15 Joinery Sets + Dowels (Bottom + Top Rear + Front Sub + Mid-C Stretchers)",
      "• Complete Stretchers: Top Rear (100mm) | Top Front (80mm) | Mid-C Gola Sub-Stretcher (60mm)",
      "• Gola System: Continuous Anodized Aluminum L-Gola (Top) & C-Gola (Middle)",
      "• CNC Notches: 59mm L-Pocket & 73.5mm C-Pocket (26mm Inset Depth)",
      "• Left Bank Open: Full Visual Inspection of Internal Minifix Cams & Soft-Close Runners"
    ]
    
    specs_lines.each_with_index do |line, idx|
      line_g = label_grp.entities.add_group
      line_g.entities.add_3d_text(line, TextAlignLeft, "Arial", false, false, 8.5.mm, 0.0, 0.3.mm, true, 0)
      line_g.transform!(Geom::Transformation.new(Geom::Point3d.new(ox, oy - CARCASE_DEPTH - 70.mm, oz + CARCASE_HEIGHT - (idx * 13.mm))))
    end

    unit_group
  end

  # ----------------------------------------------------------------------------
  # 9. HTML WORKSHOP & CNC REPORT GENERATOR
  # ----------------------------------------------------------------------------
  def self.generate_workshop_report_html
    report_file = File.join('c:', 'Users', 'asank', 'Documents', 'CabinetrixAionline', 'Cabinetrix_2x_Gola_Drawer_Bank_Report.html')

    html_content = <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <title>Cabinetrix AI — 2x Gola Drawer Bank Production & CNC Report</title>
        <style>
          :root {
            --primary: #2563eb;
            --primary-dark: #1d4ed8;
            --dark: #0f172a;
            --card-bg: #ffffff;
            --border: #e2e8f0;
            --text-main: #1e293b;
            --text-muted: #64748b;
            --accent: #f97316;
            --success: #10b981;
          }
          * { box-sizing: border-box; margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
          body { background: #f8fafc; color: var(--text-main); padding: 30px; }
          .container { max-width: 1100px; margin: 0 auto; }
          .header { background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%); color: white; padding: 30px; border-radius: 12px; margin-bottom: 25px; box-shadow: 0 10px 25px rgba(0,0,0,0.1); }
          .header h1 { font-size: 26px; margin-bottom: 8px; color: #ffffff; }
          .header p { color: #94a3b8; font-size: 14px; }
          .badge { display: inline-block; background: var(--accent); color: white; padding: 4px 10px; border-radius: 6px; font-weight: bold; font-size: 12px; margin-top: 10px; }
          
          .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap: 15px; margin-bottom: 25px; }
          .stat-card { background: white; padding: 20px; border-radius: 10px; border: 1px solid var(--border); box-shadow: 0 2px 4px rgba(0,0,0,0.02); }
          .stat-card .label { font-size: 12px; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.5px; margin-bottom: 5px; }
          .stat-card .value { font-size: 22px; font-weight: bold; color: var(--dark); }
          
          .section { background: white; border-radius: 10px; border: 1px solid var(--border); padding: 25px; margin-bottom: 25px; box-shadow: 0 2px 4px rgba(0,0,0,0.02); }
          .section h2 { font-size: 18px; margin-bottom: 15px; color: var(--dark); border-bottom: 2px solid #f1f5f9; padding-bottom: 10px; }
          
          table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }
          th { background: #f8fafc; color: #475569; text-align: left; padding: 10px 12px; border-bottom: 2px solid var(--border); font-weight: 600; }
          td { padding: 10px 12px; border-bottom: 1px solid var(--border); }
          tr:hover td { background: #f8fafc; }
          .tag { padding: 3px 8px; border-radius: 4px; font-size: 11px; font-weight: 600; }
          .tag-zinc { background: #e0f2fe; color: #0369a1; }
          .tag-alu { background: #f1f5f9; color: #334155; }
          .tag-wood { background: #fef3c7; color: #b45309; }
          
          .footer { text-align: center; color: var(--text-muted); font-size: 12px; margin-top: 30px; }
          .print-btn { background: var(--primary); color: white; border: none; padding: 10px 20px; border-radius: 6px; cursor: pointer; font-weight: bold; margin-bottom: 20px; }
          .print-btn:hover { background: var(--primary-dark); }
        </style>
      </head>
      <body>
        <div class="container">
          <button class="print-btn" onclick="window.print()">🖨️ Print Production Report</button>
          
          <div class="header">
            <h1>Cabinetrix AI — 2x Gola Drawer Bank Workshop & CNC Report</h1>
            <p>Project: 1200mm Base Cabinet (2x 600mm Banks) with Handleless Gola Profiles & 20x Minifix 15 Joinery</p>
            <span class="badge">PRODUCTION READY (SYSTEM 32 CNC)</span>
          </div>

          <div class="grid">
            <div class="stat-card">
              <div class="label">Total Dimensions</div>
              <div class="value">1200 × 560 × 820 mm</div>
            </div>
            <div class="stat-card">
              <div class="label">Total Minifix 15 Joints</div>
              <div class="value">20 Cams + 20 Bolts</div>
            </div>
            <div class="stat-card">
              <div class="label">Alignment Dowels</div>
              <div class="value">20x Ø8×30mm Beech</div>
            </div>
            <div class="stat-card">
              <div class="label">Gola Extrusions</div>
              <div class="value">1x Top L + 1x Mid C (1.2m)</div>
            </div>
          </div>

          <div class="section">
            <h2>1. Carcase Panel Cutting List</h2>
            <table>
              <thead>
                <tr>
                  <th>Part Name</th>
                  <th>Qty</th>
                  <th>Length (mm)</th>
                  <th>Width (mm)</th>
                  <th>Thk (mm)</th>
                  <th>Material</th>
                  <th>Edge Banding</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><strong>Gola Machined Side Panels (Left & Right Ends)</strong></td>
                  <td>2</td>
                  <td>720.0</td>
                  <td>560.0</td>
                  <td>18.0</td>
                  <td>White Moisture Resistant MDF/PB</td>
                  <td>1mm ABS Front & Top</td>
                </tr>
                <tr>
                  <td><strong>Gola Machined Center Division Panel</strong></td>
                  <td>1</td>
                  <td>720.0</td>
                  <td>560.0</td>
                  <td>18.0</td>
                  <td>White Moisture Resistant MDF/PB</td>
                  <td>1mm ABS Front & Top</td>
                </tr>
                <tr>
                  <td><strong>Bottom Base Panels</strong></td>
                  <td>2</td>
                  <td>573.0</td>
                  <td>560.0</td>
                  <td>18.0</td>
                  <td>White Moisture Resistant MDF/PB</td>
                  <td>1mm ABS Front Edge</td>
                </tr>
                <tr>
                  <td><strong>Top Rear Horizontal Stretchers</strong></td>
                  <td>2</td>
                  <td>573.0</td>
                  <td>100.0</td>
                  <td>18.0</td>
                  <td>White Moisture Resistant MDF/PB</td>
                  <td>0.4mm Melamine</td>
                </tr>
                <tr>
                  <td><strong>Top Front L-Gola Sub-Stretchers</strong></td>
                  <td>2</td>
                  <td>573.0</td>
                  <td>80.0</td>
                  <td>18.0</td>
                  <td>White Moisture Resistant MDF/PB</td>
                  <td>0.4mm Melamine</td>
                </tr>
                <tr>
                  <td><strong>Mid C-Gola Tie Stretchers</strong></td>
                  <td>2</td>
                  <td>573.0</td>
                  <td>60.0</td>
                  <td>18.0</td>
                  <td>White Moisture Resistant MDF/PB</td>
                  <td>0.4mm Melamine</td>
                </tr>
                <tr>
                  <td><strong>Grooved Back Panels</strong></td>
                  <td>2</td>
                  <td>692.0</td>
                  <td>573.0</td>
                  <td>6.0</td>
                  <td>White HDF / Lacquered Backboard</td>
                  <td>None (In Groove)</td>
                </tr>
                <tr>
                  <td><strong>Upper Drawer Fronts</strong></td>
                  <td>2</td>
                  <td>597.0</td>
                  <td>305.0</td>
                  <td>18.0</td>
                  <td>Anthracite Matt Lacquered / Acrylic</td>
                  <td>1mm Laser/PUR Edging</td>
                </tr>
                <tr>
                  <td><strong>Lower Deep Pan Drawer Fronts</strong></td>
                  <td>2</td>
                  <td>597.0</td>
                  <td>315.0</td>
                  <td>18.0</td>
                  <td>Anthracite Matt Lacquered / Acrylic</td>
                  <td>1mm Laser/PUR Edging</td>
                </tr>
                <tr>
                  <td><strong>Recessed Toe Kick / Plinth</strong></td>
                  <td>1</td>
                  <td>1180.0</td>
                  <td>100.0</td>
                  <td>18.0</td>
                  <td>Black Matt Water-Resistant Plinth</td>
                  <td>1mm PVC with Floor Seal</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="section">
            <h2>2. CNC Drilling & Boring Schedule (System 32)</h2>
            <table>
              <thead>
                <tr>
                  <th>Component</th>
                  <th>Hole Type</th>
                  <th>Diameter</th>
                  <th>Depth</th>
                  <th>Drill Distance / Location</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td>Bottom Panels (Inside Face)</td>
                  <td>Minifix Cam Housing</td>
                  <td>Ø15.0 mm</td>
                  <td>12.5 mm</td>
                  <td>34.0 mm from left/right edges (Front & Rear)</td>
                </tr>
                <tr>
                  <td>Bottom Panels (Edges)</td>
                  <td>Minifix Bolt Edge Bore</td>
                  <td>Ø8.0 mm</td>
                  <td>34.0 mm</td>
                  <td>Centered on 9.0 mm centerline</td>
                </tr>
                <tr>
                  <td>Top Rear Stretchers</td>
                  <td>Minifix Cam Housing</td>
                  <td>Ø15.0 mm</td>
                  <td>12.5 mm</td>
                  <td>34.0 mm from left/right edges (Underside)</td>
                </tr>
                <tr>
                  <td>Top Front L-Gola Stretchers</td>
                  <td>Minifix Cam Housing</td>
                  <td>Ø15.0 mm</td>
                  <td>12.5 mm</td>
                  <td>34.0 mm from left/right edges (Underside)</td>
                </tr>
                <tr>
                  <td>Mid C-Gola Tie Stretchers</td>
                  <td>Minifix Cam Housing</td>
                  <td>Ø15.0 mm</td>
                  <td>12.5 mm</td>
                  <td>34.0 mm from left/right edges (Underside)</td>
                </tr>
                <tr>
                  <td>Side & Division Panels (Faces)</td>
                  <td>Minifix Bolt Euro-Bores</td>
                  <td>Ø5.0 mm</td>
                  <td>11.5 mm</td>
                  <td>System 32 vertical pitch (70mm, 490mm, 711mm)</td>
                </tr>
                <tr>
                  <td>All Joint Faces & Edges</td>
                  <td>Alignment Dowel Bores</td>
                  <td>Ø8.0 mm</td>
                  <td>11mm (Face) / 21mm (Edge)</td>
                  <td>32.0 mm offset from Minifix centerline</td>
                </tr>
                <tr>
                  <td>Side & Division Panels (Front Edge)</td>
                  <td>CNC Gola L-Notch</td>
                  <td>26 mm Deep</td>
                  <td>59.0 mm High</td>
                  <td>Top front corner (Z=661 to 720mm)</td>
                </tr>
                <tr>
                  <td>Side & Division Panels (Front Edge)</td>
                  <td>CNC Gola C-Notch</td>
                  <td>26 mm Deep</td>
                  <td>73.5 mm High</td>
                  <td>Intermediate front (Z=330 to 403.5mm)</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="section">
            <h2>3. Hardware Bill of Materials (BOM)</h2>
            <table>
              <thead>
                <tr>
                  <th>Item Description</th>
                  <th>Category</th>
                  <th>Qty</th>
                  <th>Supplier Ref</th>
                </tr>
              </thead>
              <tbody>
                <tr>
                  <td><strong>Häfele / Hettich Minifix 15 Zinc Cam Lock</strong></td>
                  <td><span class="tag tag-zinc">KD Joinery</span></td>
                  <td>20 pcs</td>
                  <td>Häfele 262.28.034 / Hettich Rastex 15</td>
                </tr>
                <tr>
                  <td><strong>Minifix Connecting Bolt (M6 / Euro Thread)</strong></td>
                  <td><span class="tag tag-zinc">KD Joinery</span></td>
                  <td>20 pcs</td>
                  <td>Häfele 262.27.679 / Hettich Twister DU</td>
                </tr>
                <tr>
                  <td><strong>Fluted Beech Wooden Dowels (Ø8 × 30 mm)</strong></td>
                  <td><span class="tag tag-wood">Alignment</span></td>
                  <td>20 pcs</td>
                  <td>Pre-glued European Beech</td>
                </tr>
                <tr>
                  <td><strong>SCILM / Häfele L-Gola Undertop Profile (Black Anodized)</strong></td>
                  <td><span class="tag tag-alu">Extrusion</span></td>
                  <td>1,200 mm</td>
                  <td>SCILM 8006 / Häfele Gola L</td>
                </tr>
                <tr>
                  <td><strong>SCILM / Häfele C-Gola Mid-Drawer Profile (Black Anodized)</strong></td>
                  <td><span class="tag tag-alu">Extrusion</span></td>
                  <td>1,200 mm</td>
                  <td>SCILM 8007 / Häfele Gola C</td>
                </tr>
                <tr>
                  <td><strong>Gola Profile Fixing Brackets & Screws</strong></td>
                  <td><span class="tag tag-alu">Fasteners</span></td>
                  <td>6 sets</td>
                  <td>Gola Metal Snap-in Spring Clips</td>
                </tr>
                <tr>
                  <td><strong>Concealed Undermount Soft-Close Slides (500mm, 40kg)</strong></td>
                  <td><span class="tag tag-zinc">Runners</span></td>
                  <td>4 pairs</td>
                  <td>Blum Tandembox / Hettich Actro 5D</td>
                </tr>
                <tr>
                  <td><strong>Birch Plywood / Melamine Drawer Boxes</strong></td>
                  <td><span class="tag tag-wood">Drawers</span></td>
                  <td>4 units</td>
                  <td>2x Cutlery (150mm H), 2x Pan (220mm H)</td>
                </tr>
              </tbody>
            </table>
          </div>

          <div class="footer">
            <p>© #{Time.now.year} Cabinetrix AI — Advanced Parametric Cabinetmaking Engine</p>
          </div>
        </div>
      </body>
      </html>
    HTML

    File.write(report_file, html_content)
    puts "✅ Workshop Report successfully saved to: #{report_file}"
    report_file
  end

  # ----------------------------------------------------------------------------
  # 10. SCENE RUNNER & REPORT LAUNCHER
  # ----------------------------------------------------------------------------
  def self.build_all_and_show_report(mode: :hybrid)
    model = Sketchup.active_model
    model.start_operation("Cabinetrix 2x Gola Drawer Bank", true)

    begin
      entities = model.active_entities
      mats = get_materials(model)

      build_complete_system(entities, Geom::Point3d.new(0, 0, 0), mats, mode: mode)
      model.active_view.zoom_extents if model.active_view
      model.commit_operation

      report_path = generate_workshop_report_html

      if defined?(UI::HtmlDialog)
        dialog = UI::HtmlDialog.new(
          :dialog_title => "Cabinetrix AI — 2x Gola Drawer Bank Workshop Report",
          :preferences_key => "com.cabinetrix.golareport",
          :scrollable => true,
          :resizable => true,
          :width => 1050,
          :height => 750,
          :left => 100,
          :top => 100,
          :min_width => 800,
          :min_height => 500,
          :style => UI::HtmlDialog::STYLE_DIALOG
        )
        dialog.set_file(report_path)
        dialog.show
      elsif defined?(UI) && UI.respond_to?(:openURL)
        UI.openURL("file:///#{report_path}")
      end

      puts "================================================================="
      puts " Cabinetrix 2x Drawer Bank with 20x Minifix 15 Joints & Stretchers"
      puts " Model Generated + Workshop Production Report Opened!"
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
    cbx_menu = plugins_menu.add_submenu('Cabinetrix Master Gola')
    
    cbx_menu.add_item('Generate 2x Gola Drawer Bank + Open Workshop Report') do
      CabinetrixMasterGola.build_all_and_show_report(mode: :hybrid)
    end

    cbx_menu.add_item('Carcase & 20x Minifix Inspection View (No Drawers)') do
      CabinetrixMasterGola.build_all_and_show_report(mode: :carcase_only)
    end

    cbx_menu.add_item('Open Workshop HTML Report in Browser') do
      path = CabinetrixMasterGola.generate_workshop_report_html
      UI.openURL("file:///#{path}")
    end

    file_loaded(__FILE__)
  end
end

unless defined?(CABINETRIX_NO_AUTORUN) && CABINETRIX_NO_AUTORUN
  CabinetrixMasterGola.build_all_and_show_report(mode: :hybrid) if defined?(Sketchup) && Sketchup.active_model
end
