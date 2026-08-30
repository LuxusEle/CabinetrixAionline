# ==============================================================================
# CABINETRIX AI — UNIVERSAL PARAMETRIC BOX ENGINE (PRODUCTION STANDARD)
# File: gemini/cabinetrix_box_engine.rb
#
# Production Standard:
#   • AUTHENTIC BLUM AVENTOS HF BI-FOLD LIFT MECHANISM & TWO-SECTION DOORS:
#     - Horizontal 2-section bi-fold split (Upper Door + Lower Door with 3mm reveal).
#     - Blum AVENTOS HF Power Factor Drive Units (LH & RH).
#     - Telescopic Steel Lift Arms with front fixing brackets connecting lower door.
#     - Intermediate bi-fold hinges & top CLIP top 120° hinges.
#   • AUTHENTIC 45° MITERED HOLLOW ALUMINUM SASH DOOR SKILL (ALU SYS).
#   • EXACT SHOTGUN BLIND CORNER IMPLEMENTATION.
#   • AUTHENTIC GOLA BEVELED FINGER-PULL EXTENDED FRONTS.
# ==============================================================================
require 'sketchup.rb'
require_relative 'cabinetrix_collision_engine'

module CabinetrixBoxEngine
  BOARD_THK         = 18.0.mm
  FRONT_THK         = 18.0.mm
  DRAWER_BOX_THK    = 15.0.mm
  BACK_THK          = 6.0.mm
  BACK_GROOVE       = 5.0.mm

  PLINTH_HEIGHT     = 100.0.mm
  BASE_CARCASE_H    = 720.0.mm
  BASE_DEPTH        = 560.0.mm
  WALL_CARCASE_H    = 720.0.mm
  WALL_DEPTH        = 350.0.mm
  TALL_CARCASE_H    = 2160.0.mm
  TALL_DEPTH        = 600.0.mm
  BASE_DATUM_Z      = (PLINTH_HEIGHT + BASE_CARCASE_H)

  # SCILM Gola Catalog Profile Dimensions
  GOLA_DEPTH        = 26.0.mm
  L_GOLA_H          = 59.0.mm
  C_GOLA_H          = 73.5.mm
  C_GOLA_Z0         = 330.0.mm
  GOLA_WALL         = 1.5.mm
  GOLA_PROFILE_D    = 27.2.mm
  L_PROFILE_H       = 56.5.mm
  C_PROFILE_H       = 73.0.mm

  # AUTHENTIC GOLA FINGER-PULL EXTENDED FRONT DATUMS
  LOWER_FRONT_H     = 342.0.mm
  UPPER_FRONT_H     = 285.0.mm
  LOWER_DRAWER_Z    = 3.0.mm
  UPPER_DRAWER_Z    = 390.0.mm

  # ----------------------------------------------------------------------------
  # 1. CORE SOLID PRIMITIVES
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

  # Authentic Shotgun Front U-Notched Single Solid Sheet
  def self.create_front_notched_shelf(entities, name, origin, size, notch_x0, notch_w, notch_d, material)
    group = entities.add_group
    group.name = name
    ox, oy, oz = origin
    sw, sd, sthk = size

    pts = [
      Geom::Point3d.new(ox, oy + sd, oz),
      Geom::Point3d.new(ox + sw, oy + sd, oz),
      Geom::Point3d.new(ox + sw, oy, oz),
      Geom::Point3d.new(notch_x0 + notch_w, oy, oz),
      Geom::Point3d.new(notch_x0 + notch_w, oy + notch_d, oz),
      Geom::Point3d.new(notch_x0, oy + notch_d, oz),
      Geom::Point3d.new(notch_x0, oy, oz),
      Geom::Point3d.new(ox, oy, oz)
    ]

    face = group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.z < 0
      face.pushpull(sthk)
    end
    group.material = material if material
    group
  end

  def self.build_shotgun_grooved_back(parent_ents, name_prefix, width, base_z, top_z, mats, has_mid_cleat: false, mid_cleat_z: nil)
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

    sheet_ox = thk - groove
    sheet_oy = -thk - back_t
    sheet_oz = base_z + thk - groove
    create_box(group.entities, [sheet_ox, sheet_oy, sheet_oz], [sheet_w, back_t, sheet_h], mats[:carcase], "#{name_prefix}_Grooved_Back_Sheet")
    create_box(group.entities, [thk, -thk, top_z - thk - cleat_h], [stretcher_w, thk, cleat_h], mats[:carcase], "#{name_prefix}_Rear_Top_Vertical_Cleat")
    create_box(group.entities, [thk, -thk, base_z + thk], [stretcher_w, thk, cleat_h], mats[:carcase], "#{name_prefix}_Rear_Bottom_Vertical_Cleat")

    if has_mid_cleat && mid_cleat_z
      create_box(group.entities, [thk, -thk, mid_cleat_z - cleat_h], [stretcher_w, thk, cleat_h], mats[:carcase], "#{name_prefix}_Rear_Mid_Vertical_Cleat")
    end
    group
  end

  def self.build_structural_shelf(parent_ents, name, width, depth, z_pos, mats, full_depth_to_wall: false)
    group = parent_ents.add_group
    group.name = name
    inner_w = width - (2 * BOARD_THK)
    shelf_d = full_depth_to_wall ? depth : (depth - BOARD_THK)
    y_start = -depth

    create_box(group.entities, [BOARD_THK, y_start, z_pos], [inner_w, shelf_d, BOARD_THK], mats[:carcase], "Shelf_Panel")
    group
  end

  def self.build_adjustable_shelf(parent_ents, name, width, depth, z_pos, mats, is_glass: false, setback_mm: 20.0)
    group = parent_ents.add_group
    group.name = name

    inner_w = width - (2 * BOARD_THK)
    shelf_w = inner_w - 1.0.mm
    shelf_d = depth - setback_mm.mm - (BOARD_THK + BACK_THK)
    sh_x    = BOARD_THK + 0.5.mm
    sh_y    = -depth + setback_mm.mm

    shelf_thk = is_glass ? 8.0.mm : BOARD_THK
    mat = is_glass ? mats[:glass] : mats[:carcase]
    create_box(group.entities, [sh_x, sh_y, z_pos], [shelf_w, shelf_d, shelf_thk], mat, is_glass ? "Glass_Shelf_Slab" : "Wood_Shelf_Slab")
    group
  end

  def self.create_machined_gola_gable(entities, origin_x, base_depth, z_origin, height, material, name = "Gable_Machined_Gola")
    group = entities.add_group
    group.name = name

    pts = [
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

    face = group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.x < 0
      face.pushpull(BOARD_THK)
    end
    group.material = material if material
    group
  end

  # ----------------------------------------------------------------------------
  # 2. SCILM GOLA PROFILES
  # ----------------------------------------------------------------------------
  def self.build_gola_profile(parent_ents, profile_type, length, origin, mats)
    group = parent_ents.add_group
    group.name = "Gola_Profile_#{profile_type.to_s.upcase}_#{length.to_mm.round}mm"
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

    pts = yz.map { |y, z| Geom::Point3d.new(ox, oy - (GOLA_PROFILE_D - y), oz + z) }
    face = group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.x < 0
      face.pushpull(length)
    end

    group.material = mats[:gola]
    group
  end

  # ----------------------------------------------------------------------------
  # 3. GLOBAL DRAWER FUNCTION: HETTICH ACTRO 5D WITH GOLA EXTENDED LIP
  # ----------------------------------------------------------------------------
  def self.build_hettich_undermount_drawer(parent_ents, inner_origin, inner_w, depth, box_height, front_h, pull_offset, mats, front_mat, is_sink_u_shape: false, front_w: nil, box_z_offset: 20.0)
    drawer_unit = parent_ents.add_group
    drawer_unit.name = "Hettich_Undermount_Drawer_#{inner_w.to_mm.round}x#{front_h.to_mm.round}"

    dims = CabinetrixCollisionEngine.calculate_drawer_geometry(inner_w.to_mm, depth.to_mm, side_gap: 12.5, box_thk: 15.0, front_h: front_h.to_mm)
    box_w = dims[:box_w].mm
    box_d = dims[:box_d].mm
    box_h = [box_height, dims[:box_h].mm].min
    box_thk = dims[:box_thk].mm
    f_w = front_w || (inner_w + (2 * BOARD_THK) - 3.mm)

    ox = inner_origin.x
    base_y = inner_origin.y
    oy = base_y - pull_offset
    oz = inner_origin.z

    # 1. Gola Extended Front Slab
    create_box(drawer_unit.entities, [ox - BOARD_THK + 1.5.mm, oy - FRONT_THK, oz], [f_w, FRONT_THK, front_h], front_mat, "Drawer_Front_Face")

    # 2. Moving Drawer Box
    box_ox = ox + 12.5.mm
    box_oz = [oz + 15.0.mm, box_z_offset.mm].max
    box_oy = oy + 60.0.mm

    create_box(drawer_unit.entities, [box_ox, box_oy, box_oz], [box_thk, box_d, box_h], mats[:wood], "Drawer_Side_LH")
    create_box(drawer_unit.entities, [box_ox + box_w - box_thk, box_oy, box_oz], [box_thk, box_d, box_h], mats[:wood], "Drawer_Side_RH")
    sub_w = box_w - (2 * box_thk)

    if is_sink_u_shape
      cutout_w = 260.mm
      side_pocket_w = (sub_w - cutout_w) / 2.0
      cutout_d = 280.mm
      create_box(drawer_unit.entities, [box_ox + box_thk, box_oy, box_oz], [side_pocket_w, box_thk, box_h], mats[:wood], "Drawer_Sub_Front_LH")
      create_box(drawer_unit.entities, [box_ox + box_w - box_thk - side_pocket_w, box_oy, box_oz], [side_pocket_w, box_thk, box_h], mats[:wood], "Drawer_Sub_Front_RH")
      create_box(drawer_unit.entities, [box_ox + box_thk + side_pocket_w, box_oy, box_oz], [box_thk, cutout_d, box_h], mats[:wood], "Plumbing_Notch_LH")
      create_box(drawer_unit.entities, [box_ox + box_w - box_thk - side_pocket_w - box_thk, box_oy, box_oz], [box_thk, cutout_d, box_h], mats[:wood], "Plumbing_Notch_RH")
      create_box(drawer_unit.entities, [box_ox + box_thk + side_pocket_w, box_oy + cutout_d, box_oz], [cutout_w, box_thk, box_h], mats[:wood], "Plumbing_Notch_Back")
      create_box(drawer_unit.entities, [box_ox + box_thk, box_oy + box_d - box_thk, box_oz], [sub_w, box_thk, box_h], mats[:wood], "Drawer_Back_Panel")
    else
      create_box(drawer_unit.entities, [box_ox + box_thk, box_oy, box_oz], [sub_w, box_thk, box_h], mats[:wood], "Drawer_Sub_Front")
      create_box(drawer_unit.entities, [box_ox + box_thk, box_oy + box_d - box_thk, box_oz], [sub_w, box_thk, box_h], mats[:wood], "Drawer_Back_Panel")
      create_box(drawer_unit.entities, [box_ox + box_thk, box_oy + box_thk, box_oz + 12.mm], [sub_w, box_d - 2*box_thk, 16.0.mm], mats[:wood], "Drawer_Bottom_Panel")
    end

    runner_w = 11.0.mm
    runner_h = 24.0.mm
    fixed_slide_y = base_y + 40.mm
    create_box(drawer_unit.entities, [ox + 1.0.mm, fixed_slide_y, box_oz - 12.mm], [runner_w, box_d, runner_h], mats[:steel], "Hettich_Actro5D_Slide_LH")
    create_box(drawer_unit.entities, [ox + inner_w - runner_w - 1.0.mm, fixed_slide_y, box_oz - 12.mm], [runner_w, box_d, runner_h], mats[:steel], "Hettich_Actro5D_Slide_RH")

    drawer_unit
  end

  # ----------------------------------------------------------------------------
  # 4. AUTHENTIC 45° MITERED HOLLOW ALUMINUM SASH DOOR (ALU SYS)
  # ----------------------------------------------------------------------------
  def self.create_sash_bar(parent_ents, bar_length, alu_mat, hole_mat, is_hinged = false)
    group = parent_ents.add_group
    group.material = alu_mat

    outer = [
      [21.2, 0], [0, 0], [0, 10], [3.5, 10], [3.5, 8.5],
      [1.5, 8.5], [1.5, 1.5], [5.0, 1.5], [5.0, 45], [21.2, 45]
    ].reverse
    inner = [[6.5, 1.5], [19.7, 1.5], [19.7, 43.5], [6.5, 43.5]].reverse

    start_outer = outer.map { |y, z| Geom::Point3d.new(z.mm, y.mm, z.mm) }
    end_outer   = outer.map { |y, z| Geom::Point3d.new(bar_length - z.mm, y.mm, z.mm) }
    start_inner = inner.map { |y, z| Geom::Point3d.new(z.mm, y.mm, z.mm) }
    end_inner   = inner.map { |y, z| Geom::Point3d.new(bar_length - z.mm, y.mm, z.mm) }

    start_face = group.entities.add_face(start_outer)
    start_hole = group.entities.add_face(start_inner)
    start_hole.erase! if start_hole && start_hole.valid?
    end_face   = group.entities.add_face(end_outer)
    end_hole   = group.entities.add_face(end_inner)
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
      [100.mm, bar_length - 100.mm].each do |hinge_x|
        marker = group.entities.add_group
        marker.material = hole_mat
        circle = marker.entities.add_circle(Geom::Point3d.new(hinge_x, 21.2.mm, 22.5.mm), Geom::Vector3d.new(0, 1, 0), 17.5.mm, 24)
        face = marker.entities.add_face(circle)
        face.pushpull(-13.mm) if face
      end
    end

    group
  end

  def self.build_senior_sash_door(parent_ents, ox, oy, oz, door_w, door_h, mats, is_left_hinged: true, open_angle_deg: 0.0)
    group = parent_ents.add_group
    group.name = "Alu_Sash_Door_#{door_w.to_mm.round}x#{door_h.to_mm.round}"
    sub = group.entities
    transform = Geom::Transformation.translation([ox, oy, oz])

    alu_mat   = mats[:gola]
    glass_mat = mats[:glass]
    hole_mat  = mats[:hole] || mats[:steel]

    # Bottom Rail
    bottom = create_sash_bar(sub, door_w, alu_mat, hole_mat, false)
    bottom.transform!(transform)

    # Top Rail (Flipped 45° miter)
    top = create_sash_bar(sub, door_w, alu_mat, hole_mat, false)
    top.transform!(Geom::Transformation.scaling(1, 1, -1))
    top.transform!(Geom::Transformation.translation([0, 0, door_h]))
    top.transform!(transform)

    # Left Stile (Rotated 90°)
    left = create_sash_bar(sub, door_h, alu_mat, hole_mat, is_left_hinged)
    left.transform!(Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], -90.degrees))
    left.transform!(Geom::Transformation.scaling(-1, 1, 1))
    left.transform!(transform)

    # Right Stile (Rotated 90°)
    right = create_sash_bar(sub, door_h, alu_mat, hole_mat, !is_left_hinged)
    right.transform!(Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], -90.degrees))
    right.transform!(Geom::Transformation.translation([door_w, 0, 0]))
    right.transform!(transform)

    # Infill Smoked Glass Pane (Inside Gasket Channel)
    pane = sub.add_group
    pane.material = glass_mat
    pane_face = pane.entities.add_face(
      [10.mm, 1.75.mm, 10.mm],
      [door_w - 10.mm, 1.75.mm, 10.mm],
      [door_w - 10.mm, 5.75.mm, 10.mm],
      [10.mm, 5.75.mm, 10.mm]
    )
    pane_face.pushpull(door_h - 20.mm) if pane_face
    pane.transform!(transform)

    if open_angle_deg != 0.0
      pivot_pt = is_left_hinged ? Geom::Point3d.new(ox, oy, oz) : Geom::Point3d.new(ox + door_w, oy, oz)
      rot_angle = is_left_hinged ? -open_angle_deg.degrees : open_angle_deg.degrees
      rot_tr = Geom::Transformation.rotation(pivot_pt, Geom::Vector3d.new(0, 0, 1), rot_angle)
      group.transform!(rot_tr)
    end

    group
  end

  # ----------------------------------------------------------------------------
  # 5. AUTHENTIC BLUM AVENTOS HF BI-FOLD LIFT MECHANISM & 2-SECTION DOORS
  # ----------------------------------------------------------------------------
  def self.build_blum_aventos_hf_bi_fold_doors(parent_ents, bx, by, bz, width, height, depth, mats, front_mat, mode: :closed)
    lift_group = parent_ents.add_group
    lift_group.name = "Blum_AVENTOS_HF_BiFold_Lift_System"

    inner_w = width - (2 * BOARD_THK)
    door_w  = width - 3.0.mm
    total_door_h = height - 4.0.mm
    mid_gap = 3.0.mm
    door_h  = (total_door_h - mid_gap) / 2.0 # 356.5mm each

    front_y = by - depth - 21.2.mm

    # 1. BLUM AVENTOS HF POWER FACTOR DRIVE UNITS (Inside LH & RH Gables)
    unit_w = 30.0.mm
    unit_d = 180.0.mm
    unit_h = 135.0.mm
    mech_z = bz + height - unit_h - 20.0.mm
    mech_y = by - 160.0.mm

    # LH Power Factor Drive Unit
    create_box(lift_group.entities, [bx + BOARD_THK + 1.mm, mech_y, mech_z], [unit_w, unit_d, unit_h], mats[:steel], "Blum_AVENTOS_HF_DriveUnit_LH")
    # RH Power Factor Drive Unit
    create_box(lift_group.entities, [bx + width - BOARD_THK - unit_w - 1.mm, mech_y, mech_z], [unit_w, unit_d, unit_h], mats[:steel], "Blum_AVENTOS_HF_DriveUnit_RH")

    # 2. TELESCOPIC STEEL LIFT ARMS (LH & RH)
    arm_thick = 10.0.mm
    arm_w     = 18.0.mm
    arm_len   = 280.0.mm
    
    # LH Telescopic Lift Arm (Connecting Drive Unit to Lower Bi-Fold Door Bracket)
    create_box(lift_group.entities, [bx + BOARD_THK + unit_w + 2.mm, by - depth + 20.mm, bz + 180.mm], [arm_thick, depth - 180.mm, arm_w], mats[:steel], "Blum_AVENTOS_Telescopic_Arm_LH")
    create_box(lift_group.entities, [bx + BOARD_THK + unit_w + 2.mm, by - depth - 5.mm, bz + 170.mm], [16.mm, 20.mm, 40.mm], mats[:steel], "Front_Fixing_Bracket_LH")

    # RH Telescopic Lift Arm
    create_box(lift_group.entities, [bx + width - BOARD_THK - unit_w - arm_thick - 2.mm, by - depth + 20.mm, bz + 180.mm], [arm_thick, depth - 180.mm, arm_w], mats[:steel], "Blum_AVENTOS_Telescopic_Arm_RH")
    create_box(lift_group.entities, [bx + width - BOARD_THK - unit_w - arm_thick - 2.mm, by - depth - 5.mm, bz + 170.mm], [16.mm, 20.mm, 40.mm], mats[:steel], "Front_Fixing_Bracket_RH")

    # 3. INTERMEDIATE BI-FOLD HINGES (At the horizontal seam between upper & lower doors)
    [bx + 120.mm, bx + width - 150.mm].each_with_index do |hx, h_idx|
      create_box(lift_group.entities, [hx, by - depth - 5.mm, bz + door_h + 1.5.mm - 15.mm], [30.mm, 15.mm, 30.mm], mats[:steel], "Blum_Intermediate_Hinge_#{h_idx+1}")
      create_box(lift_group.entities, [hx, by - depth - 5.mm, bz + height - 20.mm], [30.mm, 15.mm, 20.mm], mats[:steel], "Blum_CLIP_Top_120_Hinge_#{h_idx+1}")
    end

    # 4. TWO-SECTION BI-FOLD DOORS (Upper Section + Lower Section)
    upper_z = bz + door_h + mid_gap + 2.0.mm
    lower_z = bz + 2.0.mm

    upper_door = build_senior_sash_door(lift_group.entities, bx + 1.5.mm, front_y, upper_z, door_w, door_h, mats, is_left_hinged: false)
    upper_door.name = "AVENTOS_HF_Upper_BiFold_Door_Section"

    lower_door = build_senior_sash_door(lift_group.entities, bx + 1.5.mm, front_y, lower_z, door_w, door_h, mats, is_left_hinged: false)
    lower_door.name = "AVENTOS_HF_Lower_BiFold_Door_Section"

    lift_group
  end

  # ----------------------------------------------------------------------------
  # 6. UNIVERSAL BOX CREATION API (LOCAL COORDINATES -> RIGID WORLD TRANSFORM)
  # ----------------------------------------------------------------------------
  def self.create_cabinet(parent_ents, type, params, location, mats)
    name = params[:name] || "Cabinet_#{type.to_s.upcase}"
    box_grp = parent_ents.add_group
    box_grp.name = name

    bx = 0.0.mm
    by = 0.0.mm
    bz = 0.0.mm

    width  = params[:width] || 600.mm
    height = params[:height] || (type.to_s.start_with?('tall') ? TALL_CARCASE_H : (type.to_s.start_with?('wall') || type.to_s.start_with?('open') ? WALL_CARCASE_H : (type.to_s.start_with?('top_bulkhead') ? 360.mm : BASE_CARCASE_H)))
    depth  = params[:depth]  || (type.to_s.start_with?('tall') ? TALL_DEPTH : (type.to_s.start_with?('wall') || type.to_s.start_with?('open') || type.to_s.start_with?('top_bulkhead') ? WALL_DEPTH : BASE_DEPTH))
    mode   = params[:mode]   || :closed
    front_mat = params[:front_mat] || mats[:front_dark]
    include_gola = (params[:include_gola] != false)
    inner_w = width - (2 * BOARD_THK)

    case type
    # ==========================================================================
    # CORNER BASE CABINETS — EXACT SHOTGUN BLIND CORNER IMPLEMENTATION
    # ==========================================================================
    when :base_blind_corner, :base_lemans_corner, :base_magic_corner, :base_corner_shelf
      blind_width = 600.0.mm
      door_width  = width - blind_width
      upright_x   = door_width

      # 1. Carcase
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      # 2. Dual Top Stretchers
      create_box(box_grp.entities, [bx + BOARD_THK, by - depth + GOLA_DEPTH, bz + height - BOARD_THK], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Front_Stretcher")
      create_box(box_grp.entities, [bx + BOARD_THK, by - 80.mm, bz + height - BOARD_THK], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Rear_Stretcher")

      # 3. Upright Door Support Baffle (18mm x 100mm)
      create_box(box_grp.entities, [bx + upright_x - BOARD_THK/2.0, by - depth, bz + BOARD_THK], [BOARD_THK, 100.mm, height - 3*BOARD_THK], mats[:carcase], "Corner_Door_Support_Upright")

      # 4. Shotgun 1-Piece Front-Notched Shelf with CNC U-Notch around Upright
      notch_w = BOARD_THK + 2.0.mm
      notch_d = 100.0.mm
      notch_x = bx + upright_x - notch_w/2.0
      shelf_origin = [bx + BOARD_THK, by - depth, bz + height/2.0]
      shelf_size   = [inner_w, depth - BOARD_THK - BACK_THK, BOARD_THK]
      create_front_notched_shelf(box_grp.entities, "Corner_Mid_Shelf_With_Upright_Notch", shelf_origin, shelf_size, notch_x, notch_w, notch_d, mats[:carcase])

      # 5. Front Blind Panel & Accessible Working Door
      door_open_deg = (mode == :hybrid ? 95.0 : 0.0)
      door_grp = create_box(box_grp.entities, [bx + 3.mm, by - depth - FRONT_THK, bz + 3.mm], [door_width - 6.mm, FRONT_THK, height - 38.mm], front_mat, "Corner_Working_Door_Left")
      if door_open_deg > 0
        door_grp.transform!(Geom::Transformation.rotation(Geom::Point3d.new(bx + 3.mm, by - depth - FRONT_THK, bz), Geom::Vector3d.new(0, 0, 1), -door_open_deg.degrees))
      end
      create_box(box_grp.entities, [bx + door_width + 3.mm, by - depth - FRONT_THK, bz + 3.mm], [blind_width - 6.mm, FRONT_THK, height - 3.mm], front_mat, "Corner_Blind_Panel_Right")

    # ==========================================================================
    # TALL APPLIANCE & PANTRY TOWERS
    # ==========================================================================
    when :tall_oven_tower
      create_box(box_grp.entities, [bx, by - depth, 0], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, 0], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_structural_shelf(box_grp.entities, "Structural_Base_Datum_Shelf", width, depth, BASE_DATUM_Z - PLINTH_HEIGHT, mats)
      build_structural_shelf(box_grp.entities, "Upper_Appliance_Shelf", width, depth, BASE_DATUM_Z - PLINTH_HEIGHT + 885.mm, mats)
      build_structural_shelf(box_grp.entities, "Roof_Panel", width, depth, height - BOARD_THK, mats, full_depth_to_wall: true)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, height, mats, has_mid_cleat: true, mid_cleat_z: BASE_DATUM_Z - PLINTH_HEIGHT)

      oven = create_box(box_grp.entities, [bx + BOARD_THK + 5.mm, by - depth - 20.mm, BASE_DATUM_Z - PLINTH_HEIGHT + BOARD_THK + 5.mm], [inner_w - 10.mm, depth - 20.mm, 875.mm], mats[:steel], "Double_Oven_Appliance")
      create_box(oven.entities, [bx + BOARD_THK + 15.mm, by - depth - 25.mm, BASE_DATUM_Z - PLINTH_HEIGHT + 25.mm], [inner_w - 30.mm, 5.mm, 410.mm], mats[:glass], "Oven_Lower_Glass")
      create_box(oven.entities, [bx + BOARD_THK + 15.mm, by - depth - 25.mm, BASE_DATUM_Z - PLINTH_HEIGHT + 465.mm], [inner_w - 30.mm, 5.mm, 410.mm], mats[:glass], "Oven_Upper_Glass")

      upper_door_h = height - (BASE_DATUM_Z - PLINTH_HEIGHT + 885.mm + BOARD_THK) - 6.mm
      create_box(box_grp.entities, [bx + 1.5.mm, by - depth - FRONT_THK, BASE_DATUM_Z - PLINTH_HEIGHT + 885.mm + BOARD_THK + 3.mm], [width - 3.mm, FRONT_THK, upper_door_h], front_mat, "Upper_Cupboard_Door")
      build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, by - depth, bz + 12.mm), inner_w, depth, 200.mm, 355.mm, 0.mm, mats, front_mat)
      build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, by - depth, bz + 380.mm), inner_w, depth, 200.mm, 335.mm, (mode == :hybrid ? 250.mm : 0.mm), mats, front_mat)

    when :tall_pantry_larder, :tall_space_tower
      create_box(box_grp.entities, [bx, by - depth, 0], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, 0], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_structural_shelf(box_grp.entities, "Larder_Mid_Structural_Shelf", width, depth, 1200.mm, mats)
      build_structural_shelf(box_grp.entities, "Roof_Panel", width, depth, height - BOARD_THK, mats, full_depth_to_wall: true)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, height, mats, has_mid_cleat: true, mid_cleat_z: 1200.mm)

      drawer_pull = (mode == :hybrid ? 300.mm : 0.mm)
      [bz + 20.mm, bz + 230.mm, bz + 440.mm, bz + 650.mm, bz + 860.mm].each_with_index do |dz, i|
        pull_dist = (i == 1) ? drawer_pull : 0.mm
        d_box = build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, by - depth, dz), inner_w, depth, 140.mm, 160.mm, pull_dist, mats, mats[:carcase], front_w: (inner_w - 3.mm))
      end

      build_adjustable_shelf(box_grp.entities, "Adjustable_Shelf_1", width, depth, 1200.mm + BOARD_THK + 250.mm, mats)
      build_adjustable_shelf(box_grp.entities, "Adjustable_Shelf_2", width, depth, 1200.mm + BOARD_THK + 550.mm, mats)
      
      door_open_deg = (mode == :hybrid ? 95.0 : 0.0)
      build_senior_sash_door(box_grp.entities, bx + 1.5.mm, by - depth - 21.2.mm, bz, width - 3.mm, height - bz - 3.mm, mats, is_left_hinged: true, open_angle_deg: door_open_deg)

    # ==========================================================================
    # BASE & ISLAND UNITS (WITH AUTHENTIC GOLA BEVELED EXTENDED FRONTS)
    # ==========================================================================
    when :base_gola_drawers, :base_gola_cooktop, :base_gola_sink, :base_gola_spice, :base_gola_wine, :island_gola_drawers, :island_gola_sink
      stretcher_z = bz + height - BOARD_THK
      front_w = width - 3.mm
      front_y = by - depth

      create_machined_gola_gable(box_grp.entities, bx, depth, bz, height, mats[:carcase], "Gable_LH")
      create_machined_gola_gable(box_grp.entities, bx + width - BOARD_THK, depth, bz, height, mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      # 1. TOP FRONT STRETCHER (Behind L-Gola)
      front_sub_y = -depth + GOLA_DEPTH
      create_box(box_grp.entities, [bx + BOARD_THK, front_sub_y, stretcher_z], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Front_Gola_Stretcher")

      # 2. TOP REAR STRETCHER (Benchtop Support)
      rear_stretcher_y = by - 80.mm
      create_box(box_grp.entities, [bx + BOARD_THK, rear_stretcher_y, stretcher_z], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Rear_Gola_Stretcher")

      # 3. MID C-GOLA SUB-STRETCHER
      mid_sub_z = bz + C_GOLA_Z0 - BOARD_THK
      create_box(box_grp.entities, [bx + BOARD_THK, front_sub_y, mid_sub_z], [inner_w, 60.mm, BOARD_THK], mats[:carcase], "Mid_C_Gola_Under_Stretcher")

      if include_gola
        build_gola_profile(box_grp.entities, :l, width, Geom::Point3d.new(bx, -depth + GOLA_DEPTH, bz + height - L_GOLA_H), mats)
        build_gola_profile(box_grp.entities, :c, width, Geom::Point3d.new(bx, -depth + GOLA_DEPTH, bz + C_GOLA_Z0), mats)
      end

      pull_offset_lower = (mode == :hybrid ? 280.mm : 0.mm)
      pull_offset_upper = (mode == :hybrid ? 180.mm : 0.mm)

      case type
      when :base_gola_drawers, :island_gola_drawers
        build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, front_y, bz + LOWER_DRAWER_Z), inner_w, depth, 200.mm, LOWER_FRONT_H, pull_offset_lower, mats, front_mat, box_z_offset: 24.0)
        build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, front_y, bz + UPPER_DRAWER_Z), inner_w, depth, 120.mm, UPPER_FRONT_H, pull_offset_upper, mats, front_mat, box_z_offset: 416.0)

      when :base_gola_cooktop
        build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, front_y, bz + LOWER_DRAWER_Z), inner_w, depth, 200.mm, LOWER_FRONT_H, (mode == :hybrid ? 320.mm : 0.mm), mats, front_mat, box_z_offset: 24.0)
        build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, front_y, bz + UPPER_DRAWER_Z), inner_w, depth, 120.mm, UPPER_FRONT_H, (mode == :hybrid ? 200.mm : 0.mm), mats, front_mat, box_z_offset: 416.0)

      when :base_gola_sink, :island_gola_sink
        create_box(box_grp.entities, [bx + 1.5.mm, front_y - FRONT_THK, bz + UPPER_DRAWER_Z], [front_w, FRONT_THK, UPPER_FRONT_H], front_mat, "Sink_False_Front")
        build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, front_y, bz + LOWER_DRAWER_Z), inner_w, depth, 200.mm, LOWER_FRONT_H, (mode == :hybrid ? 300.mm : 0.mm), mats, front_mat, box_z_offset: 24.0)
        create_box(box_grp.entities, [bx + 30.mm, front_y + 250.mm, bz + 30.mm], [240.mm, 200.mm, 280.mm], mats[:cam], "Cargo_Waste_Bin_1")
        create_box(box_grp.entities, [bx + width - 270.mm, front_y + 250.mm, bz + 30.mm], [240.mm, 200.mm, 280.mm], mats[:gola], "Cargo_Waste_Bin_2")

      when :base_gola_spice
        create_box(box_grp.entities, [bx + 1.5.mm, front_y - FRONT_THK, bz + 3.mm], [front_w, FRONT_THK, height - 38.mm], front_mat, "Spice_Pullout_Front")
        create_box(box_grp.entities, [bx + 20.mm, front_y + 20.mm, bz + 30.mm], [width - 40.mm, depth - 50.mm, 580.mm], mats[:steel], "Chrome_2Tier_Wire_Basket")

      when :base_gola_wine
        create_box(box_grp.entities, [bx + 1.5.mm, front_y - FRONT_THK, bz + LOWER_DRAWER_Z], [front_w, FRONT_THK, LOWER_FRONT_H], front_mat, "Lower_Front")
        create_box(box_grp.entities, [bx + 1.5.mm, front_y - FRONT_THK, bz + UPPER_DRAWER_Z], [front_w, FRONT_THK, UPPER_FRONT_H], front_mat, "Upper_Front")
      end

    # ==========================================================================
    # WALL & BULKHEAD UNITS
    # ==========================================================================
    when :wall_lift_aventos
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Top_Panel", width, depth, bz + height - BOARD_THK, mats, full_depth_to_wall: true)
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      # 50mm Setback Shelf to clear telescopic lift arms
      build_adjustable_shelf(box_grp.entities, "AVENTOS_Setback_Shelf", width, depth, bz + 360.mm, mats, setback_mm: 50.0)

      # AUTHENTIC BLUM AVENTOS HF BI-FOLD LIFT MECHANISM & DUAL HORIZONTAL DOORS
      build_blum_aventos_hf_bi_fold_doors(box_grp.entities, bx, by, bz, width, height, depth, mats, front_mat, mode: mode)

    when :wall_glass_display
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Top_Panel", width, depth, bz + height - BOARD_THK, mats, full_depth_to_wall: true)
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      build_adjustable_shelf(box_grp.entities, "Glass_Shelf_1", width, depth, bz + 240.mm, mats, is_glass: true)
      build_adjustable_shelf(box_grp.entities, "Glass_Shelf_2", width, depth, bz + 480.mm, mats, is_glass: true)
      
      door_h = height + BOARD_THK
      door_z = bz - BOARD_THK
      is_left = params[:is_left_hinged] != false
      build_senior_sash_door(box_grp.entities, bx + 1.5.mm, by - depth - 21.2.mm, door_z, width - 3.mm, door_h, mats, is_left_hinged: is_left)

    when :wall_cooker_hood
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Top_Panel", width, depth, bz + height - BOARD_THK, mats, full_depth_to_wall: true)
      build_structural_shelf(box_grp.entities, "Hood_Chamber_Shelf", width, depth, bz + 160.mm, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz + 160.mm, bz + height, mats)

      create_box(box_grp.entities, [bx + 10.mm, by - depth + 10.mm, bz], [width - 20.mm, depth - 20.mm, 150.mm], mats[:steel], "Extractor_Hood_Body")
      hood_door_h = height - 160.mm - 3.mm
      create_box(box_grp.entities, [bx + 1.5.mm, by - depth - FRONT_THK, bz + 160.mm + 3.mm], [width - 3.mm, FRONT_THK, hood_door_h], front_mat, "Upper_Hood_Door")

    when :top_bulkhead_flap, :deep_top_bulkhead
      bulkhead_h = params[:height] || 360.mm
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, bulkhead_h], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, bulkhead_h], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Top_Panel", width, depth, bz + bulkhead_h - BOARD_THK, mats, full_depth_to_wall: true)
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + bulkhead_h, mats)

      create_box(box_grp.entities, [bx + 1.5.mm, by - depth - FRONT_THK, bz + 1.5.mm], [width - 3.mm, FRONT_THK, bulkhead_h - 3.mm], front_mat, "Bulkhead_Flap_Door")

    when :open_rack_metal
      metal_mat = mats[:gola]
      oak_mat   = mats[:wood]
      frame_t   = 20.mm

      create_box(box_grp.entities, [bx, by - depth, bz], [frame_t, frame_t, height], metal_mat, "Metal_Upright_FL")
      create_box(box_grp.entities, [bx + width - frame_t, by - depth, bz], [frame_t, frame_t, height], metal_mat, "Metal_Upright_FR")
      create_box(box_grp.entities, [bx, by - frame_t, bz], [frame_t, frame_t, height], metal_mat, "Metal_Upright_RL")
      create_box(box_grp.entities, [bx + width - frame_t, by - frame_t, bz], [frame_t, frame_t, height], metal_mat, "Metal_Upright_RR")

      [bz, bz + height/2.0 - frame_t/2.0, bz + height - frame_t].each_with_index do |rz, idx|
        create_box(box_grp.entities, [bx + frame_t, by - depth, rz], [width - 2*frame_t, frame_t, frame_t], metal_mat, "Cross_Bar_Front_#{idx+1}")
        create_box(box_grp.entities, [bx + frame_t, by - frame_t, rz], [width - 2*frame_t, frame_t, frame_t], metal_mat, "Cross_Bar_Rear_#{idx+1}")
        create_box(box_grp.entities, [bx, by - depth + frame_t, rz], [frame_t, depth - 2*frame_t, frame_t], metal_mat, "Cross_Bar_Left_#{idx+1}")
        create_box(box_grp.entities, [bx + width - frame_t, by - depth + frame_t, rz], [frame_t, depth - 2*frame_t, frame_t], metal_mat, "Cross_Bar_Right_#{idx+1}")
      end

      create_box(box_grp.entities, [bx + 25.mm, by - depth + 25.mm, bz + 20.mm], [width - 50.mm, depth - 50.mm, 18.mm], oak_mat, "Oak_Display_Shelf_Lower")
      create_box(box_grp.entities, [bx + 25.mm, by - depth + 25.mm, bz + height/2.0 + 10.mm], [width - 50.mm, depth - 50.mm, 18.mm], oak_mat, "Oak_Display_Shelf_Upper")

    when :open_wine_grid
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Top_Panel", width, depth, bz + height - BOARD_THK, mats, full_depth_to_wall: true)
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      num_cols = 3
      col_w = inner_w / num_cols
      (1...num_cols).each do |c|
        create_box(box_grp.entities, [bx + BOARD_THK + (c * col_w) - 6.mm, by - depth + 20.mm, bz + BOARD_THK], [12.mm, depth - 30.mm, height - 2*BOARD_THK], mats[:wood], "Wine_Divider_V#{c}")
      end
      num_rows = 4
      row_h = (height - 2*BOARD_THK) / num_rows
      (1...num_rows).each do |r|
        create_box(box_grp.entities, [bx + BOARD_THK, by - depth + 20.mm, bz + BOARD_THK + (r * row_h) - 6.mm], [inner_w, depth - 30.mm, 12.mm], mats[:wood], "Wine_Divider_H#{r}")
      end
    end

    # --------------------------------------------------------------------------
    # 7. RIGID WORLD TRANSFORMATION
    # --------------------------------------------------------------------------
    rot_deg = location[:rotation_deg] || params[:rotation_deg] || 0.0
    tr_rot = Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0), Geom::Vector3d.new(0, 0, 1), rot_deg.degrees)
    tr_pos = Geom::Transformation.translation(Geom::Vector3d.new(location[:x] || 0.mm, location[:y] || 0.mm, location[:z] || PLINTH_HEIGHT))
    box_grp.transform!(tr_pos * tr_rot)

    box_grp
  end

  # ----------------------------------------------------------------------------
  # 8. COMPLETE PHYSICAL BOARDS EXTRACTION API
  # ----------------------------------------------------------------------------
  def self.extract_panels_for_cabinet(cab_type, width_mm, height_mm, depth_mm, cab_tag)
    thk = 18.0
    inner_w = width_mm - 2*thk
    panels = []

    panels << { part_id: "#{cab_tag}-GLH", cab_id: cab_tag, name: "Gable_LH", length: height_mm, width: depth_mm, thk: thk, material: "18mm White MFC", grain: :length, eb_l1: "1.0mm ABS", eb_l2: "-", eb_w1: "0.4mm", eb_w2: "0.4mm", has_cnc: true }
    panels << { part_id: "#{cab_tag}-GRH", cab_id: cab_tag, name: "Gable_RH", length: height_mm, width: depth_mm, thk: thk, material: "18mm White MFC", grain: :length, eb_l1: "1.0mm ABS", eb_l2: "-", eb_w1: "0.4mm", eb_w2: "0.4mm", has_cnc: true }
    panels << { part_id: "#{cab_tag}-BOT", cab_id: cab_tag, name: "Bottom_Panel", length: inner_w, width: depth_mm, thk: thk, material: "18mm White MFC", grain: :none, eb_l1: "1.0mm ABS", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }

    if cab_type.to_s.start_with?('base') || cab_type.to_s.start_with?('island') || cab_type.to_s.include?('corner')
      panels << { part_id: "#{cab_tag}-STR-F", cab_id: cab_tag, name: "Top_Front_Stretcher", length: inner_w, width: 80.0, thk: thk, material: "18mm White MFC", grain: :length, eb_l1: "0.4mm", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
      panels << { part_id: "#{cab_tag}-STR-R", cab_id: cab_tag, name: "Top_Rear_Stretcher", length: inner_w, width: 80.0, thk: thk, material: "18mm White MFC", grain: :length, eb_l1: "0.4mm", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
      panels << { part_id: "#{cab_tag}-STR-M", cab_id: cab_tag, name: "Mid_C_Gola_Stretcher", length: inner_w, width: 60.0, thk: thk, material: "18mm White MFC", grain: :length, eb_l1: "0.4mm", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
    else
      panels << { part_id: "#{cab_tag}-TOP", cab_id: cab_tag, name: "Roof_Panel", length: inner_w, width: depth_mm, thk: thk, material: "18mm White MFC", grain: :none, eb_l1: "1.0mm ABS", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
    end

    panels << { part_id: "#{cab_tag}-CLT-T", cab_id: cab_tag, name: "Rear_Top_Cleat", length: inner_w, width: 100.0, thk: thk, material: "18mm White MFC", grain: :length, eb_l1: "-", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: false }
    panels << { part_id: "#{cab_tag}-CLT-B", cab_id: cab_tag, name: "Rear_Bottom_Cleat", length: inner_w, width: 100.0, thk: thk, material: "18mm White MFC", grain: :length, eb_l1: "-", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: false }
    panels << { part_id: "#{cab_tag}-BAK", cab_id: cab_tag, name: "Back_Panel_Sheet", length: inner_w + 10.0, width: height_mm - 26.0, thk: 6.0, material: "6mm White Backing", grain: :length, eb_l1: "-", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: false }

    if cab_type.to_s.include?('drawer') || cab_type.to_s.include?('cooktop') || cab_type.to_s.include?('sink')
      dims = CabinetrixCollisionEngine.calculate_drawer_geometry(inner_w, depth_mm, side_gap: 12.5, box_thk: 15.0, front_h: 342.0)
      box_w = dims[:box_w]
      box_d = dims[:box_d]

      panels << { part_id: "#{cab_tag}-DW1-LH", cab_id: cab_tag, name: "Drawer_Box_LH_Lower", length: box_d, width: 200.0, thk: 15.0, material: "15mm Birch Plywood", grain: :length, eb_l1: "1.0mm Birch", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
      panels << { part_id: "#{cab_tag}-DW1-RH", cab_id: cab_tag, name: "Drawer_Box_RH_Lower", length: box_d, width: 200.0, thk: 15.0, material: "15mm Birch Plywood", grain: :length, eb_l1: "1.0mm Birch", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
      panels << { part_id: "#{cab_tag}-DW1-SF", cab_id: cab_tag, name: "Drawer_SubFront_Lower", length: box_w - 30.0, width: 200.0, thk: 15.0, material: "15mm Birch Plywood", grain: :length, eb_l1: "1.0mm Birch", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
      panels << { part_id: "#{cab_tag}-DW1-BK", cab_id: cab_tag, name: "Drawer_Back_Lower", length: box_w - 30.0, width: 200.0, thk: 15.0, material: "15mm Birch Plywood", grain: :length, eb_l1: "1.0mm Birch", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
      panels << { part_id: "#{cab_tag}-DW1-BM", cab_id: cab_tag, name: "Drawer_Bottom_Lower", length: box_w - 30.0, width: box_d - 30.0, thk: 16.0, material: "16mm Solid Birch Base", grain: :none, eb_l1: "-", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: false }
      panels << { part_id: "#{cab_tag}-FR1", cab_id: cab_tag, name: "Lower_Pot_Drawer_Front", length: width_mm - 3.0, width: 342.0, thk: 18.0, material: "18mm Anthracite Supermatte", grain: :length, eb_l1: "1.0mm ABS", eb_l2: "1.0mm ABS", eb_w1: "1.0mm ABS", eb_w2: "1.0mm ABS", has_cnc: false }

      panels << { part_id: "#{cab_tag}-DW2-LH", cab_id: cab_tag, name: "Drawer_Box_LH_Upper", length: box_d, width: 120.0, thk: 15.0, material: "15mm Birch Plywood", grain: :length, eb_l1: "1.0mm Birch", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
      panels << { part_id: "#{cab_tag}-DW2-RH", cab_id: cab_tag, name: "Drawer_Box_RH_Upper", length: box_d, width: 120.0, thk: 15.0, material: "15mm Birch Plywood", grain: :length, eb_l1: "1.0mm Birch", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
      panels << { part_id: "#{cab_tag}-DW2-SF", cab_id: cab_tag, name: "Drawer_SubFront_Upper", length: box_w - 30.0, width: 120.0, thk: 15.0, material: "15mm Birch Plywood", grain: :length, eb_l1: "1.0mm Birch", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
      panels << { part_id: "#{cab_tag}-DW2-BK", cab_id: cab_tag, name: "Drawer_Back_Upper", length: box_w - 30.0, width: 120.0, thk: 15.0, material: "15mm Birch Plywood", grain: :length, eb_l1: "1.0mm Birch", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: true }
      panels << { part_id: "#{cab_tag}-DW2-BM", cab_id: cab_tag, name: "Drawer_Bottom_Upper", length: box_w - 30.0, width: box_d - 30.0, thk: 16.0, material: "16mm Solid Birch Base", grain: :none, eb_l1: "-", eb_l2: "-", eb_w1: "-", eb_w2: "-", has_cnc: false }
      panels << { part_id: "#{cab_tag}-FR2", cab_id: cab_tag, name: "Upper_Drawer_Front", length: width_mm - 3.0, width: 285.0, thk: 18.0, material: "18mm Anthracite Supermatte", grain: :length, eb_l1: "1.0mm ABS", eb_l2: "1.0mm ABS", eb_w1: "1.0mm ABS", eb_w2: "1.0mm ABS", has_cnc: false }
    end

    panels
  end
end
