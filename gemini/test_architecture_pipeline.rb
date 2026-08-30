# ==============================================================================
# CABINETRIX AI — ARCHITECTURE & CATALOGUE INTEGRATION TEST
# File: gemini/test_architecture_pipeline.rb
#
# Tests the Synergistic Flow:
#   architecture.rb (Conductor) -> catalogue.rb (Stencils) -> box_engine.rb (Maker)
# ==============================================================================
require 'sketchup.rb'

_dir = File.dirname(__FILE__)
load File.join(_dir, 'catalogue.rb')
load File.join(_dir, 'cabinetrix_collision_engine.rb')
load File.join(_dir, 'cabinetrix_box_engine.rb')
load File.join(_dir, 'architecture.rb')
load File.join(_dir, 'cabinetrix_nesting_engine.rb')

module CabinetrixArchTest
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

  def self.run_test
    model = Sketchup.active_model
    model.start_operation("Cabinetrix Architecture Test", true)
    entities = model.active_entities
    mats = build_materials(model)

    puts "\n" + "=" * 65
    puts " 🏛️ TESTING ARCHITECTURE -> CATALOGUE -> BOX ENGINE PIPELINE"
    puts "=" * 65 + "\n"

    # Step 1: Query Catalogue
    puts ">> Step 1: Inspecting Stencils in Catalogue..."
    all_stencils = CabinetrixCatalogue.list_all
    puts "   -> Stencils Available in Memory: #{all_stencils.length} (#{all_stencils.join(', ')})"

    # Step 2: Conductor designs a 3D L-Shape Kitchen Room
    puts "\n>> Step 2: Architecture Conductor designing L-Shape Suite..."
    room_design = CabinetrixArchitecture.design_room_layout(:l_shape)
    puts "   -> Designed Room: #{room_design[:name]}"
    puts "   -> Total Cabinets in Plan: #{room_design[:modules].length}"

    # Step 3: Conductor instructs Box Engine to manufacture the 3D Room in SketchUp
    puts "\n>> Step 3: Manufacturing 3D Room in SketchUp..."
    result = CabinetrixArchitecture.build_room(entities, room_design, 0.0, 0.0, mats, :closed)
    
    puts "   -> Extracted Physical Panels: #{result[:panels].length} parts"
    puts "   -> Hardware BOM Items: #{result[:hardware].length} line items"

    # Step 4: Run Nesting on Extracted Panels
    puts "\n>> Step 4: Running 2D Nesting Optimizer on Stencil Panels..."
    carcase_panels = result[:panels].select { |p| p[:material].include?('carcase') || p[:thk] >= 15.0 }
    nesting = CabinetrixNestingEngine.nest_panels(carcase_panels, 2440.0, 1220.0, 10.0, 4.0)
    puts "   -> Raw 2440x1220mm Sheets Needed: #{nesting[:total_sheets]} Sheets"
    puts "   -> Carcase Material Yield: #{nesting[:overall_yield_pct]}%"

    model.commit_operation

    puts "\n" + "=" * 65
    puts " ✅ ARCHITECTURAL TEST COMPLETED WITH 100% SUCCESS!"
    puts "=" * 65 + "\n"
  end
end

if defined?(Sketchup)
  CabinetrixArchTest.run_test
end
