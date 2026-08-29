# ==============================================================================
# CABINETRIX AI — DEDICATED ARCHITECTURAL WARDROBE ENGINE (GEMINI MODULE)
# Pure Function API: CabinetrixWardrobeEngine.build_wardrobe(parent_ents, type, params, location, mats)
#
# Standards & Construction:
#   • CARCASE SYSTEM:
#     - Height: 2160mm (Standard) or 2400mm (Floor-to-Ceiling)
#     - Depth: 600mm Carcase + 21.2mm Sash Face
#     - Plinth: 100mm with recessed black toe kick
#     - Gables span Z: 0 to height (Flush with Roof Panel at Z: height)
#     - Roof Panel sits at Z: height - 18mm with Minifix 15 + Dowels fully enclosed
#     - Shotgun 6mm MDF Grooved Back with Top/Mid/Bottom 100mm Vertical Cleats
# ==============================================================================
require 'sketchup.rb'

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

  def self.build_hanging_rail(parent_ents, name, origin_x, rail_y, rail_z, length, mats)
    group = parent_ents.add_group
    group.name = name

    create_cylinder(group.entities, Geom::Point3d.new(origin_x, rail_y, rail_z), Geom::Vector3d.new(1, 0, 0), 12.5.mm, length, mats[:steel], 20)
    create_box(group.entities, [origin_x, rail_y - 18.mm, rail_z - 25.mm], [4.mm, 36.mm, 50.mm], mats[:steel], "Rail_End_Flange_LH")
    create_box(group.entities, [origin_x + length - 4.mm, rail_y - 18.mm, rail_z - 25.mm], [4.mm, 36.mm, 50.mm], mats[:steel], "Rail_End_Flange_RH")
    group
  end

  # ----------------------------------------------------------------------------
  # 2. INTERNAL UNDERMOUNT DRAWERS & ACCESSORIES (STRICTLY INSIDE CARCASE)
  # ----------------------------------------------------------------------------
  def self.build_internal_wardrobe_drawer(parent_ents, name, ox, by, depth, oz, width, box_h, front_h, pull_dist, mats, has_glass: true)
    group = parent_ents.add_group
    group.name = name

    front_edge_y = by - depth
    closed_y = front_edge_y + 35.0.mm
    box_oy = closed_y - pull_dist

    box_w = width - (2 * 12.5.mm)
    box_d = 450.0.mm
    box_ox = ox + 12.5.mm
    box_oz = oz + 15.0.mm

    create_box(group.entities, [box_ox, box_oy, box_oz], [DRAWER_BOX_THK, box_d, box_h], mats[:wood], "Drawer_Side_LH")
    create_box(group.entities, [box_ox + box_w - DRAWER_BOX_THK, box_oy, box_oz], [DRAWER_BOX_THK, box_d, box_h], mats[:wood], "Drawer_Side_RH")
    inner_w = box_w - (2 * DRAWER_BOX_THK)
    create_box(group.entities, [box_ox + DRAWER_BOX_THK, box_oy, box_oz], [inner_w, DRAWER_BOX_THK, box_h], mats[:wood], "Drawer_Sub_Front")
    create_box(group.entities, [box_ox + DRAWER_BOX_THK, box_oy + box_d - DRAWER_BOX_THK, box_oz], [inner_w, DRAWER_BOX_THK, box_h], mats[:wood], "Drawer_Back_Panel")
    create_box(group.entities, [box_ox + DRAWER_BOX_THK, box_oy + DRAWER_BOX_THK, box_oz + 12.mm], [inner_w, box_d - 2*DRAWER_BOX_THK, 16.0.mm], mats[:wood], "Drawer_Bottom_Panel")

    create_box(group.entities, [ox + 1.0.mm, box_oy, oz + 2.mm], [11.0.mm, box_d, 24.0.mm], mats[:steel], "Actro5D_Slide_LH")
    create_box(group.entities, [ox + width - 12.0.mm, box_oy, oz + 2.mm], [11.0.mm, box_d, 24.0.mm], mats[:steel], "Actro5D_Slide_RH")

    if has_glass
      create_box(group.entities, [box_ox + 25.mm, box_oy - 1.5.mm, box_oz + 15.mm], [inner_w - 20.mm, 4.mm, box_h - 25.mm], mats[:glass], "Tinted_Glass_Front_Insert")
    end
    group
  end

  def self.build_trouser_pullout(parent_ents, ox, by, depth, oz, width, mats)
    group = parent_ents.add_group
    group.name = "Chrome_Trouser_Pullout_Rack"

    front_edge_y = by - depth
    closed_y = front_edge_y + 35.0.mm
    frame_w = width - 40.mm
    frame_d = 450.mm

    create_box(group.entities, [ox + 20.mm, closed_y, oz + 40.mm], [frame_w, 20.mm, 25.mm], mats[:steel], "Trouser_Front_Bar")
    create_box(group.entities, [ox + 20.mm, closed_y + frame_d, oz + 40.mm], [frame_w, 20.mm, 25.mm], mats[:steel], "Trouser_Rear_Bar")

    bars = 8
    spacing = (frame_w - 40.mm) / (bars - 1).to_f
    bars.times do |i|
      bx = ox + 40.mm + (i * spacing)
      create_cylinder(group.entities, Geom::Point3d.new(bx, closed_y + 10.mm, oz + 30.mm), Geom::Vector3d.new(0, 1, 0), 5.mm, frame_d - 10.mm, mats[:steel], 12)
    end
    group
  end

  # ----------------------------------------------------------------------------
  # 3. 45° SENIOR SASH DOORS
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

    outer.length.times do |i|
      nxt = (i + 1) % outer.length
      group.entities.add_face(start_outer[i], start_outer[nxt], end_outer[nxt], end_outer[i])
    end
    inner.length.times do |i|
      nxt = (i + 1) % inner.length
      group.entities.add_face(start_inner[i], end_inner[i], end_inner[nxt], start_inner[nxt])
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
    pane_face = pane.entities.add_face([10.mm, 1.75.mm, 10.mm], [door_w - 10.mm, 1.75.mm, 10.mm], [door_w - 10.mm, 4.75.mm, 10.mm], [10.mm, 4.75.mm, 10.mm])
    pane_face.pushpull(door_h - 20.mm) if pane_face
    pane.material = mats[:glass]
    pane.transform!(transform)
    group
  end

  # ----------------------------------------------------------------------------
  # 4. MASTER WARDROBE FACTORY (Flush Top Panel & Gables at Z: height)
  # ----------------------------------------------------------------------------
  def self.build_wardrobe(parent_ents, type, params, location, mats)
    name   = params[:name] || "Wardrobe_#{type.to_s.upcase}"
    width  = params[:width]  || 900.0.mm
    height = params[:height] || DEFAULT_HEIGHT
    depth  = params[:depth]  || DEFAULT_DEPTH
    plinth = params[:plinth] || DEFAULT_PLINTH
    mode   = params[:mode]   || :hybrid

    bx = location[:x] || 0.mm
    by = location[:y] || 0.mm
    bz = location[:z] || plinth

    robe_grp = parent_ents.add_group
    robe_grp.name = name

    # 1. Carcase Construction (Gables span Z: 0 to height; Roof panel at Z: height - 18mm)
    create_box(robe_grp.entities, [bx, by - depth, 0], [BOARD_THK, depth, height], mats[:carcase], "Gable_LH")
    create_box(robe_grp.entities, [bx + width - BOARD_THK, by - depth, 0], [BOARD_THK, depth, height], mats[:carcase], "Gable_RH")
    build_structural_shelf(robe_grp.entities, "Bottom_Panel", bx, width, depth, bz, mats, y_origin: by)
    build_structural_shelf(robe_grp.entities, "Roof_Panel", bx, width, depth, height - BOARD_THK, mats, cam_normal: Geom::Vector3d.new(0, 0, -1), full_depth_to_wall: true, y_origin: by)
    build_shotgun_grooved_back(robe_grp.entities, name, bx, by, width, bz, height, mats)

    inner_w = width - (2 * BOARD_THK)

    # 2. Interior Modular Equipment
    case type
    when :single_hang
      build_structural_shelf(robe_grp.entities, "Top_Hat_Shelf", bx, width, depth, 1850.mm, mats, y_origin: by)
      build_hanging_rail(robe_grp.entities, "Closet_Hanging_Rail", bx + BOARD_THK, by - depth / 2.0, 1790.mm, inner_w, mats)
      build_adjustable_shelf(robe_grp.entities, "Bottom_Shoe_Shelf", bx, width, depth, bz + 250.mm, mats, y_origin: by)

    when :double_hang
      build_structural_shelf(robe_grp.entities, "Top_Hat_Shelf", bx, width, depth, 2050.mm, mats, y_origin: by)
      build_hanging_rail(robe_grp.entities, "Upper_Hanging_Rail", bx + BOARD_THK, by - depth / 2.0, 1990.mm, inner_w, mats)
      build_structural_shelf(robe_grp.entities, "Mid_Divider_Shelf", bx, width, depth, 1100.mm, mats, y_origin: by)
      build_hanging_rail(robe_grp.entities, "Lower_Hanging_Rail", bx + BOARD_THK, by - depth / 2.0, 1040.mm, inner_w, mats)

    when :linen_tower
      [bz + 350.mm, bz + 750.mm, bz + 1150.mm, bz + 1550.mm, bz + 1900.mm].each_with_index do |sz, idx|
        build_adjustable_shelf(robe_grp.entities, "Linen_Shelf_#{idx+1}", bx, width, depth, sz, mats, y_origin: by)
      end

    when :drawers_combo
      build_structural_shelf(robe_grp.entities, "Mid_Divider_Shelf", bx, width, depth, 950.mm, mats, y_origin: by)
      [bz + 20.mm, bz + 280.mm, bz + 540.mm].each_with_index do |dz, i|
        pull = (mode == :hybrid && i == 0) ? 200.mm : 0.mm
        build_internal_wardrobe_drawer(robe_grp.entities, "Internal_Drawer_#{i+1}", bx + BOARD_THK + 1.5.mm, by, depth, dz, inner_w - 3.mm, 180.mm, 200.mm, pull, mats, has_glass: true)
      end
      build_hanging_rail(robe_grp.entities, "Upper_Hanging_Rail", bx + BOARD_THK, by - depth / 2.0, 1950.mm, inner_w, mats)

    when :trouser_rack
      build_structural_shelf(robe_grp.entities, "Mid_Divider_Shelf", bx, width, depth, 1050.mm, mats, y_origin: by)
      build_internal_wardrobe_drawer(robe_grp.entities, "Jewelry_Velvet_Tray", bx + BOARD_THK + 1.5.mm, by, depth, 960.mm, inner_w - 3.mm, 60.mm, 80.mm, 0.mm, mats, has_glass: false)
      build_trouser_pullout(robe_grp.entities, bx + BOARD_THK, by, depth, bz + 50.mm, inner_w, mats)
      build_hanging_rail(robe_grp.entities, "Upper_Hanging_Rail", bx + BOARD_THK, by - depth / 2.0, 1950.mm, inner_w, mats)
    end

    # 3. Door System
    door_h = height - bz - 3.mm
    door_y = by - depth - 21.2.mm

    if width > 700.mm
      half_w = (width - 6.mm) / 2.0
      build_senior_sash_door(robe_grp.entities, bx + 1.5.mm, door_y, bz, half_w, door_h, mats, is_left_hinged: true)
      build_senior_sash_door(robe_grp.entities, bx + half_w + 3.mm, door_y, bz, half_w, door_h, mats, is_left_hinged: false)
    else
      build_senior_sash_door(robe_grp.entities, bx + 1.5.mm, door_y, bz, width - 3.mm, door_h, mats, is_left_hinged: true)
    end

    robe_grp
  end
end
