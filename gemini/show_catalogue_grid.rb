# ==============================================================================
# CABINETRIX AI — 3D EXHIBITION GRID OF ALL CATALOGUE BOXES
# File: gemini/show_catalogue_grid.rb
#
# Role:
#   • Renders EVERY box template saved in catalogue.rb in a clean 3D showroom floor grid.
#   • Places 3D dimension badges, template IDs, and names in front of each box.
#   • Verifies all drawer front heights, Gola profiles, and stretchers visually on the floor.
# ==============================================================================
require 'sketchup.rb'

_dir = File.dirname(__FILE__)
load File.join(_dir, 'catalogue.rb')
load File.join(_dir, 'cabinetrix_collision_engine.rb')
load File.join(_dir, 'cabinetrix_box_engine.rb')

module CabinetrixCatalogueGrid
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
      front_wood: get_or_create_material(model, "Mat_Front_Oak", [185, 142, 95]),
      wood:       get_or_create_material(model, "Mat_Birch_Core", [215, 185, 145]),
      gola:       get_or_create_material(model, "Mat_Gola_Black_Anodized", [30, 30, 32]),
      steel:      get_or_create_material(model, "Mat_Steel_Hardware", [195, 200, 205]),
      glass:      get_or_create_material(model, "Mat_Smoked_Glass", [70, 80, 90], 0.45),
      led:        get_or_create_material(model, "Mat_LED_Warm_3000K", [255, 245, 210]),
      stone:      get_or_create_material(model, "Mat_Calacatta_Quartz", [235, 238, 240])
    }
  end

  def self.render_grid
    model = Sketchup.active_model
    model.start_operation("Cabinetrix 3D Catalogue Floor Grid", true)
    entities = model.active_entities
    mats = build_materials(model)

    grid_root = entities.add_group
    grid_root.name = "Cabinetrix_Catalogue_Exhibition_Floor"

    puts "\n" + "=" * 65
    puts " 🏛️ RENDERING 3D CATALOGUE EXHIBITION FLOOR GRID"
    puts "=" * 65 + "\n"

    # Define Rows of Modules
    rows = [
      {
        category: "BASE GOLA UNITS",
        y_offset: 0.0,
        items: ["B_GOLA_2D", "B_GOLA_SINK", "B_GOLA_COOKTOP", "B_GOLA_SPICE"]
      },
      {
        category: "CORNER UNITS",
        y_offset: -1800.0,
        items: ["B_CNR_LEMANS", "B_CNR_MAGIC"]
      },
      {
        category: "TALL TOWERS",
        y_offset: -3600.0,
        items: ["T_SPACE_TOWER", "T_OVEN_TOWER"]
      },
      {
        category: "WALL & BULKHEADS",
        y_offset: -5400.0,
        items: ["W_LIFT_HF", "W_GLASS_SASH", "BLK_FLAP_HK"]
      },
      {
        category: "ISLAND MODULES",
        y_offset: -7200.0,
        items: ["ISL_GOLA_2D"]
      }
    ]

    total_rendered = 0

    rows.each do |row|
      x_cursor = 0.0
      row[:items].each do |tmpl_id|
        tmpl = CabinetrixCatalogue.get(tmpl_id)
        next unless tmpl

        total_rendered += 1
        w = tmpl[:dimensions][:w][:default]
        h = tmpl[:dimensions][:h][:default]
        d = tmpl[:dimensions][:d][:default]

        loc = { x: x_cursor.mm, y: row[:y_offset].mm, z: 100.mm, rotation_deg: 0.0 }
        box_params = { width: w.mm, height: h.mm, depth: d.mm, name: "#{tmpl_id}_#{w.to_i}", mode: :closed }

        box_type = case tmpl[:category]
                   when :base_drawer then :base_gola_drawers
                   when :base_sink   then :base_gola_sink
                   when :base_cooking then :base_gola_cooktop
                   when :base_storage then :base_gola_spice
                   when :corner_base then :base_lemans_corner
                   when :tall_tower  then (tmpl_id.include?('OVEN') ? :tall_oven_tower : :tall_space_tower)
                   when :wall_lift   then :wall_lift_aventos
                   when :wall_display then :wall_glass_display
                   when :top_bulkhead then :top_bulkhead_flap
                   when :island_prep then :island_gola_drawers
                   else :base_gola_drawers
                   end

        CabinetrixBoxEngine.create_cabinet(grid_root.entities, box_type, box_params, loc, mats)

        # Add 3D Badge on Floor in Front of Cabinet
        badge_pt = Geom::Point3d.new((x_cursor + w/2.0).mm, (row[:y_offset] - d - 200.0).mm, 0.mm)
        txt = grid_root.entities.add_text("[#{tmpl_id}]\n#{tmpl[:name]}\n#{w.to_i}x#{h.to_i}x#{d.to_i}mm", badge_pt, Geom::Vector3d.new(0, -50.mm, 50.mm))
        
        puts "   [RENDERED] #{tmpl_id} -> #{tmpl[:name]} at X=#{x_cursor.to_i}mm, Y=#{row[:y_offset].to_i}mm"
        x_cursor += (w + 450.0) # 450mm gallery spacing between cabinets
      end
    end

    model.commit_operation

    puts "\n" + "=" * 65
    puts " 🌟 CATALOGUE EXHIBITION GRID COMPLETE (#{total_rendered} BOXES ON FLOOR)!"
    puts "=" * 65 + "\n"
  end
end

if defined?(Sketchup)
  CabinetrixCatalogueGrid.render_grid
end
