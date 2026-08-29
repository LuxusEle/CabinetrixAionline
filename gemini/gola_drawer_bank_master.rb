# ==============================================================================
# CABINETRIX AI — MASTER 2x DRAWER BANK WITH GOLA & MINIFIX 15 (GEMINI)
# ==============================================================================
require 'sketchup.rb'
require 'json'

module CabinetrixMasterGola
  BOARD_THK         = 18.0.mm
  FRONT_THK         = 18.0.mm
  DRAWER_BOX_THK    = 15.0.mm
  BACK_THK          = 6.0.mm
  
  BANK_COUNT        = 2
  BANK_WIDTH        = 600.0.mm
  TOTAL_WIDTH       = (BANK_COUNT * BANK_WIDTH)
  CARCASE_HEIGHT    = 720.0.mm
  CARCASE_DEPTH     = 560.0.mm
  PLINTH_HEIGHT     = 100.0.mm
  PLINTH_SETBACK    = 50.0.mm

  GOLA_DEPTH        = 26.0.mm
  L_GOLA_H          = 59.0.mm
  C_GOLA_H          = 73.5.mm
  C_GOLA_Z0         = 330.0.mm

  MINIFIX_CAM_D     = 15.0.mm
  MINIFIX_CAM_DEPTH = 12.5.mm
  MINIFIX_B_DIST    = 34.0.mm
  DOWEL_D           = 8.0.mm
  DOWEL_LEN         = 30.0.mm

  UPPER_FRONT_H     = 310.0.mm
  LOWER_FRONT_H     = 355.0.mm

  def self.get_materials(model)
    mats = model.materials
    carcase_mat = mats['CBX_Melamine_White'] || mats.add('CBX_Melamine_White')
    carcase_mat.color = Sketchup::Color.new(245, 245, 242)
    carcase_mat.alpha = 1.0

    front_mat = mats['CBX_Front_Anthracite'] || mats.add('CBX_Front_Anthracite')
    front_mat.color = Sketchup::Color.new(45, 48, 54)
    front_mat.alpha = 1.0

    gola_mat = mats['CBX_Alu_Black_Anodized'] || mats.add('CBX_Alu_Black_Anodized')
    gola_mat.color = Sketchup::Color.new(25, 27, 30)
    gola_mat.alpha = 1.0

    wood_mat = mats['CBX_Natural_Birch'] || mats.add('CBX_Natural_Birch')
    wood_mat.color = Sketchup::Color.new(225, 212, 190)
    wood_mat.alpha = 1.0

    cam_mat = mats['CBX_Minifix_Zinc'] || mats.add('CBX_Minifix_Zinc')
    cam_mat.color = Sketchup::Color.new(180, 185, 190)
    cam_mat.alpha = 1.0

    steel_mat = mats['CBX_Stainless_Steel'] || mats.add('CBX_Stainless_Steel')
    steel_mat.color = Sketchup::Color.new(140, 145, 155)
    steel_mat.alpha = 1.0

    dowel_mat = mats['CBX_Beech_Dowel'] || mats.add('CBX_Beech_Dowel')
    dowel_mat.color = Sketchup::Color.new(215, 160, 95)
    dowel_mat.alpha = 1.0

    hole_mat = mats['CBX_CNC_Bore_Dark'] || mats.add('CBX_CNC_Bore_Dark')
    hole_mat.color = Sketchup::Color.new(20, 20, 20)
    hole_mat.alpha = 1.0

    accent_mat = mats['CBX_Indicator_Orange'] || mats.add('CBX_Indicator_Orange')
    accent_mat.color = Sketchup::Color.new(240, 80, 20)
    accent_mat.alpha = 1.0

    plinth_mat = mats['CBX_Plinth_Black'] || mats.add('CBX_Plinth_Black')
    plinth_mat.color = Sketchup::Color.new(35, 36, 38)
    plinth_mat.alpha = 1.0

    {
      carcase: carcase_mat, front: front_mat, gola: gola_mat, wood: wood_mat,
      cam: cam_mat, steel: steel_mat, dowel: dowel_mat, hole: hole_mat,
      accent: accent_mat, plinth: plinth_mat
    }
  end

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

  def self.build_minifix_joint(parent_ents, bolt_center, dir_vector, mats, cam_normal: Geom::Vector3d.new(0, 0, 1), cam_offset_dist: 9.0.mm, bounds_y: nil)
    group = parent_ents.add_group
    group.name = "Minifix_15_Set"

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

    arr_dir_x = -dir_vector.x * 3.5.mm
    f_arr = group.entities.add_face([
      Geom::Point3d.new(cx + arr_dir_x, cy, cz),
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

  def self.build_gola_profile(parent_ents, profile_type, length, origin, mats)
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

    pts = yz.map { |y, z| Geom::Point3d.new(ox, oy - y, oz + z) }

    face = group.entities.add_face(pts)
    if face
      face.reverse! if face.normal.x < 0
      face.pushpull(length)
    end
    group.material = mats[:gola]
    group
  end

  def self.build_hettich_undermount_drawer(parent_ents, box_origin, width, depth, box_height, front_h, front_z_offset, pull_offset, mats, front_mat)
    drawer_unit = parent_ents.add_group
    drawer_unit.name = "Hettich_Undermount_Drawer_#{width.to_mm.round}x#{front_h.to_mm.round}"

    ox = box_origin.x
    oy = box_origin.y - pull_offset
    oz = box_origin.z

    front_oz = oz + front_z_offset
    create_box(drawer_unit.entities, [ox, oy - FRONT_THK, front_oz], [width, FRONT_THK, front_h], front_mat, "Drawer_Front_Face")

    box_w = width - (2 * 12.5.mm)
    box_d = depth - 30.0.mm
    box_ox = ox + 12.5.mm
    box_oz = oz + 15.0.mm

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

    drawer_unit
  end

  def self.build_complete_system(parent_ents, origin, mats, mode: :hybrid)
    unit_group = parent_ents.add_group
    unit_group.name = "Box_Gola_Drawer_Bank_2x600W"

    ox = origin.x
    oy = origin.y
    oz = origin.z + PLINTH_HEIGHT

    bay_internal_w = BANK_WIDTH - (1.5 * BOARD_THK)
    b1_ox = ox + BOARD_THK
    b2_ox = ox + BANK_WIDTH + (BOARD_THK / 2.0)

    # 3x Machined Gola Side Gables
    [ox, ox + BANK_WIDTH - (BOARD_THK / 2.0), ox + TOTAL_WIDTH - BOARD_THK].each_with_index do |gx, i|
      pts = [
        Geom::Point3d.new(gx, oy, oz),
        Geom::Point3d.new(gx, oy - CARCASE_DEPTH, oz),
        Geom::Point3d.new(gx, oy - CARCASE_DEPTH, oz + C_GOLA_Z0),
        Geom::Point3d.new(gx, oy - CARCASE_DEPTH + GOLA_DEPTH, oz + C_GOLA_Z0),
        Geom::Point3d.new(gx, oy - CARCASE_DEPTH + GOLA_DEPTH, oz + C_GOLA_Z0 + C_GOLA_H),
        Geom::Point3d.new(gx, oy - CARCASE_DEPTH, oz + C_GOLA_Z0 + C_GOLA_H),
        Geom::Point3d.new(gx, oy - CARCASE_DEPTH, oz + CARCASE_HEIGHT - L_GOLA_H),
        Geom::Point3d.new(gx, oy - CARCASE_DEPTH + GOLA_DEPTH, oz + CARCASE_HEIGHT - L_GOLA_H),
        Geom::Point3d.new(gx, oy - CARCASE_DEPTH + GOLA_DEPTH, oz + CARCASE_HEIGHT),
        Geom::Point3d.new(gx, oy, oz + CARCASE_HEIGHT)
      ]
      f_g = unit_group.entities.add_face(pts)
      if f_g
        f_g.reverse! if f_g.normal.x < 0
        f_g.pushpull(BOARD_THK)
      end
    end

    # 2x Bottom Panels with 8x Minifix Sets
    [b1_ox, b2_ox].each do |bx|
      create_box(unit_group.entities, [bx, oy - CARCASE_DEPTH, oz], [bay_internal_w, CARCASE_DEPTH, BOARD_THK], mats[:carcase], "Bottom_Panel")
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bx, oy - 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, bounds_y: [oy - CARCASE_DEPTH, oy])
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bx, oy - CARCASE_DEPTH + 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, bounds_y: [oy - CARCASE_DEPTH, oy])
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bx + bay_internal_w, oy - 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, bounds_y: [oy - CARCASE_DEPTH, oy])
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bx + bay_internal_w, oy - CARCASE_DEPTH + 70.mm, oz + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, bounds_y: [oy - CARCASE_DEPTH, oy])
    end

    # Top Rear Stretchers (100mm)
    stretcher_z = oz + CARCASE_HEIGHT - BOARD_THK
    [b1_ox, b2_ox].each do |bx|
      create_box(unit_group.entities, [bx, oy - 100.mm, stretcher_z], [bay_internal_w, 100.mm, BOARD_THK], mats[:carcase], "Top_Rear_Stretcher")
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bx, oy - 50.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [oy - 100.mm, oy])
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bx + bay_internal_w, oy - 50.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [oy - 100.mm, oy])
    end

    # Top Front L-Gola Sub-Stretchers (80mm)
    front_sub_y = oy - CARCASE_DEPTH + GOLA_DEPTH
    [b1_ox, b2_ox].each do |bx|
      create_box(unit_group.entities, [bx, front_sub_y, stretcher_z], [bay_internal_w, 80.mm, BOARD_THK], mats[:carcase], "Top_Front_Gola_Stretcher")
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bx, front_sub_y + 40.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [front_sub_y, front_sub_y + 80.mm])
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bx + bay_internal_w, front_sub_y + 40.mm, stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [front_sub_y, front_sub_y + 80.mm])
    end

    # Mid C-Gola Tie Stretchers (60mm)
    mid_stretcher_z = oz + C_GOLA_Z0 + C_GOLA_H - BOARD_THK
    [b1_ox, b2_ox].each do |bx|
      create_box(unit_group.entities, [bx, front_sub_y, mid_stretcher_z], [bay_internal_w, 60.mm, BOARD_THK], mats[:carcase], "Mid_C_Gola_Stretcher")
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bx, front_sub_y + 30.mm, mid_stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [front_sub_y, front_sub_y + 60.mm])
      build_minifix_joint(unit_group.entities, Geom::Point3d.new(bx + bay_internal_w, front_sub_y + 30.mm, mid_stretcher_z + BOARD_THK/2.0), Geom::Vector3d.new(-1, 0, 0), mats, cam_normal: Geom::Vector3d.new(0, 0, -1), bounds_y: [front_sub_y, front_sub_y + 60.mm])
    end

    # Solid Back Panels
    [b1_ox, b2_ox].each do |bx|
      create_box(unit_group.entities, [bx, oy - 18.mm, oz + BOARD_THK], [bay_internal_w, BACK_THK, CARCASE_HEIGHT - BOARD_THK - 10.mm], mats[:carcase], "Back_Panel")
    end

    # Continuous Gola Extrusions
    build_gola_profile(unit_group.entities, :l, TOTAL_WIDTH, Geom::Point3d.new(ox, oy - CARCASE_DEPTH + GOLA_DEPTH, oz + CARCASE_HEIGHT - L_GOLA_H), mats)
    build_gola_profile(unit_group.entities, :c, TOTAL_WIDTH, Geom::Point3d.new(ox, oy - CARCASE_DEPTH + GOLA_DEPTH, oz + C_GOLA_Z0), mats)

    # 4x Undermount Drawers with True Gola Finger Pull Overlaps
    unless mode == :carcase_only
      drawer_front_w = BANK_WIDTH - 3.0.mm

      [0, 1].each do |bank_idx|
        d_ox = ox + (bank_idx * BANK_WIDTH) + 1.5.mm
        pull_dist_upper = (mode == :hybrid && bank_idx == 0) ? 220.0.mm : 0.0.mm
        pull_dist_lower = (mode == :hybrid && bank_idx == 0) ? 350.0.mm : 0.0.mm

        # Lower Pan Drawer
        build_hettich_undermount_drawer(unit_group.entities, Geom::Point3d.new(d_ox, oy - CARCASE_DEPTH, oz + 12.mm), drawer_front_w, CARCASE_DEPTH, 200.mm, LOWER_FRONT_H, -9.mm, pull_dist_lower, mats, mats[:front])
        # Upper Drawer
        build_hettich_undermount_drawer(unit_group.entities, Geom::Point3d.new(d_ox, oy - CARCASE_DEPTH, oz + 390.mm), drawer_front_w, CARCASE_DEPTH, 140.mm, UPPER_FRONT_H, -15.mm, pull_dist_upper, mats, mats[:front])
      end
    end

    # Plinth Base
    create_box(unit_group.entities, [ox + 10.mm, oy - CARCASE_DEPTH + PLINTH_SETBACK, origin.z], [TOTAL_WIDTH - 20.mm, BOARD_THK, PLINTH_HEIGHT], mats[:plinth], "Plinth_Toe_Kick")

    unit_group
  end
end

if defined?(Sketchup) && Sketchup.active_model && (!defined?(CABINETRIX_NO_AUTORUN) || !CABINETRIX_NO_AUTORUN)
  CabinetrixMasterGola.build_complete_system(Sketchup.active_model.active_entities, Geom::Point3d.new(0, 0, 0), CabinetrixMasterGola.get_materials(Sketchup.active_model), mode: :hybrid)
end
