# ==============================================================================
# CABINETRIX AI — OFFICIAL BLUM & HARDWARE 3D SHOWCASE GALLERY
# File: gemini/import_and_organize_hardware.rb
#
# Production Standard:
#   • Scans ONLY the dedicated hardware directory: gemini/skp/*.skp.
#   • Renders official Blum 3D Warehouse components (BLUM+AVENTOS.skp, Hinge+simplified.skp).
#   • Places each model onto a custom dark exhibition display pedestal.
#   • Real Solid 3D Extruded Labels with component names and millimeter bounding dimensions.
#   • PURE STANDALONE HARDWARE — ZERO CARCASES / ZERO BOXES.
# ==============================================================================
require 'sketchup.rb'

_dir = File.dirname(__FILE__)
load File.join(_dir, 'cabinetrix_machining_engine.rb')
load File.join(_dir, 'show_hardware_only_gallery.rb')

module CabinetrixHardwareImporter
  HARDWARE_SKP_DIR = File.join(File.dirname(__FILE__), "skp")

  def self.scan_and_render_all_hardware
    model = Sketchup.active_model
    model.start_operation("Cabinetrix Official Blum Hardware Gallery", true)
    entities = model.active_entities

    # Clean old exhibition groups to guarantee a pristine scene
    to_erase = entities.select { |e| e.is_a?(Sketchup::Group) && (e.name =~ /Cabinetrix_/i) }
    to_erase.each(&:erase!)

    mats = CabinetrixHardwareOnlyGallery.build_materials(model)
    pedestal_mat = mats[:pedestal]

    root = entities.add_group
    root.name = "Cabinetrix_Imported_Hardware_Showcase"

    puts "\n" + "=" * 70
    puts " 🔩 RENDERING OFFICIAL BLUM 3D HARDWARE MODELS & CONNECTORS"
    puts "    (STANDALONE 3D HARDWARE ON DISPLAY PEDESTALS — ZERO CARCASES)"
    puts "=" * 70 + "\n"

    # 1. Gather all official hardware SKP files strictly inside gemini/skp/
    skp_files = Dir.glob(File.join(HARDWARE_SKP_DIR, "*.skp"))

    # 2. Zone 1 Header
    CabinetrixHardwareOnlyGallery.add_3d_label(
      root.entities,
      "ZONE 1: OFFICIAL BLUM 3D WAREHOUSE HARDWARE COMPONENTS",
      Geom::Point3d.new(-300.mm, 250.mm, 0.mm),
      55.0, 8.0, mats[:text_gold]
    )

    x_cursor = 0.0
    rendered_count = 0

    skp_files.each do |skp_path|
      filename = File.basename(skp_path)
      base_name = File.basename(skp_path, ".*")
      
      puts "   [LOADING] #{filename}..."
      begin
        cdef = model.definitions.load(skp_path)
        next unless cdef

        rendered_count += 1
        b = cdef.bounds
        w = [b.width.to_mm, 150.0].max
        d = [b.depth.to_mm, 150.0].max
        h = [b.height.to_mm, 100.0].max

        ped_w = [w + 80.0, 300.0].max
        ped_d = [d + 80.0, 300.0].max
        ped_pt = Geom::Point3d.new(x_cursor.mm, 0.mm, 0.mm)

        # Build pedestal
        CabinetrixHardwareOnlyGallery.build_display_pedestal(root.entities, ped_pt, ped_w, ped_d, 80.0, pedestal_mat)

        # Place component instance centered on top of pedestal
        comp_pt = Geom::Point3d.new(x_cursor.mm - b.center.x, -b.center.y, 85.mm - b.min.z)
        inst = root.entities.add_instance(cdef, Geom::Transformation.translation(comp_pt))
        inst.name = "Instance_#{base_name}"

        # 3D Badges
        label_y = - (ped_d / 2.0) - 50.0
        CabinetrixHardwareOnlyGallery.add_3d_label(
          root.entities,
          base_name.gsub(/[^a-zA-Z0-9_\-]/, ' '),
          Geom::Point3d.new((x_cursor - ped_w/2.0 + 20.0).mm, label_y.mm, 0.mm),
          32.0, 4.0, mats[:text_cyan]
        )
        CabinetrixHardwareOnlyGallery.add_3d_label(
          root.entities,
          "Source: #{filename} (#{w.to_i}x#{d.to_i}x#{h.to_i}mm)",
          Geom::Point3d.new((x_cursor - ped_w/2.0 + 20.0).mm, (label_y - 50.0).mm, 0.mm),
          20.0, 3.0, mats[:text_white]
        )

        puts "   [RENDERED] #{filename} at X=#{x_cursor.to_i}mm on #{ped_w.to_i}x#{ped_d.to_i}mm pedestal"
        x_cursor += (ped_w + 300.0)
      rescue => e
        puts "   [ERROR] Failed to load #{filename}: #{e.message}"
      end
    end

    # 3. Zone 2: Standard CNC Connectors & Leveling System
    y_conn = -800.0.mm
    CabinetrixHardwareOnlyGallery.add_3d_label(
      root.entities,
      "ZONE 2: INDUSTRIAL CONNECTORS & CNC JOINERY",
      Geom::Point3d.new(-300.mm, y_conn + 250.mm, 0.mm),
      50.0, 7.0, mats[:text_gold]
    )

    connectors = [
      { name: "Häfele Minifix 15", spec: "15mm Face Cam + 8x34mm Steel Bolt", builder: ->(ents, pt) { CabinetrixMachiningEngine.build_minifix_unit(ents, pt, mats) } },
      { name: "Lamello Cabineo 8/12", spec: "Surface CNC Housing + 5mm Direct Screw", builder: ->(ents, pt) { CabinetrixMachiningEngine.build_cabineo_unit(ents, pt, mats) } },
      { name: "Häfele Rafix 20", spec: "20mm Shelf Cam Lock + System 32 Euro Pin", builder: ->(ents, pt) { CabinetrixMachiningEngine.build_rafix_unit(ents, pt, mats) } },
      { name: "Hardwood Dowel", spec: "8x30mm Ribbed Alignment Pin", builder: ->(ents, pt) { CabinetrixMachiningEngine.build_dowel_unit(ents, pt + Geom::Vector3d.new(0,0,-15.mm), mats) } },
      { name: "Camar Plinth Leg", spec: "100mm Leveling Leg + Top Flange", builder: ->(ents, pt) {
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
      ped_pt = Geom::Point3d.new(cx.mm, y_conn, 0.mm)
      CabinetrixHardwareOnlyGallery.build_display_pedestal(root.entities, ped_pt, 250.0, 250.0, 80.0, pedestal_mat)
      item[:builder].call(root.entities, Geom::Point3d.new(cx.mm, y_conn, 85.mm))

      CabinetrixHardwareOnlyGallery.add_3d_label(root.entities, item[:name], Geom::Point3d.new((cx - 110.0).mm, y_conn - 160.mm, 0.mm), 30.0, 4.0, mats[:text_cyan])
      CabinetrixHardwareOnlyGallery.add_3d_label(root.entities, item[:spec], Geom::Point3d.new((cx - 110.0).mm, y_conn - 210.mm, 0.mm), 20.0, 3.0, mats[:text_white])
    end

    model.commit_operation

    puts "\n" + "=" * 70
    puts " 🌟 OFFICIAL BLUM HARDWARE GALLERY RENDERED (#{rendered_count} SKP Models + 5 Connectors)!"
    puts "=" * 70 + "\n"
  end
end

if defined?(Sketchup)
  CabinetrixHardwareImporter.scan_and_render_all_hardware
end
