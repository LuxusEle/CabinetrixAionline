# ==============================================================================
# CABINETRIX - 18mm L-SHAPE JOINT CONNECTION DEMO
# Demonstrates:
#   1. Minifix (Cam & Bolt System - Häfele 15mm / Hettich Rastex)
#   2. Wooden Dowel (Ø8 x 30mm Fluted Pin)
#   3. Normal / Confirmat Screw (Countersunk 7.0 x 50mm)
#   4. Combined Standard Cabinet L-Joint (Minifix + Dowels + Screws)
# ==============================================================================
require 'sketchup.rb'

module CabinetrixLJointDemo
  # Standard 18mm Panel Cabinet Dimensions
  THICKNESS    = 18.0.mm   # 18mm board thickness
  PANEL_WIDTH  = 200.0.mm  # Length along the joint
  PANEL_HEIGHT = 160.0.mm  # Height of vertical side panel
  PANEL_DEPTH  = 180.0.mm  # Depth of horizontal bottom panel

  # Minifix 15 Standards (Häfele / Hettich 32mm System)
  MINIFIX_CAM_DIAMETER = 15.0.mm
  MINIFIX_CAM_DEPTH    = 12.5.mm
  MINIFIX_B_DIST       = 34.0.mm # Distance from joint edge to cam center (34mm standard)
  MINIFIX_EDGE_BORE_D  = 8.0.mm  # Bolt channel hole in horizontal panel edge
  MINIFIX_EDGE_BORE_L  = 34.0.mm # Bolt channel length
  MINIFIX_FACE_BORE_D  = 5.0.mm  # Face hole in vertical panel for bolt thread
  MINIFIX_FACE_BORE_L  = 11.5.mm # Face hole depth

  # Wooden Dowel Standards
  DOWEL_DIAMETER       = 8.0.mm
  DOWEL_LENGTH         = 30.0.mm
  DOWEL_FACE_DEPTH     = 10.5.mm # Bore into vertical face
  DOWEL_EDGE_DEPTH     = 21.0.mm # Bore into horizontal edge

  # Normal / Confirmat Screw Standards
  SCREW_DIAMETER       = 7.0.mm   # Confirmat shank (or 4.5mm chipboard screw)
  SCREW_HEAD_DIAMETER  = 10.0.mm  # Countersunk head
  SCREW_LENGTH         = 50.0.mm
  SCREW_PILOT_D        = 5.0.mm   # Pilot hole into horizontal edge
  SCREW_PILOT_DEPTH    = 42.0.mm

  # ============================================================================
  # MATERIAL SETUP
  # ============================================================================
  def self.get_materials(model)
    mats = model.materials

    panel_mat = mats['CBX_18mm_Panel'] || mats.add('CBX_18mm_Panel')
    panel_mat.color = Sketchup::Color.new(235, 230, 218)

    edge_mat = mats['CBX_Edge_Banding'] || mats.add('CBX_Edge_Banding')
    edge_mat.color = Sketchup::Color.new(198, 175, 145)

    hole_mat = mats['CBX_Drill_Hole'] || mats.add('CBX_Drill_Hole')
    hole_mat.color = Sketchup::Color.new(45, 42, 38)

    cam_mat = mats['CBX_Minifix_Zinc'] || mats.add('CBX_Minifix_Zinc')
    cam_mat.color = Sketchup::Color.new(165, 170, 175)

    steel_mat = mats['CBX_Hardware_Steel'] || mats.add('CBX_Hardware_Steel')
    steel_mat.color = Sketchup::Color.new(90, 100, 115)

    dowel_mat = mats['CBX_Beech_Dowel'] || mats.add('CBX_Beech_Dowel')
    dowel_mat.color = Sketchup::Color.new(212, 160, 102)

    accent_mat = mats['CBX_Accent'] || mats.add('CBX_Accent')
    accent_mat.color = Sketchup::Color.new(225, 95, 40)

    {
      panel: panel_mat,
      edge: edge_mat,
      hole: hole_mat,
      cam: cam_mat,
      steel: steel_mat,
      dowel: dowel_mat,
      accent: accent_mat
    }
  end

  # ============================================================================
  # GEOMETRY HELPERS (ROBUST & SAFE)
  # ============================================================================
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

  # ============================================================================
  # 3D HARDWARE GENERATORS
  # ============================================================================

  # 1. Minifix Cam (Ø15mm x 12.5mm cylinder with screwdriver cross & arrow)
  def self.create_minifix_cam_model(entities, center, mats)
    cam_group = entities.add_group
    cam_group.name = "Minifix 15 Cam"

    r = MINIFIX_CAM_DIAMETER / 2.0
    h = MINIFIX_CAM_DEPTH

    # Cam Body
    create_cylinder(cam_group.entities, center, Geom::Vector3d.new(0, 0, -1), r, h, mats[:cam], 20)

    # Screwdriver Cross Slot on top face
    slot_w = 1.5.mm
    slot_l = 7.5.mm
    cz = center.z + 0.1.mm

    cross1 = [
      Geom::Point3d.new(center.x - slot_l/2, center.y - slot_w/2, cz),
      Geom::Point3d.new(center.x + slot_l/2, center.y - slot_w/2, cz),
      Geom::Point3d.new(center.x + slot_l/2, center.y + slot_w/2, cz),
      Geom::Point3d.new(center.x - slot_l/2, center.y + slot_w/2, cz)
    ]
    f1 = cam_group.entities.add_face(cross1)
    f1.material = mats[:hole] if f1

    cross2 = [
      Geom::Point3d.new(center.x - slot_w/2, center.y - slot_l/2, cz),
      Geom::Point3d.new(center.x + slot_w/2, center.y - slot_l/2, cz),
      Geom::Point3d.new(center.x + slot_w/2, center.y + slot_l/2, cz),
      Geom::Point3d.new(center.x - slot_w/2, center.y + slot_l/2, cz)
    ]
    f2 = cam_group.entities.add_face(cross2)
    f2.material = mats[:hole] if f2

    # Orientation Arrow Indicator (points towards edge)
    arrow_pts = [
      Geom::Point3d.new(center.x, center.y - r + 1.5.mm, cz),
      Geom::Point3d.new(center.x - 2.0.mm, center.y - r + 4.5.mm, cz),
      Geom::Point3d.new(center.x + 2.0.mm, center.y - r + 4.5.mm, cz)
    ]
    arrow = cam_group.entities.add_face(arrow_pts)
    arrow.material = mats[:accent] if arrow

    cam_group
  end

  # 2. Minifix Connecting Bolt / Pin (Steel connecting rod with thread & collar)
  def self.create_minifix_bolt_model(entities, joint_pos, mats)
    bolt_group = entities.add_group
    bolt_group.name = "Minifix Connecting Bolt"

    x = joint_pos.x
    y = joint_pos.y
    z = joint_pos.z

    # Section A: Threaded shank into vertical panel (Ø5mm, 11mm long in -Y)
    th_center = Geom::Point3d.new(x, y, z)
    create_cylinder(bolt_group.entities, th_center, Geom::Vector3d.new(0, -1, 0), 2.5.mm, 11.0.mm, mats[:steel], 16)

    # Section B: Collar / Stop ring at interface (Ø7.5mm, 1.5mm thick in +Y)
    col_center = Geom::Point3d.new(x, y, z)
    create_cylinder(bolt_group.entities, col_center, Geom::Vector3d.new(0, 1, 0), 3.75.mm, 1.5.mm, mats[:steel], 16)

    # Section C: Smooth pin shank reaching into cam (Ø6.5mm, 26mm long in +Y)
    pin_center = Geom::Point3d.new(x, y + 1.5.mm, z)
    create_cylinder(bolt_group.entities, pin_center, Geom::Vector3d.new(0, 1, 0), 3.25.mm, 26.0.mm, mats[:steel], 16)

    # Section D: Spherical/Locking Head engaging the cam (Ø6.8mm, 6.5mm long in +Y)
    head_center = Geom::Point3d.new(x, y + 27.5.mm, z)
    create_cylinder(bolt_group.entities, head_center, Geom::Vector3d.new(0, 1, 0), 3.4.mm, 6.5.mm, mats[:steel], 16)

    bolt_group
  end

  # 3. Wooden Dowel Pin (Ø8x30mm fluted beech pin)
  def self.create_dowel_pin_model(entities, joint_pos, mats)
    dowel_group = entities.add_group
    dowel_group.name = "Beech Dowel Pin Ø8x30mm"

    x = joint_pos.x
    y = joint_pos.y
    z = joint_pos.z

    # Centered across joint interface: 10mm in vertical (-Y), 20mm in horizontal (+Y)
    start_pt = Geom::Point3d.new(x, y - 9.5.mm, z)
    create_cylinder(dowel_group.entities, start_pt, Geom::Vector3d.new(0, 1, 0), DOWEL_DIAMETER / 2.0, DOWEL_LENGTH, mats[:dowel], 16)

    dowel_group
  end

  # 4. Confirmat / Normal Screw (7.0 x 50mm Countersunk Head Cabinet Screw)
  def self.create_confirmat_screw_model(entities, exterior_pos, mats)
    screw_group = entities.add_group
    screw_group.name = "Confirmat Screw 7.0x50mm"

    x = exterior_pos.x
    y = exterior_pos.y
    z = exterior_pos.z

    # 1. Countersunk Head (Ø10mm over 3.5mm)
    head_pt = Geom::Point3d.new(x, y, z)
    create_cylinder(screw_group.entities, head_pt, Geom::Vector3d.new(0, 1, 0), SCREW_HEAD_DIAMETER / 2.0, 3.5.mm, mats[:steel], 16)

    # 2. Main Threaded Shank (Ø7mm for 46.5mm)
    shank_pt = Geom::Point3d.new(x, y + 3.5.mm, z)
    create_cylinder(screw_group.entities, shank_pt, Geom::Vector3d.new(0, 1, 0), SCREW_DIAMETER / 2.0, 46.5.mm, mats[:steel], 16)

    # 3. Hex Socket / Pozidriv drive on exterior head face
    drive_pt = Geom::Point3d.new(x, y - 0.05.mm, z)
    c_drive = screw_group.entities.add_circle(drive_pt, Geom::Vector3d.new(0, -1, 0), 2.0.mm, 6)
    f_drive = screw_group.entities.add_face(c_drive)
    f_drive.material = mats[:hole] if f_drive

    screw_group
  end

  # ============================================================================
  # DRILL BORES (Visual Indicators on Panels)
  # ============================================================================
  def self.add_drill_bores_minifix(entities, x_pos, joint_y, joint_z, mats)
    # 1. Horizontal Panel Cam Bore (Ø15mm x 12.5mm on top face)
    cam_center = Geom::Point3d.new(x_pos, joint_y + MINIFIX_B_DIST, joint_z + THICKNESS)
    create_cylinder(entities, cam_center, Geom::Vector3d.new(0, 0, -1), MINIFIX_CAM_DIAMETER/2.0, MINIFIX_CAM_DEPTH, mats[:hole], 16)

    # 2. Horizontal Panel Edge Hole (Ø8mm x 34mm from edge to cam)
    edge_center = Geom::Point3d.new(x_pos, joint_y, joint_z + (THICKNESS / 2.0))
    create_cylinder(entities, edge_center, Geom::Vector3d.new(0, 1, 0), MINIFIX_EDGE_BORE_D/2.0, MINIFIX_EDGE_BORE_L, mats[:hole], 16)

    # 3. Vertical Panel Face Hole (Ø5mm x 11.5mm into vertical panel face)
    face_center = Geom::Point3d.new(x_pos, joint_y, joint_z + (THICKNESS / 2.0))
    create_cylinder(entities, face_center, Geom::Vector3d.new(0, -1, 0), MINIFIX_FACE_BORE_D/2.0, MINIFIX_FACE_BORE_L, mats[:hole], 16)
  end

  def self.add_drill_bores_dowel(entities, x_pos, joint_y, joint_z, mats)
    center = Geom::Point3d.new(x_pos, joint_y, joint_z + (THICKNESS / 2.0))
    create_cylinder(entities, center, Geom::Vector3d.new(0, 1, 0), DOWEL_DIAMETER/2.0, DOWEL_EDGE_DEPTH, mats[:hole], 16)
    create_cylinder(entities, center, Geom::Vector3d.new(0, -1, 0), DOWEL_DIAMETER/2.0, DOWEL_FACE_DEPTH, mats[:hole], 16)
  end

  def self.add_drill_bores_screw(entities, x_pos, joint_y, joint_z, mats)
    exterior_y = joint_y - THICKNESS
    center_z   = joint_z + (THICKNESS / 2.0)

    c_head = Geom::Point3d.new(x_pos, exterior_y, center_z)
    create_cylinder(entities, c_head, Geom::Vector3d.new(0, 1, 0), SCREW_HEAD_DIAMETER/2.0, 3.5.mm, mats[:hole], 16)

    c_thru = Geom::Point3d.new(x_pos, exterior_y + 3.5.mm, center_z)
    create_cylinder(entities, c_thru, Geom::Vector3d.new(0, 1, 0), SCREW_DIAMETER/2.0, THICKNESS - 3.5.mm, mats[:hole], 16)

    c_pilot = Geom::Point3d.new(x_pos, joint_y, center_z)
    create_cylinder(entities, c_pilot, Geom::Vector3d.new(0, 1, 0), SCREW_PILOT_D/2.0, SCREW_PILOT_DEPTH, mats[:hole], 16)
  end

  # ============================================================================
  # 3D TEXT & ANNOTATION HELPER (Handles Multi-Line Safely)
  # ============================================================================
  def self.add_annotation_text(entities, text, position, size = 12.mm, mats = nil)
    group = entities.add_group
    group.name = "Annotation"

    lines = text.to_s.split("\n")
    line_spacing = size * 1.35

    lines.each_with_index do |line_str, idx|
      next if line_str.strip.empty?
      line_grp = group.entities.add_group
      line_grp.entities.add_3d_text(line_str, TextAlignLeft, "Arial", true, false, size, 0.0, 0.4.mm, true, 0)
      
      # Offset each line vertically downwards
      offset_z = - (idx * line_spacing)
      tr = Geom::Transformation.new(Geom::Point3d.new(position.x, position.y, position.z + offset_z))
      line_grp.transform!(tr)
      line_grp.material = mats[:accent] if mats
    end

    group
  end

  # ============================================================================
  # SINGLE L-JOINT BUILDER
  # ============================================================================
  def self.build_l_joint(parent_ents, origin, connection_type, mats, gap_offset = 0.mm)
    joint_group = parent_ents.add_group
    joint_group.name = "18mm L-Joint - #{connection_type.to_s.upcase}"

    ox = origin.x
    oy = origin.y
    oz = origin.z

    # 1. Vertical Side Panel (18mm)
    vert_panel = create_box(
      joint_group.entities,
      [ox, oy, oz],
      [PANEL_WIDTH, THICKNESS, PANEL_HEIGHT],
      mats[:panel]
    )
    vert_panel.name = "Vertical Side Panel (18mm)"

    joint_y = oy + THICKNESS
    joint_z = oz

    # 2. Horizontal Bottom Panel (18mm)
    horiz_panel = create_box(
      joint_group.entities,
      [ox, joint_y + gap_offset, joint_z],
      [PANEL_WIDTH, PANEL_DEPTH, THICKNESS],
      mats[:panel]
    )
    horiz_panel.name = "Horizontal Bottom Panel (18mm)"

    mid_x   = ox + (PANEL_WIDTH / 2.0)
    pos_x1  = ox + 45.0.mm
    pos_x2  = ox + PANEL_WIDTH - 45.0.mm

    case connection_type
    when :minifix
      [pos_x1, pos_x2].each do |x|
        cam_top_center = Geom::Point3d.new(x, joint_y + gap_offset + MINIFIX_B_DIST, joint_z + THICKNESS)
        create_minifix_cam_model(joint_group.entities, cam_top_center, mats)

        bolt_joint_pt = Geom::Point3d.new(x, joint_y, joint_z + (THICKNESS / 2.0))
        create_minifix_bolt_model(joint_group.entities, bolt_joint_pt, mats)

        add_drill_bores_minifix(joint_group.entities, x, joint_y, joint_z, mats)
      end
      add_annotation_text(joint_group.entities, "1. MINIFIX 15 (CAM & BOLT)", Geom::Point3d.new(ox, oy - 15.mm, oz + PANEL_HEIGHT + 25.mm), 13.mm, mats)
      add_annotation_text(joint_group.entities, "Cam: D15x12.5mm (B=34mm)\nEdge Bore: D8x34mm\nFace Bore: D5x11.5mm", Geom::Point3d.new(ox, oy + 45.mm, oz + PANEL_HEIGHT + 15.mm), 8.mm, mats)

    when :dowel
      [pos_x1, mid_x, pos_x2].each do |x|
        dowel_pt = Geom::Point3d.new(x, joint_y + (gap_offset / 2.0), joint_z + (THICKNESS / 2.0))
        create_dowel_pin_model(joint_group.entities, dowel_pt, mats)

        add_drill_bores_dowel(joint_group.entities, x, joint_y, joint_z, mats)
      end
      add_annotation_text(joint_group.entities, "2. WOODEN DOWEL (D8x30mm)", Geom::Point3d.new(ox, oy - 15.mm, oz + PANEL_HEIGHT + 25.mm), 13.mm, mats)
      add_annotation_text(joint_group.entities, "Beech Dowel: D8x30mm\nHoriz Edge Bore: D8x21mm\nVert Face Bore: D8x11mm", Geom::Point3d.new(ox, oy + 45.mm, oz + PANEL_HEIGHT + 15.mm), 8.mm, mats)

    when :screw
      [pos_x1, pos_x2].each do |x|
        exterior_pt = Geom::Point3d.new(x, oy, joint_z + (THICKNESS / 2.0))
        create_confirmat_screw_model(joint_group.entities, exterior_pt, mats)

        add_drill_bores_screw(joint_group.entities, x, joint_y, joint_z, mats)
      end
      add_annotation_text(joint_group.entities, "3. CONFIRMAT SCREW (7x50)", Geom::Point3d.new(ox, oy - 15.mm, oz + PANEL_HEIGHT + 25.mm), 13.mm, mats)
      add_annotation_text(joint_group.entities, "Confirmat: 7.0x50mm\nVert Panel: D7mm + D10 Bevel\nHoriz Pilot: D5x42mm", Geom::Point3d.new(ox, oy + 45.mm, oz + PANEL_HEIGHT + 15.mm), 8.mm, mats)

    when :combined
      dowel_x1   = ox + 35.0.mm
      minifix_x1 = ox + 75.0.mm
      minifix_x2 = ox + PANEL_WIDTH - 75.0.mm
      dowel_x2   = ox + PANEL_WIDTH - 35.0.mm

      [minifix_x1, minifix_x2].each do |x|
        cam_top_center = Geom::Point3d.new(x, joint_y + gap_offset + MINIFIX_B_DIST, joint_z + THICKNESS)
        create_minifix_cam_model(joint_group.entities, cam_top_center, mats)
        bolt_joint_pt = Geom::Point3d.new(x, joint_y, joint_z + (THICKNESS / 2.0))
        create_minifix_bolt_model(joint_group.entities, bolt_joint_pt, mats)
        add_drill_bores_minifix(joint_group.entities, x, joint_y, joint_z, mats)
      end

      [dowel_x1, dowel_x2].each do |x|
        dowel_pt = Geom::Point3d.new(x, joint_y + (gap_offset / 2.0), joint_z + (THICKNESS / 2.0))
        create_dowel_pin_model(joint_group.entities, dowel_pt, mats)
        add_drill_bores_dowel(joint_group.entities, x, joint_y, joint_z, mats)
      end

      exterior_pt = Geom::Point3d.new(mid_x, oy, joint_z + (THICKNESS / 2.0))
      create_confirmat_screw_model(joint_group.entities, exterior_pt, mats)
      add_drill_bores_screw(joint_group.entities, mid_x, joint_y, joint_z, mats)

      add_annotation_text(joint_group.entities, "4. STANDARD HYBRID JOINT", Geom::Point3d.new(ox, oy - 15.mm, oz + PANEL_HEIGHT + 25.mm), 13.mm, mats)
      add_annotation_text(joint_group.entities, "Complete Knock-Down Joint\n2x Minifix + 2x Dowels + 1x Screw\nIndustry 32mm System", Geom::Point3d.new(ox, oy + 45.mm, oz + PANEL_HEIGHT + 15.mm), 8.mm, mats)
    end

    joint_group
  end

  # ============================================================================
  # MAIN DEMO SCENE GENERATOR
  # ============================================================================
  def self.create_demo_scene(exploded: false)
    model = Sketchup.active_model
    model.start_operation("Demo 18mm L-Joint Connections", true)

    begin
      entities = model.active_entities
      mats = get_materials(model)

      spacing_x = 280.0.mm
      gap = exploded ? 25.0.mm : 0.0.mm

      master_group = entities.add_group
      master_group.name = "Cabinetrix - 18mm L-Joint Fasteners Demo"

      # 1. Minifix Only
      build_l_joint(master_group.entities, Geom::Point3d.new(0 * spacing_x, 0, 0), :minifix, mats, gap)

      # 2. Wooden Dowel Only
      build_l_joint(master_group.entities, Geom::Point3d.new(1 * spacing_x, 0, 0), :dowel, mats, gap)

      # 3. Confirmat Screw Only
      build_l_joint(master_group.entities, Geom::Point3d.new(2 * spacing_x, 0, 0), :screw, mats, gap)

      # 4. Combined Hybrid Joint
      build_l_joint(master_group.entities, Geom::Point3d.new(3 * spacing_x, 0, 0), :combined, mats, gap)

      # Title Banner
      add_annotation_text(
        master_group.entities,
        "CABINETRIX 18mm L-SHAPE CORNER JOINT FASTENER COMPARISON",
        Geom::Point3d.new(0, -60.mm, PANEL_HEIGHT + 60.mm),
        18.mm,
        mats
      )

      model.active_view.zoom_extents if model.active_view

      model.commit_operation
      puts "================================================================="
      puts " Cabinetrix 18mm L-Joint Demo successfully created!"
      puts " Demonstrated: Minifix 15, Wooden Dowels (8x30), Confirmat Screw (7x50)"
      puts "================================================================="
    rescue => e
      model.abort_operation
      puts "Error creating L-Joint demo: #{e.message}"
      puts e.backtrace.join("\n")
    end
  end
end

# ==============================================================================
# MENU & TOOLBAR REGISTRATION FOR SKETCHUP
# ==============================================================================
if defined?(UI) && UI.respond_to?(:menu)
  unless file_loaded?(__FILE__)
    plugins_menu = UI.menu('Plugins')
    cbx_menu = plugins_menu.add_submenu('Cabinetrix Fastener Demos')
    
    cbx_menu.add_item('Generate 18mm L-Joint Demo (Standard)') do
      CabinetrixLJointDemo.create_demo_scene(exploded: false)
    end

    cbx_menu.add_item('Generate 18mm L-Joint Demo (Exploded View)') do
      CabinetrixLJointDemo.create_demo_scene(exploded: true)
    end

    file_loaded(__FILE__)
  end
end

# Auto-run when loaded directly into SketchUp (suppressed when the engine loads
# it for connector reuse by setting the CABINETRIX_DEMO_NO_AUTORUN flag first).
unless defined?(CABINETRIX_DEMO_NO_AUTORUN) && CABINETRIX_DEMO_NO_AUTORUN
  CabinetrixLJointDemo.create_demo_scene if defined?(Sketchup) && Sketchup.active_model
end
