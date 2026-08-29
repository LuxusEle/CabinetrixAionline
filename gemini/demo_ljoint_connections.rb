# =============================================================================
# CABINETRIX AI — 18mm L-JOINT FASTENER COMPARISON (GEMINI MODULE)
# Models Minifix 15, Wooden Dowel (Ø8x30mm), and Confirmat Screw (7x50mm)
# =============================================================================
require 'sketchup.rb'

module CabinetrixLJointDemo
  BOARD_THK = 18.0.mm
  PANEL_WIDTH = 250.0.mm
  PANEL_LENGTH = 300.0.mm

  def self.get_materials(model)
    mats = model.materials
    m_wood1 = mats['CBX_Board_Oak'] || mats.add('CBX_Board_Oak')
    m_wood1.color = Sketchup::Color.new(220, 205, 185)

    m_wood2 = mats['CBX_Board_Anthracite'] || mats.add('CBX_Board_Anthracite')
    m_wood2.color = Sketchup::Color.new(50, 52, 58)

    m_cam = mats['CBX_Zinc_Cam'] || mats.add('CBX_Zinc_Cam')
    m_cam.color = Sketchup::Color.new(185, 190, 195)

    m_steel = mats['CBX_Steel_Bolt'] || mats.add('CBX_Steel_Bolt')
    m_steel.color = Sketchup::Color.new(80, 95, 115)

    m_dowel = mats['CBX_Beech_Dowel'] || mats.add('CBX_Beech_Dowel')
    m_dowel.color = Sketchup::Color.new(210, 165, 110)

    m_hole = mats['CBX_Hole_Dark'] || mats.add('CBX_Hole_Dark')
    m_hole.color = Sketchup::Color.new(25, 25, 25)

    m_indicator = mats['CBX_Arrow_Orange'] || mats.add('CBX_Arrow_Orange')
    m_indicator.color = Sketchup::Color.new(245, 90, 20)

    {
      vert_board: m_wood1,
      horiz_board: m_wood2,
      cam: m_cam,
      steel: m_steel,
      dowel: m_dowel,
      hole: m_hole,
      arrow: m_indicator
    }
  end

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

  def self.build_minifix_bolt_model(entities, pt_center, dir_vector, mats)
    group = entities.add_group
    group.name = "Minifix Bolt Assembly"
    inv_dir = dir_vector.reverse

    # Threaded shaft into vertical panel (Ø5mm x 11mm)
    create_cylinder(group.entities, pt_center, inv_dir, 2.5.mm, 11.0.mm, mats[:steel], 12)
    # Stop collar ring (Ø7.5mm x 1.5mm)
    create_cylinder(group.entities, pt_center, dir_vector, 3.75.mm, 1.5.mm, mats[:steel], 12)
    # Connecting pin shank (Ø6.5mm x 32.5mm)
    pin_start = Geom::Point3d.new(
      pt_center.x + dir_vector.x * 1.5.mm,
      pt_center.y + dir_vector.y * 1.5.mm,
      pt_center.z + dir_vector.z * 1.5.mm
    )
    create_cylinder(group.entities, pin_start, dir_vector, 3.25.mm, 32.5.mm, mats[:steel], 12)
    group
  end

  def self.build_minifix_cam_model(entities, cam_center, normal, mats)
    group = entities.add_group
    group.name = "Minifix 15 Cam Lock"

    c_rim = group.entities.add_circle(cam_center, normal, 7.8.mm, 20)
    f_rim = group.entities.add_face(c_rim)
    f_rim.material = mats[:hole] if f_rim

    inward_dir = normal.reverse
    create_cylinder(group.entities, cam_center, inward_dir, 7.5.mm, 12.5.mm, mats[:cam], 20)

    # Cross drive
    slot_w = 1.4.mm
    slot_l = 7.5.mm
    cz = cam_center.z + 0.1.mm
    cx = cam_center.x
    cy = cam_center.y

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

    # Orange indicator arrow
    f_arr = group.entities.add_face([
      Geom::Point3d.new(cx - 3.5.mm, cy, cz),
      Geom::Point3d.new(cx - 0.8.mm, cy - 2.2.mm, cz),
      Geom::Point3d.new(cx - 0.8.mm, cy + 2.2.mm, cz)
    ])
    f_arr.material = mats[:arrow] if f_arr

    group
  end

  def self.build_dowel_model(entities, pt_center, dir_vector, mats)
    group = entities.add_group
    group.name = "Wooden Dowel (Ø8x30mm)"
    dowel_start = Geom::Point3d.new(
      pt_center.x - dir_vector.x * 10.0.mm,
      pt_center.y - dir_vector.y * 10.0.mm,
      pt_center.z - dir_vector.z * 10.0.mm
    )
    create_cylinder(group.entities, dowel_start, dir_vector, 4.0.mm, 30.0.mm, mats[:dowel], 16)
    group
  end

  def self.build_confirmat_screw_model(entities, pt_center, dir_vector, mats)
    group = entities.add_group
    group.name = "Confirmat Screw (7x50mm)"
    screw_start = Geom::Point3d.new(
      pt_center.x - dir_vector.x * 18.0.mm,
      pt_center.y - dir_vector.y * 18.0.mm,
      pt_center.z - dir_vector.z * 18.0.mm
    )
    create_cylinder(group.entities, screw_start, dir_vector, 5.0.mm, 2.0.mm, mats[:steel], 16)
    screw_shank = Geom::Point3d.new(
      screw_start.x + dir_vector.x * 2.0.mm,
      screw_start.y + dir_vector.y * 2.0.mm,
      screw_start.z + dir_vector.z * 2.0.mm
    )
    create_cylinder(group.entities, screw_shank, dir_vector, 3.5.mm, 48.0.mm, mats[:steel], 16)
    group
  end

  def self.build_l_joint(parent_ents, origin, fastener_type, mats)
    joint_group = parent_ents.add_group
    joint_group.name = "L-Joint Demo (#{fastener_type.to_s.upcase})"

    ox = origin.x
    oy = origin.y
    oz = origin.z

    t = BOARD_THK
    w = PANEL_WIDTH
    l = PANEL_LENGTH

    # 1. Vertical Side Panel (18mm x 250mm x 300mm)
    create_box(joint_group.entities, [ox, oy, oz], [t, w, l], mats[:vert_board])

    # 2. Horizontal Bottom Panel (250mm x 250mm x 18mm)
    h_len = l - t
    create_box(joint_group.entities, [ox + t, oy, oz], [h_len, w, t], mats[:horiz_board])

    dir_vec = Geom::Vector3d.new(1, 0, 0)
    z_joint = oz + (t / 2.0)
    b_dist = 34.0.mm

    pos_y = [oy + 50.0.mm, oy + w - 50.0.mm]

    pos_y.each do |y_pos|
      bolt_pt = Geom::Point3d.new(ox + t, y_pos, z_joint)

      case fastener_type
      when :minifix
        build_minifix_bolt_model(joint_group.entities, bolt_pt, dir_vec, mats)
        cam_pt = Geom::Point3d.new(ox + t + b_dist, y_pos, oz + t + 0.2.mm)
        build_minifix_cam_model(joint_group.entities, cam_pt, Geom::Vector3d.new(0, 0, 1), mats)
      when :dowel
        build_dowel_model(joint_group.entities, bolt_pt, dir_vec, mats)
      when :screw
        build_confirmat_screw_model(joint_group.entities, bolt_pt, dir_vec, mats)
      when :combined
        build_minifix_bolt_model(joint_group.entities, bolt_pt, dir_vec, mats)
        cam_pt = Geom::Point3d.new(ox + t + b_dist, y_pos, oz + t + 0.2.mm)
        build_minifix_cam_model(joint_group.entities, cam_pt, Geom::Vector3d.new(0, 0, 1), mats)

        dowel_y = (y_pos == pos_y.first) ? y_pos + 32.0.mm : y_pos - 32.0.mm
        dowel_pt = Geom::Point3d.new(ox + t, dowel_y, z_joint)
        build_dowel_model(joint_group.entities, dowel_pt, dir_vec, mats)
      end
    end

    joint_group
  end

  def self.create_demo_scene
    model = Sketchup.active_model
    model.start_operation("18mm L-Joint Fastener Comparison (Gemini)", true)

    begin
      entities = model.active_entities
      mats = get_materials(model)

      types = [:minifix, :dowel, :screw, :combined]
      spacing = 380.0.mm

      types.each_with_index do |type, idx|
        origin = Geom::Point3d.new(idx * spacing, 0, 0)
        build_l_joint(entities, origin, type, mats)
      end

      model.active_view.zoom_extents if model.active_view
      model.commit_operation
      puts "✅ [GEMINI] 18mm L-Joint Fastener Demo generated successfully!"
    rescue => e
      model.abort_operation
      puts "Error creating L-Joint demo: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end

unless defined?($CABINETRIX_DEMO_NO_AUTORUN) && $CABINETRIX_DEMO_NO_AUTORUN
  CabinetrixLJointDemo.create_demo_scene if defined?(Sketchup) && Sketchup.active_model
end
