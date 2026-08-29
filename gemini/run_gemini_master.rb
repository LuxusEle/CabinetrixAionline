# ==============================================================================
# CABINETRIX AI — GEMINI DEVELOPMENT MASTER RUNNER
# (c) 2026 Cabinetrix AI. All development isolated inside gemini/
# ==============================================================================
# USAGE IN SKETCHUP RUBY CONSOLE:
#   load 'c:/Users/asank/Documents/CabinetrixAionline/gemini/run_gemini_master.rb'
#   RunGeminiMaster.build_kitchen          # Builds full luxury Gola kitchen + report
#   RunGeminiMaster.build_gola_drawer_bank # Builds 2x 600mm Gola test bank
#   RunGeminiMaster.build_ljoint_demo      # Builds 18mm fastener comparison demo
#   RunGeminiMaster.build_all              # Builds entire showroom comparison grid
# ==============================================================================
require 'sketchup.rb'

module RunGeminiMaster
  GEMINI_DIR = File.dirname(__FILE__)

  def self.load_module(filename)
    path = File.join(GEMINI_DIR, filename)
    if File.exist?(path)
      load path
      true
    else
      puts "❌ Could not find: #{path}"
      false
    end
  end

  def self.build_kitchen(mode = :hybrid)
    $CABINETRIX_NO_AUTORUN = true
    load_module('build_luxury_gola_kitchen_master.rb')
    if defined?(CabinetrixLuxuryKitchen)
      CabinetrixLuxuryKitchen.build(mode: mode)
    end
  end

  def self.build_gola_drawer_bank(mode = :hybrid)
    $CABINETRIX_NO_AUTORUN = true
    load_module('gola_drawer_bank_master.rb')
    if defined?(CabinetrixMasterGola)
      CabinetrixMasterGola.build_all_and_show_report(mode: mode)
    end
  end

  def self.build_ljoint_demo
    $CABINETRIX_DEMO_NO_AUTORUN = true
    load_module('demo_ljoint_connections.rb')
    if defined?(CabinetrixLJointDemo)
      CabinetrixLJointDemo.create_demo_scene
    end
  end

  def self.build_all
    model = Sketchup.active_model
    raise 'No active model' unless model

    model.start_operation('Gemini Master Showroom Build', true)
    ents = model.active_entities
    ents.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Cabinetrix') || g.name.to_s.start_with?('CG_') }.each { |g| g.erase! }

    $CABINETRIX_NO_AUTORUN = true
    $CABINETRIX_DEMO_NO_AUTORUN = true

    load_module('build_luxury_gola_kitchen_master.rb')
    load_module('gola_drawer_bank_master.rb')
    load_module('demo_ljoint_connections.rb')

    mats = CabinetrixLuxuryKitchen.get_materials(model)

    # 1. Master Luxury Kitchen
    CabinetrixLuxuryKitchen.build_full_kitchen(ents, mats, mode: :hybrid)

    # 2. Standalone 2x Gola Drawer Bank (Spaced to the right)
    CabinetrixMasterGola.build_complete_system(ents, Geom::Point3d.new(4500.mm, 0, 0), mats, mode: :hybrid)

    # 3. L-Joint Fastener Comparison Row (In front)
    CabinetrixLJointDemo.get_materials(model)
    types = [:minifix, :dowel, :screw, :combined]
    types.each_with_index do |t, i|
      CabinetrixLJointDemo.build_l_joint(ents, Geom::Point3d.new(4500.mm + (i * 380.mm), -1200.mm, 0), t, mats)
    end

    model.active_view.zoom_extents if model.active_view
    model.commit_operation

    puts "=========================================================================="
    puts " 🌟 [GEMINI MASTER] Complete Showroom & Kitchen Built Successfully!"
    puts "    1. Full Luxury Gola Kitchen (3600mm Wall Run + 2000x900mm Island)"
    puts "    2. 2x 600mm Gola Drawer Bank with 20x Minifix 15 Joints"
    puts "    3. 18mm L-Joint Fastener Comparison Row"
    puts "=========================================================================="
  end
end

# Auto-run Kitchen by default on direct file load
unless defined?($CABINETRIX_GEMINI_NO_AUTORUN) && $CABINETRIX_GEMINI_NO_AUTORUN
  RunGeminiMaster.build_kitchen if defined?(Sketchup) && Sketchup.active_model
end
