# ==============================================================================
# CABINETRIX AI — PURE HARDWARE, CONNECTORS & ACCESSORIES 3D GALLERY
# File: gemini/show_hardware_only_gallery.rb
#
# Production Standard:
#   • PURE HARDWARE MODELS ONLY (ZERO CARCASES / ZERO BOXES).
#   • High-Precision Standalone 3D Models on Exhibition Display Pedestals:
#     1. CONNECTORS: Minifix 15, Cabineo 8/12, Rafix 20, Dowels, Confirmat, Camar Plinth Legs.
#     2. HINGES & LIFTS: Blum Official SKP Hinge, Blum 110°, Blum 155° Zero Protrusion, Inset, Free Stop Lift.
#     3. RUNNERS & SLIDES: Hettich Actro 5D (500, 450, 350, 250mm), Heavy Side Ball Bearing Slides.
#     4. RAILS & PROFILES: Wardrobe Oval 30x15mm Rail, SCILM L-Gola, SCILM C-Gola, Camar Suspension Track.
#   • Solid 3D Extruded Labels with Technical Specs (SKU, Diameters, Depths, Pitch).
# ==============================================================================
require 'sketchup.rb'

_dir = File.dirname(__FILE__)
load File.join(_dir, 'cabinetrix_machining_engine.rb')
load File.join(_dir, 'merge_blum_skp_asset.rb')
load File.join(_dir, 'show_catalogue_grid.rb')

module CabinetrixHardwareOnlyGallery
  def self.build_display_pedestal(entities, origin_pt, width_mm, depth_mm, height_mm, pedestal_mat)
    CabinetrixMachiningEngine.create_box(
      entities,
      [origin_pt.x - width_mm.mm / 2.0, origin_pt.y - depth_mm.mm / 2.0, origin_pt.z],
      [width_mm.mm, depth_mm.mm, height_mm.mm],
      pedestal_mat,
      "Display_Pedestal"
    )
  end

  def self.render_gallery
    model = Sketchup.active_model
    model.start_operation("Cabinetrix Pure Hardware Gallery", true)
    entities = model.active_entities
    mats = CabinetrixCatalogueGrid.build_materials(model)

    pedestal_mat = mats[:badge_bg] # Sleek dark pedestal
    gallery_root = entities.add_group
    gallery_root.name = "Cabinetrix_Hardware_Only_Showcase"

    puts "\n" + "=" * 70
    puts " 🔩 RENDERING PURE HARDWARE, CONNECTORS & ACCESSORIES GALLERY"
    puts "    (STANDALONE 3D HARDWARE MODELS — ZERO BOXES / NO CARCASES)"
    puts "=" * 70 + "\n"

    # ==========================================================================
    # ZONE 1: CONNECTORS & FASTENERS (Y = 0mm)
    # ==========================================================================
    y1 = 0.0.mm
    CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, "GALLERY 1: INDUSTRIAL CONNECTORS & FASTENERS", Geom::Point3d.new(-300.mm, y1 + 250.mm, 0.mm), 55.0, 8.0, mats[:text_gold])

    connectors = [
      {
        name: "Häfele Minifix 15",
        spec: "15mm Face Cam + 8x34mm Steel Connecting Bolt",
        code: "HAF-MINIFIX-15",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_minifix_unit(ents, pt, mats) }
      },
      {
        name: "Lamello Cabineo 8/12",
        spec: "Surface CNC Housing + 5mm Direct Screw",
        code: "LAM-CABINEO-12",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_cabineo_unit(ents, pt, mats) }
      },
      {
        name: "Häfele Rafix 20",
        spec: "20mm Shelf Cam Lock + System 32 Euro Pin",
        code: "HAF-RAFIX-20",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_rafix_unit(ents, pt, mats) }
      },
      {
        name: "Hardwood Dowel",
        spec: "8x30mm Ribbed Alignment Pin (Solid Hardwood)",
        code: "DOWEL-8X30",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_dowel_unit(ents, pt + Geom::Vector3d.new(0,0,-15.mm), mats) }
      },
      {
        name: "Camar Plinth Leg",
        spec: "100mm Adjustable Leveling Leg + Top Flange",
        code: "CAMAR-LEG-100",
        builder: ->(ents, pt) {
          grp = ents.add_group
          CabinetrixMachiningEngine.create_cylinder(grp.entities, pt, Geom::Vector3d.new(0,0,-1), 38.mm, 5.mm, mats[:gola])
          CabinetrixMachiningEngine.create_cylinder(grp.entities, pt - Geom::Vector3d.new(0,0,5.mm), Geom::Vector3d.new(0,0,-1), 24.mm, 85.mm, mats[:gola])
          CabinetrixMachiningEngine.create_cylinder(grp.entities, pt - Geom::Vector3d.new(0,0,90.mm), Geom::Vector3d.new(0,0,-1), 28.mm, 10.mm, mats[:gola])
          grp
        }
      }
    ]

    connectors.each_with_index do |item, idx|
      cx = idx * 600.0
      ped_pt = Geom::Point3d.new(cx.mm, y1, 0.mm)
      build_display_pedestal(gallery_root.entities, ped_pt, 250.0, 250.0, 80.0, pedestal_mat)
      
      item[:builder].call(gallery_root.entities, Geom::Point3d.new(cx.mm, y1, 85.mm))

      # 3D Badges
      CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, item[:name], Geom::Point3d.new((cx - 110.0).mm, y1 - 160.mm, 0.mm), 32.0, 4.0, mats[:text_cyan])
      CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, item[:spec], Geom::Point3d.new((cx - 110.0).mm, y1 - 210.mm, 0.mm), 22.0, 3.0, mats[:text_white])
    end

    # ==========================================================================
    # ZONE 2: HINGE SYSTEMS & FLAP LIFTS (Y = -900mm)
    # ==========================================================================
    y2 = -900.0.mm
    CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, "GALLERY 2: BLUM CONCEALED HINGES & FLAP LIFT MECHANISMS", Geom::Point3d.new(-300.mm, y2 + 250.mm, 0.mm), 55.0, 8.0, mats[:text_gold])

    hinges = [
      {
        name: "Blum Official SKP Hinge",
        spec: "Official 3D Warehouse Blum Component (Hinge+simplified.skp)",
        builder: ->(ents, pt) {
          model = Sketchup.active_model
          cdef = CabinetrixBlumAsset.load_blum_skp_definition(model)
          if cdef
            inst = ents.add_instance(cdef, Geom::Transformation.translation(pt))
            inst.transform!(Geom::Transformation.rotation(pt, Geom::Vector3d.new(1,0,0), 90.degrees))
          else
            CabinetrixMachiningEngine.build_blum_hinge_complete(ents, pt, is_155_deg: false, mats: mats)
          end
        }
      },
      {
        name: "Blum 110° CLIP top",
        spec: "Full Overlay + 35mm Press-in Cup + 37mm System 32 Plate",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_blum_hinge_complete(ents, pt, is_155_deg: false, mats: mats) }
      },
      {
        name: "Blum 155° Zero Protrusion",
        spec: "Wide-Angle Hinge for Space Tower Internal Drawer Clearance",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_blum_hinge_complete(ents, pt, is_155_deg: true, mats: mats) }
      },
      {
        name: "Free Stop Flap Lift Unit",
        spec: "Upward Damping Telescopic Lift Mechanism (HK System)",
        builder: ->(ents, pt) {
          CabinetrixMachiningEngine.create_box(ents, [pt.x - 14.mm, pt.y - 80.mm, pt.z], [28.mm, 160.mm, 120.mm], mats[:steel], "Lift_Body")
          CabinetrixMachiningEngine.create_box(ents, [pt.x + 16.mm, pt.y - 60.mm, pt.z + 80.mm], [8.mm, 180.mm, 15.mm], mats[:steel], "Telescopic_Arm")
        }
      }
    ]

    hinges.each_with_index do |item, idx|
      cx = idx * 750.0
      ped_pt = Geom::Point3d.new(cx.mm, y2, 0.mm)
      build_display_pedestal(gallery_root.entities, ped_pt, 300.0, 300.0, 80.0, pedestal_mat)

      item[:builder].call(gallery_root.entities, Geom::Point3d.new(cx.mm, y2, 85.mm))

      CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, item[:name], Geom::Point3d.new((cx - 130.0).mm, y2 - 180.mm, 0.mm), 32.0, 4.0, mats[:text_cyan])
      CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, item[:spec], Geom::Point3d.new((cx - 130.0).mm, y2 - 230.mm, 0.mm), 22.0, 3.0, mats[:text_white])
    end

    # ==========================================================================
    # ZONE 3: DRAWER SLIDES & UNDERMOUNT RUNNERS (Y = -1800mm)
    # ==========================================================================
    y3 = -1800.0.mm
    CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, "GALLERY 3: HETTICH ACTRO 5D UNDERMOUNT RUNNERS & SLIDES", Geom::Point3d.new(-300.mm, y3 + 250.mm, 0.mm), 55.0, 8.0, mats[:text_gold])

    runners = [
      { name: "Hettich Actro 5D 500mm", len: 500.0, spec: "70kg Full-Extension Synchronized Runner" },
      { name: "Hettich Actro 5D 450mm", len: 450.0, spec: "Standard 560mm Base & Tower Slide" },
      { name: "Hettich Actro 5D 350mm", len: 350.0, spec: "Shallow 370mm Carcase Slide" },
      { name: "Hettich Actro 5D 250mm", len: 250.0, spec: "Compact Spice & Internal Pullout Slide" },
      { name: "Heavy Ball Bearing 450mm", len: 450.0, spec: "45kg 3-Section Telescopic Side Slide", is_bb: true }
    ]

    runners.each_with_index do |item, idx|
      cx = idx * 600.0
      ped_pt = Geom::Point3d.new(cx.mm, y3 - (item[:len]/2.0).mm, 0.mm)
      build_display_pedestal(gallery_root.entities, ped_pt, 200.0, item[:len] + 80.0, 80.0, pedestal_mat)

      if item[:is_bb]
        # Side ball bearing slide
        CabinetrixMachiningEngine.create_box(gallery_root.entities, [cx.mm - 6.mm, y3 - item[:len].mm, 85.mm], [12.mm, item[:len].mm, 45.mm], mats[:steel], "Ball_Bearing_Slide")
      else
        # Undermount Actro 5D
        CabinetrixMachiningEngine.build_hettich_runner_rail(gallery_root.entities, Geom::Point3d.new(cx.mm - 5.mm, y3 - item[:len].mm, 85.mm), item[:len], mats)
      end

      CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, item[:name], Geom::Point3d.new((cx - 100.0).mm, y3 - item[:len].mm - 60.mm, 0.mm), 30.0, 4.0, mats[:text_cyan])
      CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, item[:spec], Geom::Point3d.new((cx - 100.0).mm, y3 - item[:len].mm - 105.mm, 0.mm), 20.0, 3.0, mats[:text_white])
    end

    # ==========================================================================
    # ZONE 4: RAILS, GOLA PROFILES & HANDLES (Y = -2800mm)
    # ==========================================================================
    y4 = -2800.0.mm
    CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, "GALLERY 4: WARDROBE RAILS, SCILM GOLA PROFILES & HANDLES", Geom::Point3d.new(-300.mm, y4 + 250.mm, 0.mm), 55.0, 8.0, mats[:text_gold])

    rails = [
      {
        name: "Wardrobe Oval Rail 30x15mm",
        spec: "Chrome Steel Hanging Bar + Cast Metal End Flanges",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_wardrobe_oval_rail_assembly(ents, pt, 600.0, mats) }
      },
      {
        name: "SCILM Top L-Gola Profile",
        spec: "Continuous Aluminum Channel (Black Anodized)",
        builder: ->(ents, pt) { CabinetrixBoxEngine.build_gola_profile(ents, :l, 600.mm, pt + Geom::Vector3d.new(0, 27.2.mm, 0), mats) }
      },
      {
        name: "SCILM Mid C-Gola Profile",
        spec: "Continuous Intermediate Aluminum Channel",
        builder: ->(ents, pt) { CabinetrixBoxEngine.build_gola_profile(ents, :c, 600.mm, pt + Geom::Vector3d.new(0, 27.2.mm, 0), mats) }
      },
      {
        name: "Camar Wall Track & Brackets",
        spec: "Steel Suspension Rail + Heavy Duty Hanging Brackets",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_wall_suspension_track(ents, pt, 600.0, mats) }
      },
      {
        name: "Contemporary Bar Handles",
        spec: "224mm & 160mm Solid Anodized Metal Pulls",
        builder: ->(ents, pt) {
          CabinetrixBoxEngine.build_contemporary_bar_handle(ents, pt + Geom::Vector3d.new(150.mm, 0, 0), 224.0, :horizontal, mats)
          CabinetrixBoxEngine.build_contemporary_bar_handle(ents, pt + Geom::Vector3d.new(450.mm, 0, 0), 160.0, :horizontal, mats)
        }
      }
    ]

    rails.each_with_index do |item, idx|
      cx = idx * 750.0
      ped_pt = Geom::Point3d.new((cx + 300.0).mm, y4, 0.mm)
      build_display_pedestal(gallery_root.entities, ped_pt, 650.0, 200.0, 80.0, pedestal_mat)

      item[:builder].call(gallery_root.entities, Geom::Point3d.new(cx.mm, y4, 85.mm))

      CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, item[:name], Geom::Point3d.new(cx.mm, y4 - 150.mm, 0.mm), 32.0, 4.0, mats[:text_cyan])
      CabinetrixCatalogueGrid.add_3d_label(gallery_root.entities, item[:spec], Geom::Point3d.new(cx.mm, y4 - 200.mm, 0.mm), 22.0, 3.0, mats[:text_white])
    end

    model.commit_operation

    puts "\n" + "=" * 70
    puts " 🌟 PURE HARDWARE ONLY SHOWCASE RENDERED SUCCESSFULLY!"
    puts "=" * 70 + "\n"
  end
end

if defined?(Sketchup)
  CabinetrixHardwareOnlyGallery.render_gallery
end
