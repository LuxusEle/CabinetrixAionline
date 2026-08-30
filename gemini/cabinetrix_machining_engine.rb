# ==============================================================================
# CABINETRIX AI — MASTER CONNECTORS, HINGES, RUNNERS & RAILS ENGINE
# File: gemini/cabinetrix_machining_engine.rb
#
# Production Standard:
#   • Standard System 32 Woodworking Machining Primitives.
#   • Comprehensive Industrial Hardware Catalog:
#     1. CONNECTORS: Minifix 15, Cabineo 8/12, Rafix 20, Wooden Dowels, Confirmat 7x50.
#     2. HINGES: Blum 110° Overlay, 155° Zero-Protrusion (Space Tower), Inset, Bi-Fold 134°, Free Stop Flap Lift.
#     3. RUNNERS: Hettich Actro 5D Undermount (250..550mm), Heavy Side Ball-Bearing.
#     4. RAILS: Wardrobe Oval Chrome Rail (30x15mm) + Flanges, SCILM L/C Gola Profiles, Wall Suspension Track.
#   • Dual Output: Generates 3D Visual Geometry in SketchUp AND CNC Machining Toolpaths for Export.
# ==============================================================================
require 'sketchup.rb'

module CabinetrixMachiningEngine
  # ----------------------------------------------------------------------------
  # 1. HARDWARE CATALOG DEFINITIONS
  # ----------------------------------------------------------------------------
  CONNECTOR_CATALOG = {
    minifix_15: {
      name: "Häfele Minifix 15 Cam & Bolt",
      face_bore_dia: 15.0, face_bore_depth: 12.5, edge_distance: 34.0,
      edge_bore_dia: 8.0, edge_bore_depth: 34.0, gable_pilot_dia: 5.0, gable_pilot_depth: 11.5,
      sku: "HAF-MINIFIX-15", unit_cost: 0.45
    },
    cabineo_8_12: {
      name: "Lamello Cabineo 8/12 One-Piece Connector",
      pocket_length: 33.8, pocket_width: 15.0, pocket_depth: 10.0,
      through_hole_dia: 5.0, gable_pilot_dia: 5.0, gable_pilot_depth: 12.0,
      edge_drilling_required: false, sku: "LAM-CABINEO-12", unit_cost: 0.65
    },
    rafix_20: {
      name: "Häfele Rafix 20 Shelf Connector",
      face_bore_dia: 20.0, face_bore_depth: 14.2, edge_distance: 9.5,
      gable_pilot_dia: 5.0, gable_pilot_depth: 11.5, sku: "HAF-RAFIX-20", unit_cost: 0.38
    },
    wooden_dowel_8x30: {
      name: "Hardwood Ribbed Dowel 8x30mm",
      face_bore_dia: 8.0, face_bore_depth: 12.0, edge_bore_dia: 8.0, edge_bore_depth: 20.0,
      sku: "DOWEL-8X30", unit_cost: 0.05
    },
    confirmat_7x50: {
      name: "Confirmat Stepped Assembly Screw 7x50mm",
      clearance_hole_dia: 7.0, countersink_dia: 10.0, countersink_depth: 2.0,
      pilot_hole_dia: 5.0, pilot_hole_depth: 38.0, sku: "CONF-7X50", unit_cost: 0.12
    }
  }

  HINGE_CATALOG = {
    blum_110_overlay: {
      name: "Blum CLIP top BLUMOTION 110° (Full Overlay)",
      cup_dia: 35.0, cup_depth: 12.5, k_reveal: 3.5,
      dowel_dia: 8.0, dowel_pitch: 45.0, plate_setback: 37.0, plate_pitch: 32.0,
      opening_angle: 110, sku: "BLUM-71B3550", unit_cost: 2.85
    },
    blum_155_zero_protrusion: {
      name: "Blum 155° Zero Protrusion Hinge (For Space Tower Inner Drawers)",
      cup_dia: 35.0, cup_depth: 12.5, k_reveal: 3.5,
      plate_setback: 37.0, opening_angle: 155, zero_protrusion: true,
      sku: "BLUM-71T7550", unit_cost: 4.50
    },
    blum_inset_cranked: {
      name: "Blum CLIP top 110° Inset Hinge (High Cranked Arm)",
      cup_dia: 35.0, cup_depth: 12.5, k_reveal: 3.5,
      plate_setback: 37.0, opening_angle: 110, sku: "BLUM-71B3750", unit_cost: 3.10
    },
    free_stop_flap_lift: {
      name: "Free Stop Damping Upward Flap Lift System",
      body_size: [28.0, 160.0, 120.0], arm_len: 280.0,
      sku: "LIFT-FREE-STOP-HK", unit_cost: 18.50
    }
  }

  RUNNER_CATALOG = {
    hettich_actro_500: {
      name: "Hettich Actro 5D Undermount Slide 500mm (70kg Full-Extension)",
      length: 500.0, load_kg: 70, min_carcase_d: 540.0, sku: "HET-ACTRO-500", unit_cost: 22.00
    },
    hettich_actro_450: {
      name: "Hettich Actro 5D Undermount Slide 450mm (70kg Full-Extension)",
      length: 450.0, load_kg: 70, min_carcase_d: 490.0, sku: "HET-ACTRO-450", unit_cost: 20.00
    },
    hettich_actro_350: {
      name: "Hettich Actro 5D Undermount Slide 350mm (40kg Full-Extension)",
      length: 350.0, load_kg: 40, min_carcase_d: 390.0, sku: "HET-ACTRO-350", unit_cost: 17.50
    },
    hettich_actro_250: {
      name: "Hettich Actro 5D Undermount Slide 250mm (40kg Full-Extension)",
      length: 250.0, load_kg: 40, min_carcase_d: 290.0, sku: "HET-ACTRO-250", unit_cost: 15.00
    },
    side_mount_ball_bearing_450: {
      name: "Heavy-Duty 45mm Ball Bearing Slide 450mm (45kg)",
      length: 450.0, load_kg: 45, width: 12.7, height: 45.0, sku: "SLIDE-BB-450", unit_cost: 8.50
    }
  }

  RAIL_CATALOG = {
    wardrobe_oval_rail: {
      name: "Wardrobe Chrome Oval Hanging Rail 30x15mm with End Flanges",
      profile_w: 15.0, profile_h: 30.0, material: "Chrome Steel", sku: "RAIL-OVAL-3015", unit_cost: 6.00
    },
    scilm_l_gola: {
      name: "SCILM Top L-Gola Aluminum Continuous Profile (Black Anodized)",
      profile_w: 27.2, profile_h: 56.5, sku: "SCILM-GOLA-L", unit_cost: 14.00
    },
    scilm_c_gola: {
      name: "SCILM Mid C-Gola Aluminum Continuous Profile (Black Anodized)",
      profile_w: 27.2, profile_h: 73.0, sku: "SCILM-GOLA-C", unit_cost: 16.50
    },
    camar_suspension_rail: {
      name: "Camar Heavy-Duty Cabinet Wall Suspension Track (Steel)",
      profile_w: 12.0, profile_h: 40.0, max_load_kg: 150, sku: "CAMAR-WALL-RAIL", unit_cost: 9.00
    }
  }

  # ----------------------------------------------------------------------------
  # 2. 3D VISUAL HARDWARE GENERATORS
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

  # --- Connectors 3D ---
  def self.build_minifix_unit(parent_ents, pt, mats)
    grp = parent_ents.add_group
    grp.name = "Häfele_Minifix_15_Assembly"
    steel_mat = mats[:steel]
    create_cylinder(grp.entities, pt, Geom::Vector3d.new(0, 0, -1), 7.5.mm, 12.5.mm, steel_mat)
    create_cylinder(grp.entities, pt + Geom::Vector3d.new(0, 0, -6.mm), Geom::Vector3d.new(1, 0, 0), 4.0.mm, 34.0.mm, steel_mat)
    grp
  end

  def self.build_cabineo_unit(parent_ents, pt, mats)
    grp = parent_ents.add_group
    grp.name = "Lamello_Cabineo_Connector"
    black_mat = mats[:gola]
    steel_mat = mats[:steel]
    # Oval pocket body
    create_box(grp.entities, [pt.x - 7.5.mm, pt.y - 16.9.mm, pt.z - 10.mm], [15.mm, 33.8.mm, 10.mm], black_mat, "Cabineo_Housing")
    create_cylinder(grp.entities, pt, Geom::Vector3d.new(0, 0, -1), 2.5.mm, 20.mm, steel_mat)
    grp
  end

  def self.build_rafix_unit(parent_ents, pt, mats)
    grp = parent_ents.add_group
    grp.name = "Häfele_Rafix_20_Connector"
    steel_mat = mats[:steel]
    create_cylinder(grp.entities, pt, Geom::Vector3d.new(0, 0, -1), 10.0.mm, 14.2.mm, steel_mat)
    create_cylinder(grp.entities, pt + Geom::Vector3d.new(0, 0, -7.mm), Geom::Vector3d.new(0, -1, 0), 3.5.mm, 12.0.mm, steel_mat)
    grp
  end

  def self.build_dowel_unit(parent_ents, pt, mats)
    grp = parent_ents.add_group
    grp.name = "Hardwood_Dowel_8x30"
    create_cylinder(grp.entities, pt, Geom::Vector3d.new(0, 0, 1), 4.0.mm, 30.0.mm, mats[:wood])
    grp
  end

  # --- Hinges 3D ---
  def self.build_blum_hinge_complete(parent_ents, pt, is_155_deg: false, mats: nil)
    grp = parent_ents.add_group
    grp.name = is_155_deg ? "Blum_155_Zero_Protrusion_Hinge" : "Blum_110_CLIP_Top_Hinge"
    steel_mat = mats[:steel]

    # Carcase Plate (37mm System 32)
    create_box(grp.entities, [pt.x, pt.y, pt.z - 16.mm], [3.5.mm, 32.mm, 32.mm], steel_mat, "Cruciform_Mounting_Plate")
    create_cylinder(grp.entities, pt + Geom::Vector3d.new(3.5.mm, 16.mm, 16.mm), Geom::Vector3d.new(-1, 0, 0), 2.5.mm, 11.5.mm, steel_mat)
    create_cylinder(grp.entities, pt + Geom::Vector3d.new(3.5.mm, 16.mm, -16.mm), Geom::Vector3d.new(-1, 0, 0), 2.5.mm, 11.5.mm, steel_mat)

    # Hinge Arm (with Zero Protrusion extension if 155°)
    arm_l = is_155_deg ? 65.mm : 45.mm
    create_box(grp.entities, [pt.x, pt.y - 20.mm, pt.z - 6.mm], [6.mm, arm_l, 12.mm], steel_mat, "Hinge_Articulated_Arm")

    # 35mm Door Cup
    cup_center = pt + Geom::Vector3d.new(18.mm, -25.mm, 0)
    create_cylinder(grp.entities, cup_center, Geom::Vector3d.new(0, -1, 0), 17.5.mm, 12.5.mm, steel_mat)
    create_box(grp.entities, [cup_center.x - 10.mm, cup_center.y - 2.mm, cup_center.z - 24.mm], [20.mm, 2.mm, 48.mm], steel_mat, "Cup_Flange")
    grp
  end

  # --- Runners 3D ---
  def self.build_hettich_runner_rail(parent_ents, pt, length_mm, mats)
    grp = parent_ents.add_group
    grp.name = "Hettich_Actro_5D_Runner_#{length_mm.to_i}mm"
    steel_mat = mats[:steel]

    # Cabinet Fixed Rail
    create_box(grp.entities, [pt.x, pt.y, pt.z], [11.mm, length_mm.mm, 24.mm], steel_mat, "Cabinet_Profile_Rail")
    # Synchronized Intermediate Slide
    create_box(grp.entities, [pt.x + 2.mm, pt.y + 10.mm, pt.z + 4.mm], [7.mm, (length_mm - 20).mm, 18.mm], steel_mat, "Intermediate_Slide")
    # Drawer Hook & Catch
    create_box(grp.entities, [pt.x + 1.mm, pt.y + (length_mm - 25).mm, pt.z + 18.mm], [10.mm, 20.mm, 8.mm], mats[:gola], "5D_Catch_Mechanism")
    grp
  end

  # --- Rails 3D ---
  def self.build_wardrobe_oval_rail_assembly(parent_ents, pt, length_mm, mats)
    grp = parent_ents.add_group
    grp.name = "Wardrobe_Oval_Hanging_Rail_#{length_mm.to_i}mm"
    steel_mat = mats[:steel]

    # LH Flange Socket
    create_box(grp.entities, [pt.x, pt.y - 10.mm, pt.z - 20.mm], [5.mm, 20.mm, 40.mm], steel_mat, "End_Flange_LH")
    # RH Flange Socket
    create_box(grp.entities, [pt.x + length_mm.mm - 5.mm, pt.y - 10.mm, pt.z - 20.mm], [5.mm, 20.mm, 40.mm], steel_mat, "End_Flange_RH")

    # Oval Rail Bar
    create_box(grp.entities, [pt.x + 5.mm, pt.y - 7.5.mm, pt.z - 15.mm], [(length_mm - 10).mm, 15.mm, 30.mm], steel_mat, "Chrome_Oval_Rail_30x15")
    grp
  end

  def self.build_wall_suspension_track(parent_ents, pt, length_mm, mats)
    grp = parent_ents.add_group
    grp.name = "Camar_Wall_Suspension_Track_#{length_mm.to_i}mm"
    steel_mat = mats[:steel]
    create_box(grp.entities, [pt.x, pt.y, pt.z], [length_mm.mm, 4.mm, 40.mm], steel_mat, "Steel_Wall_Track")
    # Suspension brackets at ends
    create_box(grp.entities, [pt.x + 10.mm, pt.y + 4.mm, pt.z + 5.mm], [45.mm, 25.mm, 30.mm], mats[:gola], "Carcase_Suspension_Bracket_LH")
    create_box(grp.entities, [pt.x + length_mm.mm - 55.mm, pt.y + 4.mm, pt.z + 5.mm], [45.mm, 25.mm, 30.mm], mats[:gola], "Carcase_Suspension_Bracket_RH")
    grp
  end
end
