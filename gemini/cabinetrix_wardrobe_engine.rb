# ==============================================================================
# CABINETRIX AI — DEDICATED ARCHITECTURAL WARDROBE ENGINE (GEMINI MODULE)
# Pure Function API: CabinetrixWardrobeEngine.build_wardrobe(parent_ents, type, params, location, mats)
#
# Production Standard:
#   • KINEMATIC DOOR-PENETRATION COLLISION RULE:
#     - "Nothing goes through doors unless door is opened."
#     - In hybrid demo mode, front sash doors are rotated open (95°) so that internal drawers and trouser pullouts glide out cleanly.
#     - When doors are closed (0°), all internal components are 100% retracted inside the carcase.
#   • GLOBAL DRAWER HARDWARE FUNCTION:
#     - Pure Hardware Formula: Drawer Box Width = Internal Width - (2 * Side Gap)
#     - Uses CabinetrixCollisionEngine.calculate_drawer_geometry(inner_w, depth, side_gap: 12.5, hinge_spacer: spacer_offset)
#   • KOMPLEMENT & CONERO ARCHITECTURAL ACCESSORIES:
#     - Single Long Hanging (1600mm coat clearance + 55mm rod hook drop)
#     - Double Stack Hanging (2 x 950mm tier clearance for shirts & trousers)
#     - Pull-out Trouser Racks (650mm vertical drop clearance)
#     - Sloping Shoe Racks (25° pitch + front retaining gallery rails)
#     - Internal Drawer Stacks (Zero-protrusion 155° hinge clearances / 25mm spacer offsets)
#   • System 32 metric line-bore drilling, Minifix 15 + dowel KD connections.
# ==============================================================================
require 'sketchup.rb'
require_relative 'cabinetrix_collision_engine'

module CabinetrixWardrobeEngine
  BOARD_THK         = 18.0.mm
  FRONT_THK         = 18.0.mm
  DRAWER_BOX_THK    = 15.0.mm
  BACK_THK          = 6.0.mm
  BACK_GROOVE       = 5.0.mm

  DEFAULT_PLINTH    = 100.0.mm
  DEFAULT_HEIGHT    = 2160.0.mm
  DEFAULT_DEPTH     = 600.0.mm

  MINIFIX_CAM_D     = 15.0.mm
  MINIFIX_CAM_DEPTH = 12.5.mm
  MINIFIX_B_DIST    = 34.0.mm
  DOWEL_D           = 8.0.mm
  DOWEL_LEN         = 30.0.mm

  # ----------------------------------------------------------------------------
  # 1. CORE PRIMITIVES
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

  def self.create_cylinder(entities, center, normal, radius, height, material = nil, num_segments = 20)
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

  def self.build_minifix_joint(parent_ents, bolt_center, dir_vector, mats, cam_normal: Geom::Vector3d.new(0, 0, 1), cam_offset_dist: 9.0.mm, bounds_y: nil)
    group = parent_ents.add_group
    group.name = "Minifix_15_Joint_Set"
    inv_vector = dir_vector.reverse

    create_cylinder(group.entities, bolt_center, inv_vector, 2.5.mm, 11.0.mm, mats[:steel], 12)
    create_cylinder(group.entities, bolt_center, dir_vector, 3.75.mm, 1.5.mm, mats[:steel], 12)
    pin_start = Geom::Point3d.new(bolt_center.x + dir_vector.x * 1.5.mm, bolt_center.y + dir_vector.y * 1.5.mm, bolt_center.z + dir_vector.z * 1.5.mm)
    create_cylinder(group.entities, pin_start, dir_vector, 3.25.mm, 32.5.mm, mats[:steel], 12)

    cam_x = bolt_center.x + dir_vector.x * MINIFIX_B_DIST
    cam_y = bolt_center.y + dir_vector.y * MINIFIX_B_DIST
    cam_z = bolt_center.z + dir_vector.z * MINIFIX_B_DIST
    cam_face_pt = Geom::Point3d.new(cam_x + cam_normal.x * cam_offset_dist, cam_y + cam_normal.y * cam_offset_dist, cam_z + cam_normal.z * cam_offset_dist)
    vis_pt = Geom::Point3d.new(cam_face_pt.x + cam_normal.x * 0.3.mm, cam_face_pt.y + cam_normal.y * 0.3.mm, cam_face_pt.z + cam_normal.z * 0.3.mm)

    c_rim = group.entities.add_circle(vis_pt, cam_normal, (MINIFIX_CAM_D / 2.0) + 0.3.mm, 18)
    f_rim = group.entities.add_face(c_rim)
    f_rim.material = mats[:hole] if f_rim
    create_cylinder(group.entities, vis_pt, cam_normal.reverse, MINIFIX_CAM_D / 2.0, MINIFIX_CAM_DEPTH, mats[:cam], 18)

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
        dowel_start = Geom::Point3d.new(bolt_center.x - dir_vector.x * 10.0.mm, dowel_y, bolt_center.z)
        create_cylinder(group.entities, dowel_start, dir_vector, DOWEL_D / 2.0, DOWEL_LEN, mats[:dowel], 16)
      end
    end
    group
  end

  def self.build_shotgun_grooved_back(parent_ents, name_prefix, origin_x, y_origin, width, base_z, top_z, mats)
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

    sheet_ox = origin_x + thk - groove
    sheet_oy = y_origin - thk - back_t
    sheet_oz = base_z + thk - groove
    create_box(group.entities, [sheet_ox, sheet_oy, sheet_oz], [sheet_w, back_t, sheet_h], mats[:carcase], "#{name_prefix}_Grooved_Back_Sheet")
    create_box(group.entities, [origin_x + thk, y_origin - thk, top_z - thk - cleat_h], [stretcher_w, thk, cleat_h], mats[:carcase], "#{name_prefix}_Rear_Top_Vertical_Cleat")
    create_box(group.entities, [origin_x + thk, y_origin - thk, base_z + thk], [stretcher_w, thk, cleat_h], mats[:carcase], "#{name_prefix}_Rear_Bottom_Vertical_Cleat")
    create_box(group.entities, [origin_x + thk, y_origin - thk, base_z + (top_z - base_z)/2.0 - cleat_h/2.0], [stretcher_w, thk, cleat_h], mats[:carcase], "#{name_prefix}_Rear_Mid_Vertical_Cleat")
    group
  end

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

  def self.build_adjustable_shelf(parent_ents, name, origin_x, width, depth, z_pos, mats, is_glass: false, y_origin: 0)
    group = parent_ents.add_group
    group.name = name

    inner_w = width - (2 * BOARD_THK)
    shelf_w = inner_w - 1.0.mm
    shelf_d = depth - 20.0.mm - (BOARD_THK + BACK_THK)
    sh_x    = origin_x + BOARD_THK + 0.5.mm
    sh_y    = y_origin - depth + 20.0.mm

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
  # 2. KOMPLEMENT & CONERO ACCESSORY BUILDERS
  # ----------------------------------------------------------------------------
  def self.build_clothes_rail(parent_ents, name, origin_x, y_origin, width, depth, z_pos, mats)
    group = parent_ents.add_group
    group.name = name
    inner_w = width - (2 * BOARD_THK)
    rail_y = y_origin - depth / 2.0
    rail_start = Geom::Point3d.new(origin_x + BOARD_THK + 5.mm, rail_y, z_pos)

    create_cylinder(group.entities, rail_start, Geom::Vector3d.new(1, 0, 0), 12.5.mm, inner_w - 10.mm, mats[:steel], 24)
    create_box(group.entities, [origin_x + BOARD_THK, rail_y - 15.mm, z_pos - 20.mm], [5.mm, 30.mm, 40.mm], mats[:cam], "Socket_Bracket_LH")
    create_box(group.entities, [origin_x + width - BOARD_THK - 5.mm, rail_y - 15.mm, z_pos - 20.mm], [5.mm, 30.mm, 40.mm], mats[:cam], "Socket_Bracket_RH")
    create_box(group.entities, [origin_x + BOARD_THK + 10.mm, rail_y - 2.mm, z_pos - 14.mm], [inner_w - 20.mm, 4.mm, 2.mm], mats[:gola], "Diffuser_LED_Strip")
    group
  end

  def self.build_trouser_rack(parent_ents, name, origin_x, y_origin, width, depth, z_pos, mats, pull_dist = 0.mm)
    group = parent_ents.add_group
    group.name = name
    inner_w = width - (2 * BOARD_THK) - (2 * 12.5.mm)
    rack_d  = depth - 100.mm
    ox      = origin_x + BOARD_THK + 12.5.mm
    oy      = y_origin - depth + 50.mm - pull_dist

    create_box(group.entities, [ox, oy, z_pos], [inner_w, 20.mm, 25.mm], mats[:gola], "Trouser_Frame_Front")
    create_box(group.entities, [ox, oy + rack_d - 20.mm, z_pos], [inner_w, 20.mm, 25.mm], mats[:gola], "Trouser_Frame_Rear")
    create_box(group.entities, [ox, oy, z_pos], [20.mm, rack_d, 25.mm], mats[:gola], "Trouser_Frame_Side_LH")
    create_box(group.entities, [ox + inner_w - 20.mm, oy, z_pos], [20.mm, rack_d, 25.mm], mats[:gola], "Trouser_Frame_Side_RH")

    num_rods = (inner_w / 65.mm).to_i
    spacing  = inner_w / (num_rods + 1)
    (1..num_rods).each do |i|
      rod_x = ox + (i * spacing)
      create_cylinder(group.entities, Geom::Point3d.new(rod_x, oy + 20.mm, z_pos + 12.mm), Geom::Vector3d.new(0, 1, 0), 4.mm, rack_d - 40.mm, mats[:steel], 12)
    end
    group
  end

  def self.build_shoe_rack(parent_ents, name, origin_x, y_origin, width, depth, z_pos, mats)
    group = parent_ents.add_group
    group.name = name
    inner_w = width - (2 * BOARD_THK) - 2.mm
    rack_d  = depth - 80.mm
    ox      = origin_x + BOARD_THK + 1.mm
    oy      = y_origin - depth + 40.mm

    shelf = create_box(group.entities, [ox, oy, z_pos], [inner_w, rack_d, 12.mm], mats[:gola], "Shoe_Shelf_Plate")
    shelf.transform!(Geom::Transformation.rotation(Geom::Point3d.new(ox, oy, z_pos), Geom::Vector3d.new(1, 0, 0), 20.degrees))
    create_box(group.entities, [ox + 10.mm, oy + 30.mm, z_pos + 25.mm], [inner_w - 20.mm, 5.mm, 20.mm], mats[:steel], "Chrome_Shoe_Rail")
    group
  end

  # Internal KOMPLEMENT Wardrobe Drawer (Global hardware drawer calculation)
  def self.build_internal_wardrobe_drawer(parent_ents, name, origin_x, y_origin, width, depth, z_pos, box_h, front_h, mats, pull_dist = 0.mm, spacer_offset = 0.mm)
    group = parent_ents.add_group
    group.name = name

    inner_w = width - (2 * BOARD_THK)
    dims = CabinetrixCollisionEngine.calculate_drawer_geometry(inner_w.to_mm, depth.to_mm, side_gap: 12.5, box_thk: 15.0, front_h: front_h.to_mm, runner_len: (depth.to_mm - 100.0), hinge_spacer: spacer_offset.to_mm)

    box_w = dims[:box_w].mm
    box_d = dims[:box_d].mm
    box_thk = dims[:box_thk].mm
    usable_w = box_w + (2 * 12.5.mm)

    ox = origin_x + BOARD_THK + spacer_offset
    oy = y_origin - depth + 20.mm - pull_dist

    # Decorative drawer front
    create_box(group.entities, [ox + 1.5.mm, oy, z_pos], [usable_w - 3.mm, FRONT_THK, front_h], mats[:carcase], "Internal_Drawer_Front")

    # Birch drawer box
    box_ox = ox + 12.5.mm
    box_oy = oy + FRONT_THK
    box_oz = z_pos + 12.mm
    create_box(group.entities, [box_ox, box_oy, box_oz], [box_thk, box_d, box_h], mats[:wood], "Drawer_Side_LH")
    create_box(group.entities, [box_ox + box_w - box_thk, box_oy, box_oz], [box_thk, box_d, box_h], mats[:wood], "Drawer_Side_RH")
    sub_w = box_w - (2 * box_thk)
    create_box(group.entities, [box_ox + box_thk, box_oy, box_oz], [sub_w, box_thk, box_h], mats[:wood], "Drawer_Sub_Front")
    create_box(group.entities, [box_ox + box_thk, box_oy + box_d - box_thk, box_oz], [sub_w, box_thk, box_h], mats[:wood], "Drawer_Back")
    create_box(group.entities, [box_ox + box_thk, box_oy + box_thk, box_oz + 8.mm], [sub_w, box_d - 2*box_thk, 12.mm], mats[:wood], "Drawer_Bottom")

    # Side undermount runners
    create_box(group.entities, [ox + 1.mm, box_oy, z_pos + 2.mm], [11.mm, box_d, 24.mm], mats[:steel], "Runner_LH")
    create_box(group.entities, [ox + usable_w - 12.mm, box_oy, z_pos + 2.mm], [11.mm, box_d, 24.mm], mats[:steel], "Runner_RH")
    group
  end

  # ----------------------------------------------------------------------------
  # 3. WARDROBE MASTER BUILDER
  # ----------------------------------------------------------------------------
  def self.build_wardrobe(parent_ents, type, params, location, mats)
    name = params[:name] || "Wardrobe_#{type.to_s.upcase}"
    robe_grp = parent_ents.add_group
    robe_grp.name = name

    bx = location[:x] || 0.mm
    by = location[:y] || 0.mm
    bz = location[:z] || DEFAULT_PLINTH

    width  = params[:width]  || 900.mm
    height = params[:height] || DEFAULT_HEIGHT
    depth  = params[:depth]  || DEFAULT_DEPTH
    mode   = params[:mode]   || :hybrid
    front_mat = params[:front_mat] || mats[:front_dark]
    inner_w = width - (2 * BOARD_THK)

    # 1. Carcase Construction
    create_box(robe_grp.entities, [bx, by - depth, 0], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
    create_box(robe_grp.entities, [bx + width - BOARD_THK, by - depth, 0], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
    build_structural_shelf(robe_grp.entities, "Bottom_Panel", bx, width, depth, bz, mats, y_origin: by)
    build_structural_shelf(robe_grp.entities, "Roof_Panel", bx, width, depth, height - BOARD_THK, mats, cam_normal: Geom::Vector3d.new(0, 0, -1), full_depth_to_wall: true, y_origin: by)
    build_shotgun_grooved_back(robe_grp.entities, name, bx, by, width, bz, height, mats)

    top_shelf_z = height - 360.mm
    build_structural_shelf(robe_grp.entities, "Upper_Storage_Shelf", bx, width, depth, top_shelf_z, mats, y_origin: by)

    # Kinematic Rule: Internal drawers/pullouts only extend if doors are open!
    # In :hybrid demo mode, doors are rotated open 95° to allow clear extension.
    drawer_pull = (mode == :hybrid ? 280.mm : 0.mm)
    trouser_pull = (mode == :hybrid ? 200.mm : 0.mm)

    # 2. Internal Accessory Configurations (Zero-Collision Geometry)
    case type
    when :single_hanging, :wardrobe_single_hang
      build_clothes_rail(robe_grp.entities, "Long_Clothes_Rail", bx, by, width, depth, top_shelf_z - 55.mm, mats)
      build_adjustable_shelf(robe_grp.entities, "Shoe_Base_Shelf", bx, width, depth, bz + 180.mm, mats, y_origin: by)

    when :double_hanging, :wardrobe_double_hang
      mid_shelf_z = bz + 960.mm
      build_structural_shelf(robe_grp.entities, "Mid_Divider_Shelf", bx, width, depth, mid_shelf_z, mats, y_origin: by)
      build_clothes_rail(robe_grp.entities, "Upper_Clothes_Rail", bx, by, width, depth, top_shelf_z - 55.mm, mats)
      build_clothes_rail(robe_grp.entities, "Lower_Clothes_Rail", bx, by, width, depth, mid_shelf_z - 55.mm, mats)

    when :drawers_combo, :wardrobe_combo
      mid_shelf_z = bz + 1000.mm
      build_structural_shelf(robe_grp.entities, "Mid_Divider_Shelf", bx, width, depth, mid_shelf_z, mats, y_origin: by)
      build_clothes_rail(robe_grp.entities, "Clothes_Rail", bx, by, width, depth, top_shelf_z - 55.mm, mats)

      # 3 Internal Drawers (pitch = 200mm)
      [bz + 20.mm, bz + 230.mm, bz + 440.mm].each_with_index do |dz, idx|
        pull_dist = (idx == 1) ? drawer_pull : 0.mm
        build_internal_wardrobe_drawer(robe_grp.entities, "Internal_Drawer_#{idx+1}", bx, by, width, depth, dz, 140.mm, 180.mm, mats, pull_dist)
      end

      build_trouser_rack(robe_grp.entities, "Trouser_Pullout_Rack", bx, by, width, depth, bz + 680.mm, mats, trouser_pull)

    when :shoe_master, :wardrobe_shoes
      mid_shelf_z = bz + 1150.mm
      build_structural_shelf(robe_grp.entities, "Mid_Divider_Shelf", bx, width, depth, mid_shelf_z, mats, y_origin: by)
      build_clothes_rail(robe_grp.entities, "Clothes_Rail", bx, by, width, depth, top_shelf_z - 55.mm, mats)

      [bz + 30.mm, bz + 250.mm, bz + 470.mm, bz + 690.mm, bz + 910.mm].each_with_index do |sz, idx|
        build_shoe_rack(robe_grp.entities, "Shoe_Rack_Tier_#{idx+1}", bx, by, width, depth, sz, mats)
      end
    end

    # 3. 45° Senior Sash Glass Doors (Kinematically Open in Hybrid Demo Mode)
    door_w = (width - 4.mm) / 2.0
    door_h = height - bz - 3.mm
    door_open_deg = (mode == :hybrid ? 95.0 : 0.0)
    CabinetrixBoxEngine.build_senior_sash_door(robe_grp.entities, bx + 1.5.mm, by - depth - 21.2.mm, bz, door_w, door_h, mats, is_left_hinged: true, open_angle_deg: door_open_deg)
    CabinetrixBoxEngine.build_senior_sash_door(robe_grp.entities, bx + 2.5.mm + door_w, by - depth - 21.2.mm, bz, door_w, door_h, mats, is_left_hinged: false, open_angle_deg: door_open_deg)

    robe_grp
  end
end
