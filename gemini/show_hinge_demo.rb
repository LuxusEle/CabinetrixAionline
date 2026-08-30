# ==============================================================================
# CABINETRIX AI — DEDICATED BLUM HINGE SYSTEMS DEMO & KINEMATIC BENCH
# File: gemini/show_hinge_demo.rb
#
# Production Standard:
#   • DEMO 1: Official Blum CLIP top BLUMOTION (Imported SKP Component) on Gable+Door Joint.
#   • DEMO 2: Kinematic Door Rotation (Open at 95° vs Closed at 0°) with Embedded 35mm Cup.
#   • DEMO 3: Blum 155° Zero-Protrusion Hinge for Space Tower Inner Drawer Clearance.
#   • DEMO 4: Exploded Component Assembly View (Gable -> Plate -> Arm -> Cup -> Door).
#   • Real Solid 3D Extruded Labels and Callout Placards.
# ==============================================================================
require 'sketchup.rb'

_dir = File.dirname(__FILE__)
load File.join(_dir, 'cabinetrix_machining_engine.rb')
load File.join(_dir, 'show_catalogue_grid.rb')

module CabinetrixHingeDemo
  def self.render_demo
    model = Sketchup.active_model
    model.start_operation("Cabinetrix Blum Hinge Systems Demo", true)
    entities = model.active_entities
    mats = CabinetrixCatalogueGrid.build_materials(model)

    root = entities.add_group
    root.name = "Cabinetrix_Blum_Hinge_Master_Demo"

    puts "\n" + "=" * 70
    puts " 🚪 RENDERING DEDICATED BLUM HINGE SYSTEMS DEMONSTRATION BENCH"
    puts "=" * 70 + "\n"

    # ==========================================================================
    # BENCH 1: KINEMATIC DOOR ROTATION & EMBEDDED CUP (CLOSED VS 95° OPEN)
    # ==========================================================================
    b1_x = 0.0.mm
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "DEMO 1: KINEMATIC DOOR ROTATION (0° CLOSED VS 95° OPEN)", Geom::Point3d.new(b1_x, 150.mm, 0.mm), 50.0, 8.0, mats[:text_gold])

    # Closed Door Setup
    g1 = root.entities.add_group
    g1.name = "Closed_Door_Hinge_Joint"
    # Gable (18mm x 350mm x 400mm)
    CabinetrixBoxEngine.create_box(g1.entities, [b1_x, -350.mm, 0], [18.mm, 350.mm, 400.mm], mats[:carcase], "Carcase_Gable_LH")
    # Mounting Plate on Gable (37mm setback, System 32)
    CabinetrixBoxEngine.build_blum_carcase_plate(g1.entities, b1_x + 18.mm, -350.mm, 200.mm, true, mats)
    # Closed Door Slab (18mm x 250mm x 400mm)
    door_closed = g1.entities.add_group
    door_closed.name = "Door_Closed_0deg"
    CabinetrixBoxEngine.create_box(door_closed.entities, [b1_x + 1.5.mm, -350.mm - 18.mm, 0], [250.mm, 18.mm, 400.mm], mats[:front_dark], "Door_Slab")
    CabinetrixBoxEngine.build_blum_door_cup(door_closed.entities, b1_x + 21.5.mm, -350.mm, 200.mm, mats)

    CabinetrixCatalogueGrid.add_3d_label(g1.entities, "0° CLOSED (Flush Full Overlay)", Geom::Point3d.new(b1_x, -420.mm, 0.mm), 30.0, 4.0, mats[:text_cyan])

    # 95° Open Door Setup
    b1_open_x = b1_x + 400.mm
    g1_open = root.entities.add_group
    g1_open.name = "Open_Door_Hinge_Joint"
    CabinetrixBoxEngine.create_box(g1_open.entities, [b1_open_x, -350.mm, 0], [18.mm, 350.mm, 400.mm], mats[:carcase], "Carcase_Gable_LH")
    CabinetrixBoxEngine.build_blum_carcase_plate(g1_open.entities, b1_open_x + 18.mm, -350.mm, 200.mm, true, mats)

    door_open = g1_open.entities.add_group
    door_open.name = "Door_Open_95deg"
    CabinetrixBoxEngine.create_box(door_open.entities, [b1_open_x + 1.5.mm, -350.mm - 18.mm, 0], [250.mm, 18.mm, 400.mm], mats[:front_dark], "Door_Slab")
    CabinetrixBoxEngine.build_blum_door_cup(door_open.entities, b1_open_x + 21.5.mm, -350.mm, 200.mm, mats)

    # Rotate open door around hinge pivot
    pivot_pt = Geom::Point3d.new(b1_open_x + 1.5.mm, -350.mm, 0)
    door_open.transform!(Geom::Transformation.rotation(pivot_pt, Geom::Vector3d.new(0, 0, 1), -95.degrees))

    CabinetrixCatalogueGrid.add_3d_label(g1_open.entities, "95° OPEN (Full Access)", Geom::Point3d.new(b1_open_x, -420.mm, 0.mm), 30.0, 4.0, mats[:text_cyan])

    # ==========================================================================
    # BENCH 2: BLUM 155° ZERO-PROTRUSION HINGE (FOR SPACE TOWER INNER DRAWERS)
    # ==========================================================================
    b2_x = 950.0.mm
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "DEMO 2: BLUM 155° ZERO-PROTRUSION (INNER DRAWER CLEARANCE)", Geom::Point3d.new(b2_x, 150.mm, 0.mm), 50.0, 8.0, mats[:text_gold])

    g2 = root.entities.add_group
    g2.name = "Space_Tower_155_Hinge_Joint"
    CabinetrixBoxEngine.create_box(g2.entities, [b2_x, -560.mm, 0], [18.mm, 560.mm, 400.mm], mats[:carcase], "Carcase_Gable_LH")
    # 155° Hinge Plate on Gable
    CabinetrixMachiningEngine.build_blum_hinge_complete(g2.entities, Geom::Point3d.new(b2_x + 18.mm, -560.mm, 200.mm), is_155_deg: true, mats: mats)

    # Space Tower Inner Drawer pulling out smoothly past the hinge
    CabinetrixBoxEngine.build_hettich_undermount_drawer(g2.entities, Geom::Point3d.new(b2_x + 18.mm, -560.mm + 25.mm, 100.mm), 400.mm, 560.mm, 140.mm, 160.mm, 250.mm, mats, mats[:carcase], front_w: 372.mm, is_inner_drawer: true)

    # 155° Swung-out Door
    door_155 = g2.entities.add_group
    door_155.name = "Door_Open_155deg"
    CabinetrixBoxEngine.create_box(door_155.entities, [b2_x + 1.5.mm, -560.mm - 18.mm, 0], [450.mm, 18.mm, 400.mm], mats[:front_dark], "Door_Slab")
    pivot_155 = Geom::Point3d.new(b2_x + 1.5.mm, -560.mm, 0)
    door_155.transform!(Geom::Transformation.rotation(pivot_155, Geom::Vector3d.new(0, 0, 1), -155.degrees))

    CabinetrixCatalogueGrid.add_3d_label(g2.entities, "155° Zero Protrusion -> Inner Drawer Pulls Out Freely", Geom::Point3d.new(b2_x, -630.mm, 0.mm), 30.0, 4.0, mats[:text_cyan])

    # ==========================================================================
    # BENCH 3: EXPLODED COMPONENT ASSEMBLY (SYSTEM 32 ANATOMY)
    # ==========================================================================
    b3_x = 1800.0.mm
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "DEMO 3: EXPLODED SYSTEM 32 HINGE ANATOMY", Geom::Point3d.new(b3_x, 150.mm, 0.mm), 50.0, 8.0, mats[:text_gold])

    g3 = root.entities.add_group
    g3.name = "Exploded_Hinge_Assembly"

    # Part 1: Gable with System 32 Euro Holes
    CabinetrixBoxEngine.create_box(g3.entities, [b3_x, -350.mm, 0], [18.mm, 350.mm, 400.mm], mats[:carcase], "Gable_with_System32_Bores")
    CabinetrixMachiningEngine.create_cylinder(g3.entities, Geom::Point3d.new(b3_x + 18.mm, -350.mm + 37.mm, 216.mm), Geom::Vector3d.new(-1, 0, 0), 2.5.mm, 11.5.mm, mats[:steel])
    CabinetrixMachiningEngine.create_cylinder(g3.entities, Geom::Point3d.new(b3_x + 18.mm, -350.mm + 37.mm, 184.mm), Geom::Vector3d.new(-1, 0, 0), 2.5.mm, 11.5.mm, mats[:steel])
    CabinetrixCatalogueGrid.add_3d_label(g3.entities, "1. System 32 Euro Holes (37mm Setback)", Geom::Point3d.new(b3_x - 50.mm, -380.mm, 300.mm), 24.0, 3.0, mats[:text_white])

    # Part 2: Exploded Cruciform Plate (+60mm X)
    plate_x = b3_x + 60.mm
    CabinetrixBoxEngine.build_blum_carcase_plate(g3.entities, plate_x, -350.mm, 200.mm, true, mats)
    CabinetrixCatalogueGrid.add_3d_label(g3.entities, "2. 175H3100 Cruciform Plate", Geom::Point3d.new(plate_x - 30.mm, -380.mm, 250.mm), 24.0, 3.0, mats[:text_white])

    # Part 3: Exploded Articulated Arm & Damper (+140mm X)
    arm_x = b3_x + 140.mm
    CabinetrixMachiningEngine.create_box(g3.entities, [arm_x, -350.mm + 2.mm, 194.mm], [6.mm, 40.mm, 12.mm], mats[:steel], "Articulated_Hinge_Arm")
    CabinetrixCatalogueGrid.add_3d_label(g3.entities, "3. CLIP top BLUMOTION Arm", Geom::Point3d.new(arm_x - 30.mm, -380.mm, 200.mm), 24.0, 3.0, mats[:text_white])

    # Part 4: Exploded 35mm Cup Flange (+220mm X)
    cup_x = b3_x + 220.mm
    CabinetrixBoxEngine.build_blum_door_cup(g3.entities, cup_x, -350.mm, 200.mm, mats)
    CabinetrixCatalogueGrid.add_3d_label(g3.entities, "4. 35mm Press-in Cup (k=3.5mm)", Geom::Point3d.new(cup_x - 30.mm, -380.mm, 150.mm), 24.0, 3.0, mats[:text_white])

    # Part 5: Exploded Door Slab (+280mm X)
    door_x = b3_x + 280.mm
    CabinetrixBoxEngine.create_box(g3.entities, [door_x, -350.mm - 18.mm, 0], [200.mm, 18.mm, 400.mm], mats[:front_dark], "Door_Panel")
    CabinetrixCatalogueGrid.add_3d_label(g3.entities, "5. Door Front Slab", Geom::Point3d.new(door_x - 20.mm, -380.mm, 100.mm), 24.0, 3.0, mats[:text_white])

    model.commit_operation

    puts "\n" + "=" * 70
    puts " 🌟 BLUM HINGE SYSTEMS MASTER DEMO RENDERED SUCCESSFULLY!"
    puts "=" * 70 + "\n"
  end
end

if defined?(Sketchup)
  CabinetrixHingeDemo.render_demo
end
