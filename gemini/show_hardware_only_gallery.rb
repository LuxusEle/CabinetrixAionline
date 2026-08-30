# ==============================================================================
# CABINETRIX AI — PURE HARDWARE, CONNECTORS & ACCESSORIES 3D GALLERY
# File: gemini/show_hardware_only_gallery.rb
#
# Production Standard:
#   • PURE HARDWARE ONLY (ZERO BOXES / ZERO CARCASES).
#   • Standalone 3D Hardware Display on Exhibition Pedestals:
#     1. CONNECTORS: Minifix 15, Cabineo 8/12, Rafix 20, Dowels, Confirmat, Camar Plinth Legs.
#     2. HINGES & LIFTS: Blum Official SKP Hinge, Blum 110°, Blum 155° Zero Protrusion, Free Stop Lift.
#     3. RUNNERS & SLIDES: Hettich Actro 5D (500, 450, 350, 250mm), Heavy Side Ball Bearing Slides.
#     4. RAILS & PROFILES: Wardrobe Oval 30x15mm Rail, SCILM L-Gola, SCILM C-Gola, Camar Suspension Track.
#   • Real Solid 3D Extruded Labels with Technical Specs (SKU, Dimensions, Boring Specs).
# ==============================================================================
require 'sketchup.rb'

_dir = File.dirname(__FILE__)
load File.join(_dir, 'cabinetrix_machining_engine.rb')
load File.join(_dir, 'merge_blum_skp_asset.rb')

module CabinetrixHardwareOnlyGallery
  def self.get_or_create_material(model, name, rgb, alpha = 1.0)
    mat = model.materials[name] || model.materials.add(name)
    mat.color = Sketchup::Color.new(*rgb)
    mat.alpha = alpha
    mat
  end

  def self.build_materials(model)
    {
      carcase:    get_or_create_material(model, "Mat_Carcase_White", [242, 243, 245]),
      front_dark: get_or_create_material(model, "Mat_Front_Anthracite", [48, 51, 56]),
      wood:       get_or_create_material(model, "Mat_Birch_Core", [215, 185, 145]),
      gola:       get_or_create_material(model, "Mat_Gola_Black_Anodized", [30, 30, 32]),
      steel:      get_or_create_material(model, "Mat_Steel_Hardware", [195, 200, 205]),
      glass:      get_or_create_material(model, "Mat_Smoked_Glass", [70, 80, 90], 0.45),
      pedestal:   get_or_create_material(model, "Mat_Display_Pedestal", [22, 27, 34]),
      text_gold:  get_or_create_material(model, "Mat_3D_Text_Gold", [240, 180, 40]),
      text_cyan:  get_or_create_material(model, "Mat_3D_Text_Cyan", [88, 166, 255]),
      text_white: get_or_create_material(model, "Mat_3D_Text_White", [245, 245, 250])
    }
  end

  def self.add_3d_label(parent_ents, text_str, origin_pt, letter_height_mm, extrusion_mm, text_mat)
    grp = parent_ents.add_group
    grp.name = "Label_#{text_str.gsub(/[^a-zA-Z0-9]/, '_')}"
    
    text_sub = grp.entities.add_group
    text_sub.entities.add_3d_text(
      text_str,
      TextAlignLeft,
      "Arial",
      true,
      false,
      letter_height_mm.mm,
      0.0.mm,
      0.0.mm,
      true,
      extrusion_mm.mm
    )
    text_sub.material = text_mat
    
    tr = Geom::Transformation.translation(origin_pt)
    grp.transform!(tr)
    grp
  end

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

    # Erase any old exhibition floor groups to prevent overlap
    to_erase = entities.select { |e| e.is_a?(Sketchup::Group) && (e.name =~ /Cabinetrix_/i) }
    to_erase.each(&:erase!)

    mats = build_materials(model)
    pedestal_mat = mats[:pedestal]

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
    add_3d_label(gallery_root.entities, "ZONE 1: INDUSTRIAL CONNECTORS & FASTENERS", Geom::Point3d.new(-300.mm, y1 + 250.mm, 0.mm), 55.0, 8.0, mats[:text_gold])

    connectors = [
      {
        name: "Häfele Minifix 15",
        spec: "15mm Face Cam + 8x34mm Steel Connecting Bolt",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_minifix_unit(ents, pt, mats) }
      },
      {
        name: "Lamello Cabineo 8/12",
        spec: "Surface CNC Housing + 5mm Direct Screw",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_cabineo_unit(ents, pt, mats) }
      },
      {
        name: "Häfele Rafix 20",
        spec: "20mm Shelf Cam Lock + System 32 Euro Pin",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_rafix_unit(ents, pt, mats) }
      },
      {
        name: "Hardwood Dowel",
        spec: "8x30mm Ribbed Alignment Pin (Solid Hardwood)",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_dowel_unit(ents, pt + Geom::Vector3d.new(0,0,-15.mm), mats) }
      },
      {
        name: "Camar Plinth Leg",
        spec: "100mm Adjustable Leveling Leg + Top Flange",
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

      add_3d_label(gallery_root.entities, item[:name], Geom::Point3d.new((cx - 110.0).mm, y1 - 160.mm, 0.mm), 32.0, 4.0, mats[:text_cyan])
      add_3d_label(gallery_root.entities, item[:spec], Geom::Point3d.new((cx - 110.0).mm, y1 - 210.mm, 0.mm), 22.0, 3.0, mats[:text_white])
    end

    # ==========================================================================
    # ZONE 2: HINGE SYSTEMS & FLAP LIFTS (Y = -900mm)
    # ==========================================================================
    y2 = -900.0.mm
    add_3d_label(gallery_root.entities, "ZONE 2: BLUM CONCEALED HINGES & FLAP LIFT MECHANISMS", Geom::Point3d.new(-300.mm, y2 + 250.mm, 0.mm), 55.0, 8.0, mats[:text_gold])

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

      add_3d_label(gallery_root.entities, item[:name], Geom::Point3d.new((cx - 130.0).mm, y2 - 180.mm, 0.mm), 32.0, 4.0, mats[:text_cyan])
      add_3d_label(gallery_root.entities, item[:spec], Geom::Point3d.new((cx - 130.0).mm, y2 - 230.mm, 0.mm), 22.0, 3.0, mats[:text_white])
    end

    # ==========================================================================
    # ZONE 3: DRAWER SLIDES & UNDERMOUNT RUNNERS (Y = -1800mm)
    # ==========================================================================
    y3 = -1800.0.mm
    add_3d_label(gallery_root.entities, "ZONE 3: HETTICH ACTRO 5D UNDERMOUNT RUNNERS & SLIDES", Geom::Point3d.new(-300.mm, y3 + 250.mm, 0.mm), 55.0, 8.0, mats[:text_gold])

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
        CabinetrixMachiningEngine.create_box(gallery_root.entities, [cx.mm - 6.mm, y3 - item[:len].mm, 85.mm], [12.mm, item[:len].mm, 45.mm], mats[:steel], "Ball_Bearing_Slide")
      else
        CabinetrixMachiningEngine.build_hettich_runner_rail(gallery_root.entities, Geom::Point3d.new(cx.mm - 5.mm, y3 - item[:len].mm, 85.mm), item[:len], mats)
      end

      add_3d_label(gallery_root.entities, item[:name], Geom::Point3d.new((cx - 100.0).mm, y3 - item[:len].mm - 60.mm, 0.mm), 30.0, 4.0, mats[:text_cyan])
      add_3d_label(gallery_root.entities, item[:spec], Geom::Point3d.new((cx - 100.0).mm, y3 - item[:len].mm - 105.mm, 0.mm), 20.0, 3.0, mats[:text_white])
    end

    # ==========================================================================
    # ZONE 4: RAILS, GOLA PROFILES & HANDLES (Y = -2800mm)
    # ==========================================================================
    y4 = -2800.0.mm
    add_3d_label(gallery_root.entities, "ZONE 4: WARDROBE RAILS, SCILM GOLA PROFILES & HANDLES", Geom::Point3d.new(-300.mm, y4 + 250.mm, 0.mm), 55.0, 8.0, mats[:text_gold])

    rails = [
      {
        name: "Wardrobe Oval Rail 30x15mm",
        spec: "Chrome Steel Hanging Bar + Cast Metal End Flanges",
        builder: ->(ents, pt) { CabinetrixMachiningEngine.build_wardrobe_oval_rail_assembly(ents, pt, 600.0, mats) }
      },
      {
        name: "SCILM Top L-Gola Profile",
        spec: "Continuous Aluminum Channel (Black Anodized)",
        builder: ->(ents, pt) {
          grp = ents.add_group
          CabinetrixMachiningEngine.create_box(grp.entities, [pt.x, pt.y, pt.z], [600.mm, 27.2.mm, 56.5.mm], mats[:gola], "L_Gola_Profile")
        }
      },
      {
        name: "SCILM Mid C-Gola Profile",
        spec: "Continuous Intermediate Aluminum Channel",
        builder: ->(ents, pt) {
          grp = ents.add_group
          CabinetrixMachiningEngine.create_box(grp.entities, [pt.x, pt.y, pt.z], [600.mm, 27.2.mm, 73.0.mm], mats[:gola], "C_Gola_Profile")
        }
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
          CabinetrixMachiningEngine.create_box(ents, [pt.x + 150.mm, pt.y - 28.mm, pt.z + 10.mm], [224.mm, 6.mm, 8.mm], mats[:gola], "Bar_Handle_224")
          CabinetrixMachiningEngine.create_box(ents, [pt.x + 450.mm, pt.y - 28.mm, pt.z + 10.mm], [160.mm, 6.mm, 8.mm], mats[:gola], "Bar_Handle_160")
        }
      }
    ]

    rails.each_with_index do |item, idx|
      cx = idx * 750.0
      ped_pt = Geom::Point3d.new((cx + 300.0).mm, y4, 0.mm)
      build_display_pedestal(gallery_root.entities, ped_pt, 650.0, 200.0, 80.0, pedestal_mat)

      item[:builder].call(gallery_root.entities, Geom::Point3d.new(cx.mm, y4, 85.mm))

      add_3d_label(gallery_root.entities, item[:name], Geom::Point3d.new(cx.mm, y4 - 150.mm, 0.mm), 32.0, 4.0, mats[:text_cyan])
      add_3d_label(gallery_root.entities, item[:spec], Geom::Point3d.new(cx.mm, y4 - 200.mm, 0.mm), 22.0, 3.0, mats[:text_white])
    end

    model.commit_operation

    puts "\n" + "=" * 70
    puts " 🌟 PURE HARDWARE ONLY SHOWCASE RENDERED SUCCESSFULLY (ZERO BOXES)!"
    puts "=" * 70 + "\n"
  end
end

if defined?(Sketchup)
  CabinetrixHardwareOnlyGallery.render_gallery
end
