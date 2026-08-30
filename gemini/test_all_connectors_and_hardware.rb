# ==============================================================================
# CABINETRIX AI — COMPLETE 3D HARDWARE, CONNECTORS, HINGES & RAILS EXHIBITION
# File: gemini/test_all_connectors_and_hardware.rb
#
# Production Standard:
#   • Renders ALL Connectors, Blum Hinges, Free Stop Flap Lifts, Hettich Runners & Rails.
#   • Real Solid 3D Extruded Text Labels in front of every hardware unit.
#   • Clean 4-Row Exhibition Floor Layout with wide spacing.
# ==============================================================================
require 'sketchup.rb'

_dir = File.dirname(__FILE__)
load File.join(_dir, 'cabinetrix_machining_engine.rb')
load File.join(_dir, 'show_catalogue_grid.rb') # for materials and 3D labels

module CabinetrixHardwareExhibition
  def self.render_hardware_floor
    model = Sketchup.active_model
    model.start_operation("Cabinetrix Hardware Exhibition", true)
    entities = model.active_entities
    mats = CabinetrixCatalogueGrid.build_materials(model)

    root = entities.add_group
    root.name = "Cabinetrix_Hardware_Exhibition_Floor"

    puts "\n" + "=" * 70
    puts " 🔩 RENDERING COMPLETE HARDWARE, CONNECTORS, HINGES & RAILS BENCH"
    puts "=" * 70 + "\n"

    # ==========================================================================
    # ROW 1: CONNECTORS & FASTENERS (Y = 0mm)
    # ==========================================================================
    y1 = 0.0.mm
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "ROW 1: INDUSTRIAL CONNECTORS & CNC JOINERY", Geom::Point3d.new(-300.mm, y1 + 100.mm, 0.mm), 60.0, 8.0, mats[:text_gold])

    # 1. Minifix 15
    CabinetrixMachiningEngine.build_minifix_unit(root.entities, Geom::Point3d.new(0.mm, y1, 100.mm), mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Häfele Minifix 15", Geom::Point3d.new(-50.mm, y1 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "15mm Cam + 8x34mm Bolt", Geom::Point3d.new(-50.mm, y1 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 2. Lamello Cabineo 8/12
    CabinetrixMachiningEngine.build_cabineo_unit(root.entities, Geom::Point3d.new(500.mm, y1, 100.mm), mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Lamello Cabineo 8/12", Geom::Point3d.new(450.mm, y1 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Flatbed Surface CNC Pocket", Geom::Point3d.new(450.mm, y1 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 3. Rafix 20
    CabinetrixMachiningEngine.build_rafix_unit(root.entities, Geom::Point3d.new(1000.mm, y1, 100.mm), mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Häfele Rafix 20", Geom::Point3d.new(950.mm, y1 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "20mm Shelf Cam Lock", Geom::Point3d.new(950.mm, y1 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 4. Hardwood Dowel 8x30
    CabinetrixMachiningEngine.build_dowel_unit(root.entities, Geom::Point3d.new(1500.mm, y1, 85.mm), mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Hardwood Dowel", Geom::Point3d.new(1450.mm, y1 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "8x30mm Alignment Pin", Geom::Point3d.new(1450.mm, y1 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # ==========================================================================
    # ROW 2: HINGES & FLAP LIFT MECHANISMS (Y = -800mm)
    # ==========================================================================
    y2 = -800.0.mm
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "ROW 2: BLUM CONCEALED HINGES & FREE STOP FLAP LIFTS", Geom::Point3d.new(-300.mm, y2 + 100.mm, 0.mm), 60.0, 8.0, mats[:text_gold])

    # 1. Blum 110° Full Overlay
    CabinetrixMachiningEngine.build_blum_hinge_complete(root.entities, Geom::Point3d.new(0.mm, y2, 100.mm), is_155_deg: false, mats: mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Blum 110° CLIP top", Geom::Point3d.new(-50.mm, y2 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Full Overlay + 37mm Plate", Geom::Point3d.new(-50.mm, y2 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 2. Blum 155° Zero Protrusion
    CabinetrixMachiningEngine.build_blum_hinge_complete(root.entities, Geom::Point3d.new(500.mm, y2, 100.mm), is_155_deg: true, mats: mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Blum 155° Zero Protrusion", Geom::Point3d.new(450.mm, y2 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "For Space Tower Inner Drawers", Geom::Point3d.new(450.mm, y2 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 3. Free Stop Flap Lift Mechanism (Image 5)
    CabinetrixMachiningEngine.create_box(root.entities, [1000.mm, y2 - 100.mm, 50.mm], [28.mm, 160.mm, 120.mm], mats[:steel], "Free_Stop_Lift_Unit")
    CabinetrixMachiningEngine.create_box(root.entities, [1030.mm, y2 - 80.mm, 140.mm], [8.mm, 200.mm, 15.mm], mats[:steel], "Telescopic_Arm")
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Free Stop Flap Lift", Geom::Point3d.new(950.mm, y2 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Upward Damping System (HK)", Geom::Point3d.new(950.mm, y2 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # ==========================================================================
    # ROW 3: DRAWER SLIDES & RUNNERS (Y = -1600mm)
    # ==========================================================================
    y3 = -1600.0.mm
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "ROW 3: HETTICH ACTRO 5D UNDERMOUNT RUNNERS", Geom::Point3d.new(-300.mm, y3 + 100.mm, 0.mm), 60.0, 8.0, mats[:text_gold])

    # 1. Hettich 500mm
    CabinetrixMachiningEngine.build_hettich_runner_rail(root.entities, Geom::Point3d.new(0.mm, y3 - 500.mm, 50.mm), 500.0, mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Hettich Actro 5D 500mm", Geom::Point3d.new(-50.mm, y3 - 580.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "70kg Full-Extension Undermount", Geom::Point3d.new(-50.mm, y3 - 630.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 2. Hettich 450mm
    CabinetrixMachiningEngine.build_hettich_runner_rail(root.entities, Geom::Point3d.new(500.mm, y3 - 450.mm, 50.mm), 450.0, mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Hettich Actro 5D 450mm", Geom::Point3d.new(450.mm, y3 - 580.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Standard Base & Tower Slide", Geom::Point3d.new(450.mm, y3 - 630.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 3. Hettich 350mm (Shallow)
    CabinetrixMachiningEngine.build_hettich_runner_rail(root.entities, Geom::Point3d.new(1000.mm, y3 - 350.mm, 50.mm), 350.0, mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Hettich Actro 5D 350mm", Geom::Point3d.new(950.mm, y3 - 580.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Shallow 370mm Carcase Slide", Geom::Point3d.new(950.mm, y3 - 630.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 4. Hettich 250mm (Compact)
    CabinetrixMachiningEngine.build_hettich_runner_rail(root.entities, Geom::Point3d.new(1500.mm, y3 - 250.mm, 50.mm), 250.0, mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Hettich Actro 5D 250mm", Geom::Point3d.new(1450.mm, y3 - 580.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Compact Pullout Slide", Geom::Point3d.new(1450.mm, y3 - 630.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # ==========================================================================
    # ROW 4: RAILS & PROFILES (Y = -2600mm)
    # ==========================================================================
    y4 = -2600.0.mm
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "ROW 4: WARDROBE RAILS, GOLA PROFILES & SUSPENSION TRACKS", Geom::Point3d.new(-300.mm, y4 + 100.mm, 0.mm), 60.0, 8.0, mats[:text_gold])

    # 1. Wardrobe Chrome Oval Rail 30x15mm
    CabinetrixMachiningEngine.build_wardrobe_oval_rail_assembly(root.entities, Geom::Point3d.new(0.mm, y4, 100.mm), 600.0, mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Wardrobe Oval Rail 30x15mm", Geom::Point3d.new(-50.mm, y4 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Chrome Hanging Bar + End Sockets", Geom::Point3d.new(-50.mm, y4 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 2. SCILM L-Gola Profile
    CabinetrixBoxEngine.build_gola_profile(root.entities, :l, 600.mm, Geom::Point3d.new(700.mm, y4 + 27.2.mm, 80.mm), mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "SCILM Top L-Gola Profile", Geom::Point3d.new(650.mm, y4 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Black Anodized Upper Channel", Geom::Point3d.new(650.mm, y4 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 3. SCILM C-Gola Profile
    CabinetrixBoxEngine.build_gola_profile(root.entities, :c, 600.mm, Geom::Point3d.new(1400.mm, y4 + 27.2.mm, 80.mm), mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "SCILM Mid C-Gola Profile", Geom::Point3d.new(1350.mm, y4 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Black Anodized Mid Channel", Geom::Point3d.new(1350.mm, y4 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    # 4. Camar Wall Suspension Track
    CabinetrixMachiningEngine.build_wall_suspension_track(root.entities, Geom::Point3d.new(2100.mm, y4, 80.mm), 600.0, mats)
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Camar Suspension Track", Geom::Point3d.new(2050.mm, y4 - 80.mm, 0.mm), 35.0, 5.0, mats[:text_cyan])
    CabinetrixCatalogueGrid.add_3d_label(root.entities, "Steel Wall Track + Brackets", Geom::Point3d.new(2050.mm, y4 - 130.mm, 0.mm), 25.0, 3.0, mats[:text_white])

    model.commit_operation

    puts "\n" + "=" * 70
    puts " 🌟 COMPLETE HARDWARE EXHIBITION RENDERED SUCCESSFULLY!"
    puts "=" * 70 + "\n"
  end
end

if defined?(Sketchup)
  CabinetrixHardwareExhibition.render_hardware_floor
end
