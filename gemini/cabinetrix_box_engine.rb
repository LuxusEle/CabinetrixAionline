# ==============================================================================
# CABINETRIX AI — UNIVERSAL PARAMETRIC BOX ENGINE (PRODUCTION STANDARD)
# File: gemini/cabinetrix_box_engine.rb
#
# Production Standard:
#   • ADJUSTABLE LEGS & CLIP-ON PLINTH SYSTEM (100mm CAMAR/VOLPATO STANDARD).
#   • BOTH HANDLED AND HANDLELESS (GOLA) BASE & DRAWER CABINETS.
#   • CONTEMPORARY BAR / EDGE HANDLES (HORIZONTAL ON DRAWERS, VERTICAL ON DOORS).
#   • AUTHENTIC CNC HALF-LAP FINGER JOINTS FOR WINE RACKS (SLOTTED COMB CUTOUTS).
#   • SPACE TOWER INSET DRAWERS SET BACK 25MM BEHIND DOOR LINE.
#   • FREE STOP DAMPING LIFT SYSTEM (IMAGE 5 REFERENCE).
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

  # Gola Finger-Pull Front Datums
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

  def self.create_cylinder(entities, center, normal, radius, height, material = nil, num_segments = 24)
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
  # 2. ADJUSTABLE LEGS & CLIP-ON PLINTH KICKBOARD SYSTEM
  # ----------------------------------------------------------------------------
  def self.build_adjustable_legs_and_plinth(parent_ents, bx, by, bz, width, depth, mats, include_plinth: true)
    legs_grp = parent_ents.add_group
    legs_grp.name = "Adjustable_Legs_And_Plinth_System"
    black_mat  = mats[:gola]
    plinth_mat = mats[:gola]

    leg_h = 100.0.mm
    leg_coords = [
      [bx + 60.mm, by - depth + 60.mm],
      [bx + width - 60.mm, by - depth + 60.mm],
      [bx + 60.mm, by - 60.mm],
      [bx + width - 60.mm, by - 60.mm]
    ]
    if width.to_mm >= 900.0
      leg_coords << [bx + width / 2.0, by - depth / 2.0]
    end

    leg_coords.each do |lx, ly|
      # Top mounting flange
      create_cylinder(legs_grp.entities, Geom::Point3d.new(lx, ly, bz), Geom::Vector3d.new(0, 0, -1), 38.mm, 5.mm, black_mat)
      # Main adjustable leg column
      create_cylinder(legs_grp.entities, Geom::Point3d.new(lx, ly, bz - 5.mm), Geom::Vector3d.new(0, 0, -1), 24.mm, leg_h - 15.mm, black_mat)
      # Leveling base foot
      create_cylinder(legs_grp.entities, Geom::Point3d.new(lx, ly, bz - leg_h + 10.mm), Geom::Vector3d.new(0, 0, -1), 28.mm, 10.mm, black_mat)
    end

    if include_plinth
      plinth_y = by - depth + 40.mm
      create_box(legs_grp.entities, [bx, plinth_y, bz - leg_h], [width, 18.mm, leg_h], plinth_mat, "ClipOn_Plinth_Kickboard")
    end

    legs_grp
  end

  # ----------------------------------------------------------------------------
  # 3. CONTEMPORARY BAR / EDGE HANDLES
  # ----------------------------------------------------------------------------
  def self.build_contemporary_bar_handle(parent_ents, center_pt, length_mm, orientation, mats)
    handle_grp = parent_ents.add_group
    handle_grp.name = "Contemporary_Bar_Handle_#{length_mm.to_i}mm"
    handle_mat = mats[:gola]

    cx, cy, cz = center_pt.x, center_pt.y, center_pt.z
    half_l = (length_mm / 2.0).mm
    pitch  = (length_mm - 32.0).mm / 2.0

    if orientation == :horizontal
      create_cylinder(handle_grp.entities, Geom::Point3d.new(cx - pitch, cy, cz), Geom::Vector3d.new(0, -1, 0), 5.mm, 25.mm, handle_mat)
      create_cylinder(handle_grp.entities, Geom::Point3d.new(cx + pitch, cy, cz), Geom::Vector3d.new(0, -1, 0), 5.mm, 25.mm, handle_mat)
      create_box(handle_grp.entities, [cx - half_l, cy - 28.mm, cz - 4.mm], [length_mm.mm, 6.mm, 8.mm], handle_mat, "Handle_Bar")
    else
      create_cylinder(handle_grp.entities, Geom::Point3d.new(cx, cy, cz - pitch), Geom::Vector3d.new(0, -1, 0), 5.mm, 25.mm, handle_mat)
      create_cylinder(handle_grp.entities, Geom::Point3d.new(cx, cy, cz + pitch), Geom::Vector3d.new(0, -1, 0), 5.mm, 25.mm, handle_mat)
      create_box(handle_grp.entities, [cx - 4.mm, cy - 28.mm, cz - half_l], [8.mm, 6.mm, length_mm.mm], handle_mat, "Handle_Bar")
    end

    handle_grp
  end

  # ----------------------------------------------------------------------------
  # 4. CNC SLOTTED COMB DIVIDER (AUTHENTIC HALF-LAP FINGER JOINTS)
  # ----------------------------------------------------------------------------
  def self.create_slotted_comb_panel(parent_ents, origin, length, width, thickness, slot_positions, slot_w, slot_d, mat, name)
    group = parent_ents.add_group
    group.name = name
    ox, oy, oz = origin

    pts = []
    pts << Geom::Point3d.new(ox, oy, oz)

    slot_positions.sort.each do |sp|
      s_start = sp - (slot_w / 2.0)
      s_end   = sp + (slot_w / 2.0)
      pts << Geom::Point3d.new(ox + s_start, oy, oz)
      pts << Geom::Point3d.new(ox + s_start, oy + slot_d, oz)
      pts << Geom::Point3d.new(ox + s_end, oy + slot_d, oz)
      pts << Geom::Point3d.new(ox + s_end, oy, oz)
    end

    pts << Geom::Point3d.new(ox + length, oy, oz)
    pts << Geom::Point3d.new(ox + length, oy + width, oz)
    pts << Geom::Point3d.new(ox, oy + width, oz)

    face = group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.z < 0
      face.pushpull(thickness)
    end
    group.material = mat if mat
    group
  end

  def self.build_interlocking_wine_grid(parent_ents, bx, by, bz, width, height, depth, mats, is_open_display: true)
    grid_group = parent_ents.add_group
    grid_group.name = "Interlocking_CNC_Finger_Joint_Wine_Grid"
    wood_mat = mats[:wood]

    inner_w = width - (2 * BOARD_THK)
    inner_h = height - (2 * BOARD_THK)
    grid_d  = depth - 30.0.mm
    thk     = 12.0.mm
    slot_w  = 12.5.mm
    slot_d  = grid_d / 2.0

    num_cols = 3
    num_rows = 4
    col_w = inner_w / num_cols
    row_h = inner_h / num_rows

    vert_slot_z_list = (1...num_rows).map { |r| r * row_h }
    horiz_slot_x_list = (1...num_cols).map { |c| c * col_w }

    (1...num_cols).each do |c|
      vx = bx + BOARD_THK + (c * col_w) - (thk / 2.0)
      v_grp = grid_group.entities.add_group
      v_grp.name = "CNC_Vertical_Comb_Divider_#{c}"
      
      pts = [
        Geom::Point3d.new(vx, by - depth + 20.mm, bz + BOARD_THK),
        Geom::Point3d.new(vx, by - depth + 20.mm + grid_d, bz + BOARD_THK)
      ]
      
      vert_slot_z_list.each do |sz|
        pts << Geom::Point3d.new(vx, by - depth + 20.mm + grid_d, bz + BOARD_THK + sz - slot_w/2.0)
        pts << Geom::Point3d.new(vx, by - depth + 20.mm + grid_d - slot_d, bz + BOARD_THK + sz - slot_w/2.0)
        pts << Geom::Point3d.new(vx, by - depth + 20.mm + grid_d - slot_d, bz + BOARD_THK + sz + slot_w/2.0)
        pts << Geom::Point3d.new(vx, by - depth + 20.mm + grid_d, bz + BOARD_THK + sz + slot_w/2.0)
      end

      pts << Geom::Point3d.new(vx, by - depth + 20.mm + grid_d, bz + BOARD_THK + inner_h)
      pts << Geom::Point3d.new(vx, by - depth + 20.mm, bz + BOARD_THK + inner_h)

      face = v_grp.entities.add_face(pts)
      if face
        face.reverse! if face.normal.x < 0
        face.pushpull(thk)
      end
      v_grp.material = wood_mat
    end

    (1...num_rows).each do |r|
      hz = bz + BOARD_THK + (r * row_h) - (thk / 2.0)
      create_slotted_comb_panel(grid_group.entities, [bx + BOARD_THK, by - depth + 20.mm, hz], inner_w, grid_d, thk, horiz_slot_x_list, slot_w, slot_d, wood_mat, "CNC_Horizontal_Comb_Divider_#{r}")
    end

    if is_open_display
      dis_group = grid_group.entities.add_group
      dis_group.name = "Disassembled_CNC_Finger_Joint_Laydown"
      dis_y = by - depth - 220.0.mm
      dis_z = -180.0.mm

      create_slotted_comb_panel(dis_group.entities, [bx + BOARD_THK, dis_y, dis_z], inner_w, grid_d, thk, horiz_slot_x_list, slot_w, slot_d, wood_mat, "CNC_Notched_Horizontal_Comb_Floor_Display")
      create_slotted_comb_panel(dis_group.entities, [bx + BOARD_THK + 20.mm, dis_y, dis_z - 80.mm], inner_h, grid_d, thk, vert_slot_z_list, slot_w, slot_d, wood_mat, "CNC_Notched_Vertical_Comb_Floor_Display")
    end

    grid_group
  end

  # ----------------------------------------------------------------------------
  # 5. KINEMATIC BLUM CONCEALED HINGES
  # ----------------------------------------------------------------------------
  def self.build_blum_carcase_plate(parent_ents, g_inside_x, door_back_y, hz, is_left_hinged, mats)
    plate_grp = parent_ents.add_group
    plate_grp.name = "Blum_Cruciform_Mounting_Plate"
    steel_mat = mats[:steel]

    if is_left_hinged
      create_box(plate_grp.entities, [g_inside_x, door_back_y + 21.mm, hz - 16.mm], [3.5.mm, 32.mm, 32.mm], steel_mat, "Mounting_Plate")
      create_cylinder(plate_grp.entities, Geom::Point3d.new(g_inside_x + 3.5.mm, door_back_y + 37.mm, hz + 16.mm), Geom::Vector3d.new(-1, 0, 0), 2.5.mm, 4.mm, steel_mat)
      create_cylinder(plate_grp.entities, Geom::Point3d.new(g_inside_x + 3.5.mm, door_back_y + 37.mm, hz - 16.mm), Geom::Vector3d.new(-1, 0, 0), 2.5.mm, 4.mm, steel_mat)
      create_box(plate_grp.entities, [g_inside_x, door_back_y + 2.mm, hz - 6.mm], [6.mm, 35.mm, 12.mm], steel_mat, "Hinge_Arm_Base")
    else
      create_box(plate_grp.entities, [g_inside_x - 3.5.mm, door_back_y + 21.mm, hz - 16.mm], [3.5.mm, 32.mm, 32.mm], steel_mat, "Mounting_Plate")
      create_cylinder(plate_grp.entities, Geom::Point3d.new(g_inside_x, door_back_y + 37.mm, hz + 16.mm), Geom::Vector3d.new(1, 0, 0), 2.5.mm, 4.mm, steel_mat)
      create_cylinder(plate_grp.entities, Geom::Point3d.new(g_inside_x, door_back_y + 37.mm, hz - 16.mm), Geom::Vector3d.new(1, 0, 0), 2.5.mm, 4.mm, steel_mat)
      create_box(plate_grp.entities, [g_inside_x - 6.mm, door_back_y + 2.mm, hz - 6.mm], [6.mm, 35.mm, 12.mm], steel_mat, "Hinge_Arm_Base")
    end

    plate_grp
  end

  def self.build_blum_door_cup(door_ents, cup_x, door_back_y, hz, mats)
    cup_grp = door_ents.add_group
    cup_grp.name = "Blum_35mm_Door_Hinge_Cup"
    steel_mat = mats[:steel]

    create_cylinder(cup_grp.entities, Geom::Point3d.new(cup_x, door_back_y, hz), Geom::Vector3d.new(0, -1, 0), 17.5.mm, 12.5.mm, steel_mat)
    create_box(cup_grp.entities, [cup_x - 10.mm, door_back_y - 2.5.mm, hz - 24.mm], [20.mm, 2.5.mm, 48.mm], steel_mat, "Cup_Flange")
    create_cylinder(cup_grp.entities, Geom::Point3d.new(cup_x, door_back_y, hz + 22.5.mm), Geom::Vector3d.new(0, -1, 0), 4.0.mm, 11.0.mm, steel_mat)
    create_cylinder(cup_grp.entities, Geom::Point3d.new(cup_x, door_back_y, hz - 22.5.mm), Geom::Vector3d.new(0, -1, 0), 4.0.mm, 11.0.mm, steel_mat)

    cup_grp
  end

  # ----------------------------------------------------------------------------
  # 6. FREE STOP DAMPING UPWARD FLAP LIFT SYSTEM (IMAGE 5 REFERENCE)
  # ----------------------------------------------------------------------------
  def self.build_free_stop_flap_lift_mechanism(parent_ents, bx, by, bz, width, height, depth, mats)
    lift_group = parent_ents.add_group
    lift_group.name = "Free_Stop_Damping_Flap_Lift_System"
    steel_mat = mats[:steel]
    cover_mat = mats[:carcase]

    body_w = 28.0.mm
    body_d = 160.0.mm
    body_h = 120.0.mm
    lift_z = bz + height - body_h - 15.0.mm
    lift_y = by - depth + 35.0.mm

    create_box(lift_group.entities, [bx + BOARD_THK + 1.mm, lift_y, lift_z], [body_w, body_d, body_h], steel_mat, "Body_Lift_LH")
    create_box(lift_group.entities, [bx + BOARD_THK, lift_y - 5.mm, lift_z - 5.mm], [body_w + 3.mm, body_d + 10.mm, body_h + 10.mm], cover_mat, "Body_Cover_LH")

    create_box(lift_group.entities, [bx + width - BOARD_THK - body_w - 1.mm, lift_y, lift_z], [body_w, body_d, body_h], steel_mat, "Body_Lift_RH")
    create_box(lift_group.entities, [bx + width - BOARD_THK - body_w - 3.mm, lift_y - 5.mm, lift_z - 5.mm], [body_w + 3.mm, body_d + 10.mm, body_h + 10.mm], cover_mat, "Body_Cover_RH")

    arm_len = depth - 80.mm
    create_box(lift_group.entities, [bx + BOARD_THK + body_w + 2.mm, by - depth + 15.mm, bz + height - 40.mm], [10.mm, arm_len, 18.mm], steel_mat, "Telescopic_Arm_LH")
    create_box(lift_group.entities, [bx + width - BOARD_THK - body_w - 12.mm, by - depth + 15.mm, bz + height - 40.mm], [10.mm, arm_len, 18.mm], steel_mat, "Telescopic_Arm_RH")

    door_back_y = by - depth
    create_box(lift_group.entities, [bx + 60.mm, door_back_y - 3.mm, bz + height - 50.mm], [45.mm, 3.mm, 35.mm], steel_mat, "Door_Fixing_Base_LH")
    create_box(lift_group.entities, [bx + width - 105.mm, door_back_y - 3.mm, bz + height - 50.mm], [45.mm, 3.mm, 35.mm], steel_mat, "Door_Fixing_Base_RH")

    lift_group
  end

  # ----------------------------------------------------------------------------
  # 7. SHOTGUN NOTCHED SHELVES & CARCASE PANELS
  # ----------------------------------------------------------------------------
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
    ].uniq

    face = group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.x < 0
      face.pushpull(BOARD_THK)
    end
    group.material = material if material
    group
  end

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

  def self.build_hettich_undermount_drawer(parent_ents, inner_origin, inner_w, depth, box_height, front_h, pull_offset, mats, front_mat, is_sink_u_shape: false, front_w: nil, box_z_offset: 20.0, is_inner_drawer: false, handle_len: nil)
    drawer_unit = parent_ents.add_group
    drawer_unit.name = "Hettich_Undermount_Drawer_#{inner_w.to_mm.round}x#{front_h.to_mm.round}"

    hinge_spacer = is_inner_drawer ? 25.0 : 0.0
    dims = CabinetrixCollisionEngine.calculate_drawer_geometry(inner_w.to_mm, depth.to_mm, side_gap: 12.5, box_thk: 15.0, front_h: front_h.to_mm, hinge_spacer: hinge_spacer)
    box_w = dims[:box_w].mm
    box_d = dims[:box_d].mm
    box_h = [box_height, dims[:box_h].mm].min
    box_thk = dims[:box_thk].mm
    f_w = front_w || (inner_w + (2 * BOARD_THK) - 3.mm)

    ox = inner_origin.x
    base_y = inner_origin.y
    oy = base_y - pull_offset
    oz = inner_origin.z

    front_ox = is_inner_drawer ? (ox + hinge_spacer.mm) : (ox - BOARD_THK + 1.5.mm)
    front_oy = is_inner_drawer ? (oy + 5.mm) : (oy - FRONT_THK)
    create_box(drawer_unit.entities, [front_ox, front_oy, oz], [f_w, FRONT_THK, front_h], front_mat, "Drawer_Front_Face")

    # Add contemporary handle if specified
    if handle_len && !is_inner_drawer
      h_center = Geom::Point3d.new(front_ox + f_w/2.0, front_oy, oz + front_h - 40.mm)
      build_contemporary_bar_handle(drawer_unit.entities, h_center, handle_len, :horizontal, mats)
    end

    box_ox = ox + 12.5.mm + hinge_spacer.mm
    box_oz = [oz + 15.0.mm, box_z_offset.mm].max
    box_oy = oy + (is_inner_drawer ? 30.0.mm : 60.0.mm)

    create_box(drawer_unit.entities, [box_ox, box_oy, box_oz], [box_thk, box_d, box_h], mats[:wood], "Drawer_Side_LH")
    create_box(drawer_unit.entities, [box_ox + box_w - box_thk, box_oy, box_oz], [box_thk, box_d, box_h], mats[:wood], "Drawer_Side_RH")
    sub_w = box_w - (2 * box_thk)

    create_box(drawer_unit.entities, [box_ox + box_thk, box_oy, box_oz], [sub_w, box_thk, box_h], mats[:wood], "Drawer_Sub_Front")
    create_box(drawer_unit.entities, [box_ox + box_thk, box_oy + box_d - box_thk, box_oz], [sub_w, box_thk, box_h], mats[:wood], "Drawer_Back_Panel")
    create_box(drawer_unit.entities, [box_ox + box_thk, box_oy + box_thk, box_oz + 12.mm], [sub_w, box_d - 2*box_thk, 16.0.mm], mats[:wood], "Drawer_Bottom_Panel")

    runner_w = 11.0.mm
    runner_h = 24.0.mm
    fixed_slide_y = base_y + 40.mm
    create_box(drawer_unit.entities, [ox + 1.0.mm + hinge_spacer.mm, fixed_slide_y, box_oz - 12.mm], [runner_w, box_d, runner_h], mats[:steel], "Hettich_Actro5D_Slide_LH")
    create_box(drawer_unit.entities, [ox + inner_w - runner_w - 1.0.mm, fixed_slide_y, box_oz - 12.mm], [runner_w, box_d, runner_h], mats[:steel], "Hettich_Actro5D_Slide_RH")

    drawer_unit
  end

  def self.create_sash_bar(parent_ents, bar_length, alu_mat)
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

    group
  end

  def self.build_senior_sash_door(parent_ents, ox, oy, oz, door_w, door_h, mats, open_angle_deg: 0.0, hinge_z_list: nil, is_left_hinged: true)
    group = parent_ents.add_group
    group.name = "Alu_Sash_Door_#{door_w.to_mm.round}x#{door_h.to_mm.round}"
    sub = group.entities
    transform = Geom::Transformation.translation([ox, oy, oz])

    alu_mat   = mats[:gola]
    glass_mat = mats[:glass]

    bottom = create_sash_bar(sub, door_w, alu_mat)
    bottom.transform!(transform)

    top = create_sash_bar(sub, door_w, alu_mat)
    top.transform!(Geom::Transformation.scaling(1, 1, -1))
    top.transform!(Geom::Transformation.translation([0, 0, door_h]))
    top.transform!(transform)

    left = create_sash_bar(sub, door_h, alu_mat)
    left.transform!(Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], -90.degrees))
    left.transform!(Geom::Transformation.scaling(-1, 1, 1))
    left.transform!(transform)

    right = create_sash_bar(sub, door_h, alu_mat)
    right.transform!(Geom::Transformation.rotation([0, 0, 0], [0, 1, 0], -90.degrees))
    right.transform!(Geom::Transformation.translation([door_w, 0, 0]))
    right.transform!(transform)

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

    if hinge_z_list
      cup_x = is_left_hinged ? (ox + 20.0.mm) : (ox + door_w - 20.0.mm)
      door_back_y = oy + 21.2.mm
      hinge_z_list.each do |hz|
        build_blum_door_cup(sub, cup_x, door_back_y, hz, mats)
      end
    end

    if open_angle_deg != 0.0
      pivot_x = is_left_hinged ? ox : (ox + door_w)
      pivot_pt = Geom::Point3d.new(pivot_x, oy + 21.2.mm, oz)
      rot_dir  = is_left_hinged ? -1.0 : 1.0
      rot_tr = Geom::Transformation.rotation(pivot_pt, Geom::Vector3d.new(0, 0, 1), rot_dir * open_angle_deg.degrees)
      group.transform!(rot_tr)
    end

    group
  end

  # ----------------------------------------------------------------------------
  # 8. UNIVERSAL BOX CREATION API
  # ----------------------------------------------------------------------------
  def self.create_cabinet(parent_ents, type, params, location, mats)
    name = params[:name] || "Cabinet_#{type.to_s.upcase}"
    box_grp = parent_ents.add_group
    box_grp.name = name

    bx = 0.0.mm
    by = 0.0.mm
    bz = 0.0.mm

    template = CabinetrixCatalogue.get(type) if defined?(CabinetrixCatalogue)
    if template
      actual_type = template[:engine_type] || type.to_sym
      t_w = template.dig(:dimensions, :w) || template.dig(:dimensions, :w, :default)
      t_h = template.dig(:dimensions, :h) || template.dig(:dimensions, :h, :default)
      t_d = template.dig(:dimensions, :d) || template.dig(:dimensions, :d, :default)
      width  = params[:width]  || (t_w ? t_w.mm : nil)
      height = params[:height] || (t_h ? t_h.mm : nil)
      depth  = params[:depth]  || (t_d ? t_d.mm : nil)
      type   = actual_type
    end

    width  ||= params[:width] || 600.mm
    height ||= params[:height] || (type.to_s.start_with?('tall') ? TALL_CARCASE_H : (type.to_s.start_with?('wall') || type.to_s.start_with?('open') ? WALL_CARCASE_H : (type.to_s.start_with?('top_bulkhead') ? 360.mm : BASE_CARCASE_H)))
    depth  ||= params[:depth]  || (type.to_s.start_with?('tall') ? TALL_DEPTH : (type.to_s.start_with?('wall') || type.to_s.start_with?('open') || type.to_s.start_with?('top_bulkhead') ? WALL_DEPTH : BASE_DEPTH))

    params = CabinetrixCollisionEngine.audit_pre_flight(type, params)

    mode   = params[:mode]   || :closed
    front_mat = params[:front_mat] || mats[:front_dark]
    include_gola = (params[:include_gola] != false)
    inner_w = width - (2 * BOARD_THK)

    # 1. Automatic Adjustable Legs & Plinth for Floor Standing Units
    is_floor_standing = type.to_s.start_with?('base') || type.to_s.start_with?('island') || type.to_s.start_with?('tall') || type.to_s.start_with?('metod_base')
    if is_floor_standing && (params[:include_plinth] != false)
      build_adjustable_legs_and_plinth(box_grp.entities, bx, by, bz, width, depth, mats)
    end

    case type
    # ==========================================================================
    # CORNER BASE UNITS
    # ==========================================================================
    when :base_blind_corner, :base_lemans_corner, :base_magic_corner, :base_corner_shelf
      blind_width = 600.0.mm
      door_width  = width - blind_width
      upright_x   = door_width

      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      create_box(box_grp.entities, [bx + BOARD_THK, by - depth + GOLA_DEPTH, bz + height - BOARD_THK], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Front_Stretcher")
      create_box(box_grp.entities, [bx + BOARD_THK, by - 80.mm, bz + height - BOARD_THK], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Rear_Stretcher")

      pillar_center_x = bx + upright_x
      create_box(box_grp.entities, [pillar_center_x - BOARD_THK/2.0, by - depth, bz + BOARD_THK], [BOARD_THK, 100.mm, height - 3*BOARD_THK], mats[:carcase], "Corner_Door_Support_Upright")

      notch_w = BOARD_THK + 2.0.mm
      notch_d = 100.0.mm
      notch_x = pillar_center_x - notch_w/2.0
      shelf_origin = [bx + BOARD_THK, by - depth, bz + height/2.0]
      shelf_size   = [inner_w, depth - BOARD_THK - BACK_THK, BOARD_THK]
      create_front_notched_shelf(box_grp.entities, "Corner_Mid_Shelf_With_Upright_Notch", shelf_origin, shelf_size, notch_x, notch_w, notch_d, mats[:carcase])

      pillar_face_x = pillar_center_x - BOARD_THK/2.0
      corner_hinge_z = [bz + 100.mm, bz + height - 120.mm]
      corner_hinge_z.each do |hz|
        build_blum_carcase_plate(box_grp.entities, pillar_face_x, by - depth, hz, false, mats)
      end

      door_open_deg = (mode == :hybrid ? 95.0 : 0.0)
      door_grp = box_grp.entities.add_group
      door_grp.name = "Corner_Working_Door_Assembly"
      
      create_box(door_grp.entities, [bx + 3.mm, by - depth - FRONT_THK, bz + 3.mm], [door_width - 6.mm, FRONT_THK, height - 38.mm], front_mat, "Door_Slab")
      corner_hinge_z.each do |hz|
        build_blum_door_cup(door_grp.entities, bx + door_width - 21.5.mm, by - depth, hz, mats)
      end

      if door_open_deg > 0
        pivot_pt = Geom::Point3d.new(bx + upright_x - 3.mm, by - depth - FRONT_THK, bz)
        door_grp.transform!(Geom::Transformation.rotation(pivot_pt, Geom::Vector3d.new(0, 0, 1), door_open_deg.degrees))
      end
      create_box(box_grp.entities, [bx + door_width + 3.mm, by - depth - FRONT_THK, bz + 3.mm], [blind_width - 6.mm, FRONT_THK, height - 3.mm], front_mat, "Corner_Blind_Panel_Right")

    # ==========================================================================
    # HANDLED DRAWER BASE UNITS (STANDARD / CONTEMPORARY)
    # ==========================================================================
    when :base_handled_drawers
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      create_box(box_grp.entities, [bx + BOARD_THK, by - depth, bz + height - BOARD_THK], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Front_Stretcher")
      create_box(box_grp.entities, [bx + BOARD_THK, by - 80.mm, bz + height - BOARD_THK], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Rear_Stretcher")

      # 2-Drawer Full-Overlay Configuration (e.g. 2x 356mm fronts on 720mm, or 2x 396mm on 800mm)
      f_h = (height - 6.mm) / 2.0
      build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, by - depth, bz + 1.5.mm), inner_w, depth, 200.mm, f_h, 0.mm, mats, front_mat, handle_len: [width.to_mm - 200.0, 160.0].max)
      build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, by - depth, bz + 1.5.mm + f_h + 3.mm), inner_w, depth, 200.mm, f_h, 0.mm, mats, front_mat, handle_len: [width.to_mm - 200.0, 160.0].max)

    # ==========================================================================
    # METOD STANDARD BASE UNITS (800MM FULL OVERLAY DOORS WITH HANDLES)
    # ==========================================================================
    when :metod_base_unit
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      create_box(box_grp.entities, [bx + BOARD_THK, by - depth, bz + height - BOARD_THK], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Front_Stretcher")
      create_box(box_grp.entities, [bx + BOARD_THK, by - 80.mm, bz + height - BOARD_THK], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Rear_Stretcher")

      safe_shelves = CabinetrixCollisionEngine.calculate_safe_shelf_elevations(height.to_mm)
      safe_shelves.each_with_index do |sz, idx|
        build_adjustable_shelf(box_grp.entities, "Adjustable_Shelf_#{idx+1}", width, depth, bz + sz.mm, mats)
      end

      door_h = height - 3.0.mm
      door_y = by - depth - FRONT_THK
      hinge_z_list = [bz + 100.mm, bz + height - 100.mm]

      if width.to_mm <= 450.0
        hinge_z_list.each do |hz|
          build_blum_carcase_plate(box_grp.entities, bx + BOARD_THK, by - depth, hz, true, mats)
        end
        door_grp = box_grp.entities.add_group
        door_grp.name = "METOD_Single_Door_Assembly"
        create_box(door_grp.entities, [bx + 1.5.mm, door_y, bz + 1.5.mm], [width - 3.mm, FRONT_THK, door_h], front_mat, "Door_Slab")
        hinge_z_list.each do |hz|
          build_blum_door_cup(door_grp.entities, bx + 21.5.mm, by - depth, hz, mats)
        end
        # Handle on right side of door
        h_pt = Geom::Point3d.new(bx + width - 35.mm, door_y, bz + height - 120.mm)
        build_contemporary_bar_handle(door_grp.entities, h_pt, 160.0, :vertical, mats)
      else
        single_w = (width - 6.mm) / 2.0
        hinge_z_list.each do |hz|
          build_blum_carcase_plate(box_grp.entities, bx + BOARD_THK, by - depth, hz, true, mats)
          build_blum_carcase_plate(box_grp.entities, bx + width - BOARD_THK, by - depth, hz, false, mats)
        end

        door_l = box_grp.entities.add_group
        door_l.name = "METOD_Door_LH"
        create_box(door_l.entities, [bx + 1.5.mm, door_y, bz + 1.5.mm], [single_w, FRONT_THK, door_h], front_mat, "Door_Slab_LH")
        hinge_z_list.each do |hz|
          build_blum_door_cup(door_l.entities, bx + 21.5.mm, by - depth, hz, mats)
        end
        h_pt_l = Geom::Point3d.new(bx + 1.5.mm + single_w - 35.mm, door_y, bz + height - 120.mm)
        build_contemporary_bar_handle(door_l.entities, h_pt_l, 160.0, :vertical, mats)

        door_r = box_grp.entities.add_group
        door_r.name = "METOD_Door_RH"
        create_box(door_r.entities, [bx + 1.5.mm + single_w + 3.mm, door_y, bz + 1.5.mm], [single_w, FRONT_THK, door_h], front_mat, "Door_Slab_RH")
        hinge_z_list.each do |hz|
          build_blum_door_cup(door_r.entities, bx + width - 21.5.mm, by - depth, hz, mats)
        end
        h_pt_r = Geom::Point3d.new(bx + 1.5.mm + single_w + 38.mm, door_y, bz + height - 120.mm)
        build_contemporary_bar_handle(door_r.entities, h_pt_r, 160.0, :vertical, mats)
      end

    # ==========================================================================
    # BASE GOLA UNITS (720MM CARCASE WITH SCILM PROFILES)
    # ==========================================================================
    when :base_gola_drawers, :base_gola_cooktop, :base_gola_sink, :base_gola_spice, :base_gola_wine, :island_gola_drawers, :island_gola_sink
      stretcher_z = bz + height - BOARD_THK
      front_w = width - 3.mm
      front_y = by - depth

      create_machined_gola_gable(box_grp.entities, bx, depth, bz, height, mats[:carcase], "Gable_LH")
      create_machined_gola_gable(box_grp.entities, bx + width - BOARD_THK, depth, bz, height, mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      front_sub_y = -depth + GOLA_DEPTH
      create_box(box_grp.entities, [bx + BOARD_THK, front_sub_y, stretcher_z], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Front_Gola_Stretcher")
      rear_stretcher_y = by - 80.mm
      create_box(box_grp.entities, [bx + BOARD_THK, rear_stretcher_y, stretcher_z], [inner_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Rear_Gola_Stretcher")

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
      upper_door_z = BASE_DATUM_Z - PLINTH_HEIGHT + 885.mm + BOARD_THK + 3.mm
      oven_hinge_z = [upper_door_z + 80.mm, upper_door_z + upper_door_h - 80.mm]

      oven_hinge_z.each do |hz|
        build_blum_carcase_plate(box_grp.entities, bx + BOARD_THK, by - depth, hz, true, mats)
      end

      door_grp = box_grp.entities.add_group
      door_grp.name = "Upper_Cupboard_Door_Assembly"
      create_box(door_grp.entities, [bx + 1.5.mm, by - depth - FRONT_THK, upper_door_z], [width - 3.mm, FRONT_THK, upper_door_h], front_mat, "Door_Slab")
      oven_hinge_z.each do |hz|
        build_blum_door_cup(door_grp.entities, bx + 21.5.mm, by - depth, hz, mats)
      end

      build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, by - depth, bz + 12.mm), inner_w, depth, 200.mm, 355.mm, 0.mm, mats, front_mat)
      build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, by - depth, bz + 380.mm), inner_w, depth, 200.mm, 335.mm, (mode == :hybrid ? 250.mm : 0.mm), mats, front_mat)

    when :tall_pantry_larder, :tall_space_tower
      create_box(box_grp.entities, [bx, by - depth, 0], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, 0], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_structural_shelf(box_grp.entities, "Larder_Mid_Structural_Shelf", width, depth, 1200.mm, mats)
      build_structural_shelf(box_grp.entities, "Roof_Panel", width, depth, height - BOARD_THK, mats, full_depth_to_wall: true)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, height, mats, has_mid_cleat: true, mid_cleat_z: 1200.mm)

      if depth.to_mm >= 450.0
        drawer_pull = (mode == :hybrid ? 300.mm : 0.mm)
        [bz + 20.mm, bz + 230.mm, bz + 440.mm, bz + 650.mm, bz + 860.mm].each_with_index do |dz, i|
          pull_dist = (i == 1) ? drawer_pull : 0.mm
          build_hettich_undermount_drawer(box_grp.entities, Geom::Point3d.new(bx + BOARD_THK, by - depth + 25.mm, dz), inner_w, depth, 140.mm, 160.mm, pull_dist, mats, mats[:carcase], front_w: (inner_w - 28.mm), is_inner_drawer: true)
        end

        upper_clear_h = height.to_mm - 1200.0 - 36.0
        safe_shelves = CabinetrixCollisionEngine.calculate_safe_shelf_elevations(upper_clear_h)
        safe_shelves.each_with_index do |sz, idx|
          build_adjustable_shelf(box_grp.entities, "Adjustable_Shelf_#{idx+1}", width, depth, 1200.mm + sz.mm, mats)
        end
      else
        lower_clear_h = 1200.0 - 36.0
        lower_shelves = CabinetrixCollisionEngine.calculate_safe_shelf_elevations(lower_clear_h)
        lower_shelves.each_with_index do |sz, idx|
          build_adjustable_shelf(box_grp.entities, "Lower_Shelf_#{idx+1}", width, depth, bz + sz.mm, mats)
        end

        upper_clear_h = height.to_mm - 1200.0 - 36.0
        upper_shelves = CabinetrixCollisionEngine.calculate_safe_shelf_elevations(upper_clear_h)
        upper_shelves.each_with_index do |sz, idx|
          build_adjustable_shelf(box_grp.entities, "Upper_Shelf_#{idx+1}", width, depth, 1200.mm + sz.mm, mats)
        end
      end
      
      tower_hinge_z = [bz + 200.mm, bz + 625.mm, bz + 1250.mm, bz + 1950.mm]

      tower_hinge_z.each do |hz|
        build_blum_carcase_plate(box_grp.entities, bx + BOARD_THK, by - depth, hz, true, mats)
      end

      door_open_deg = (mode == :hybrid ? 95.0 : 0.0)
      build_senior_sash_door(box_grp.entities, bx + 1.5.mm, by - depth - 21.2.mm, bz, width - 3.mm, height - bz - 3.mm, mats, open_angle_deg: door_open_deg, hinge_z_list: tower_hinge_z, is_left_hinged: true)

    # ==========================================================================
    # WALL UNITS & FLAP LIFTS
    # ==========================================================================
    when :wall_lift_aventos, :top_bulkhead_flap, :deep_top_bulkhead
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Top_Panel", width, depth, bz + height - BOARD_THK, mats, full_depth_to_wall: true)
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      safe_shelves = CabinetrixCollisionEngine.calculate_safe_shelf_elevations(height.to_mm)
      safe_shelves.each_with_index do |sz, idx|
        build_adjustable_shelf(box_grp.entities, "Adjustable_Shelf_#{idx+1}", width, depth, bz + sz.mm, mats, setback_mm: 40.0)
      end

      build_free_stop_flap_lift_mechanism(box_grp.entities, bx, by, bz, width, height, depth, mats)
      create_box(box_grp.entities, [bx + 1.5.mm, by - depth - FRONT_THK, bz + 1.5.mm], [width - 3.mm, FRONT_THK, height - 3.mm], front_mat, "Flap_Door_Slab")

    when :wall_glass_display
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Top_Panel", width, depth, bz + height - BOARD_THK, mats, full_depth_to_wall: true)
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      safe_shelves = CabinetrixCollisionEngine.calculate_safe_shelf_elevations(height.to_mm)
      safe_shelves.each_with_index do |sz, idx|
        build_adjustable_shelf(box_grp.entities, "Glass_Shelf_#{idx+1}", width, depth, bz + sz.mm, mats, is_glass: true)
      end
      
      door_h = height + BOARD_THK
      door_z = bz - BOARD_THK
      is_l = (params[:is_left_hinged] != false)
      wall_hinge_z = [bz + 60.mm, bz + height - 60.mm]

      gx = is_l ? (bx + BOARD_THK) : (bx + width - BOARD_THK)
      wall_hinge_z.each do |hz|
        build_blum_carcase_plate(box_grp.entities, gx, by - depth, hz, is_l, mats)
      end

      build_senior_sash_door(box_grp.entities, bx + 1.5.mm, by - depth - 21.2.mm, door_z, width - 3.mm, door_h, mats, hinge_z_list: wall_hinge_z, is_left_hinged: is_l)

    when :open_wine_grid
      create_box(box_grp.entities, [bx, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
      create_box(box_grp.entities, [bx + width - BOARD_THK, by - depth, bz], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
      build_structural_shelf(box_grp.entities, "Top_Panel", width, depth, bz + height - BOARD_THK, mats, full_depth_to_wall: true)
      build_structural_shelf(box_grp.entities, "Bottom_Panel", width, depth, bz, mats)
      build_shotgun_grooved_back(box_grp.entities, name, width, bz, bz + height, mats)

      build_interlocking_wine_grid(box_grp.entities, bx, by, bz, width, height, depth, mats, is_open_display: true)

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
      if height.to_mm > 500.0
        create_box(box_grp.entities, [bx + 25.mm, by - depth + 25.mm, bz + height/2.0 + 10.mm], [width - 50.mm, depth - 50.mm, 18.mm], oak_mat, "Oak_Display_Shelf_Upper")
      end
    end

    rot_deg = location[:rotation_deg] || params[:rotation_deg] || 0.0
    tr_rot = Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0), Geom::Vector3d.new(0, 0, 1), rot_deg.degrees)
    tr_pos = Geom::Transformation.translation(Geom::Vector3d.new(location[:x] || 0.mm, location[:y] || 0.mm, location[:z] || 0.mm))
    box_grp.transform!(tr_pos * tr_rot)

    box_grp
  end

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

    panels
  end
end
