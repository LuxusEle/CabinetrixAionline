# ==============================================================================
# CABINETRIX AI — 3D EXHIBITION GRID OF ALL CATALOGUE BOXES (WITH 3D TEXT)
# File: gemini/show_catalogue_grid.rb
#
# Production Standard:
#   • Generous Spacing between Cabinets (1000mm gap between boxes, 2800mm between rows)
#   • Real Solid 3D Extruded Text Labels on the Floor in front of each box.
#   • Clean Category Row Headers in Bold 3D Text.
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
      stone:      get_or_create_material(model, "Mat_Calacatta_Quartz", [235, 238, 240]),
      badge_bg:   get_or_create_material(model, "Mat_Badge_Dark", [22, 27, 34]),
      text_gold:  get_or_create_material(model, "Mat_3D_Text_Gold", [240, 180, 40]),
      text_cyan:  get_or_create_material(model, "Mat_3D_Text_Cyan", [88, 166, 255]),
      text_white: get_or_create_material(model, "Mat_3D_Text_White", [245, 245, 250])
    }
  end

  def self.add_3d_label(parent_ents, text_str, origin_pt, letter_height_mm, extrusion_mm, text_mat, bg_mat = nil)
    grp = parent_ents.add_group
    grp.name = "Label_#{text_str.gsub(/[^a-zA-Z0-9]/, '_')}"
    
    # 3D Text Geometry
    text_sub = grp.entities.add_group
    text_sub.entities.add_3d_text(
      text_str,
      TextAlignLeft,
      "Arial",
      true,              # bold
      false,             # italic
      letter_height_mm.mm,
      0.0.mm,            # tolerance
      0.0.mm,            # z offset
      true,              # filled
      extrusion_mm.mm    # extrusion depth
    )
    text_sub.material = text_mat
    
    # Position on floor
    tr = Geom::Transformation.translation(origin_pt)
    grp.transform!(tr)
    grp
  end

  def self.render_grid
    model = Sketchup.active_model
    model.start_operation("Cabinetrix 3D Catalogue Floor Grid", true)
    entities = model.active_entities
    mats = build_materials(model)

    grid_root = entities.add_group
    grid_root.name = "Cabinetrix_Catalogue_Exhibition_Floor"

    puts "\n" + "=" * 65
    puts " 🏛️ RENDERING 3D CATALOGUE EXHIBITION FLOOR GRID (WITH 3D TEXT)"
    puts "=" * 65 + "\n"

    rows = [
      {
        category: "ROW 1: BASE GOLA UNITS",
        y_offset: 0.0,
        items: ["B_GOLA_2D", "B_GOLA_SINK", "B_GOLA_COOKTOP", "B_GOLA_SPICE"]
      },
      {
        category: "ROW 2: CORNER STORAGE UNITS",
        y_offset: -2600.0,
        items: ["B_CNR_LEMANS", "B_CNR_MAGIC"]
      },
      {
        category: "ROW 3: TALL APPLIANCE & PANTRY TOWERS",
        y_offset: -5200.0,
        items: ["T_SPACE_TOWER", "T_OVEN_TOWER"]
      },
      {
        category: "ROW 4: WALL & BULKHEAD UNITS",
        y_offset: -7800.0,
        items: ["W_LIFT_HF", "W_GLASS_SASH", "BLK_FLAP_HK"]
      },
      {
        category: "ROW 5: FREESTANDING ISLAND PREP",
        y_offset: -10400.0,
        items: ["ISL_GOLA_2D"]
      }
    ]

    total_rendered = 0

    rows.each do |row|
      x_cursor = 0.0
      
      # 3D Category Row Header
      header_pt = Geom::Point3d.new(-400.mm, (row[:y_offset] - 150.0).mm, 0.mm)
      add_3d_label(grid_root.entities, row[:category], header_pt, 75.0, 10.0, mats[:text_gold])

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

        # 1. Build 3D Cabinet Box
        CabinetrixBoxEngine.create_cabinet(grid_root.entities, box_type, box_params, loc, mats)

        # 2. Add Crisp 3D Floor Text Badges in Front of Box
        label_line1 = "[#{tmpl_id}]"
        label_line2 = "#{tmpl[:name]}"
        label_line3 = "#{w.to_i}W x #{h.to_i}H x #{d.to_i}D mm"

        b_x = x_cursor + 20.0
        b_y = row[:y_offset] - d - 180.0
        
        # Primary Code (Cyan 3D Text)
        add_3d_label(grid_root.entities, label_line1, Geom::Point3d.new(b_x.mm, b_y.mm, 0.mm), 50.0, 8.0, mats[:text_cyan])
        # Name (White 3D Text)
        add_3d_label(grid_root.entities, label_line2, Geom::Point3d.new(b_x.mm, (b_y - 90.0).mm, 0.mm), 38.0, 5.0, mats[:text_white])
        # Dimensions (Gold 3D Text)
        add_3d_label(grid_root.entities, label_line3, Geom::Point3d.new(b_x.mm, (b_y - 160.0).mm, 0.mm), 32.0, 5.0, mats[:text_gold])

        puts "   [RENDERED] #{tmpl_id} at X=#{x_cursor.to_i}mm, Y=#{row[:y_offset].to_i}mm"
        x_cursor += (w + 950.0) # 950mm wide clear spacing between boxes
      end
    end

    model.commit_operation

    puts "\n" + "=" * 65
    puts " 🌟 CATALOGUE EXHIBITION GRID COMPLETE WITH 3D TEXT (#{total_rendered} BOXES)!"
    puts "=" * 65 + "\n"
  end
end

if defined?(Sketchup)
  CabinetrixCatalogueGrid.render_grid
end
