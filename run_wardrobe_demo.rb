# =============================================================================
# Cabinex AI — Wardrobe Demo (master engine build_wardrobe test)
# (c) 2026 Cabinex AI. All Rights Reserved.
#
# Tests the NEW build_wardrobe + build_wardrobe_run in the combined engine:
#   - hinged sash robe (inner carcase + 2 cover sides + hanging rail)
#   - sliding 2-leaf robe w/ mirror
#   - sliding robe w/ rods + drawer bank + shelves
#   - a continuous robe run (plinth merged across the bank)
#
# USAGE (SketchUp Ruby console):
#   load "C:/Users/asank/Documents/CabinexAi/run_wardrobe_demo.rb"
#   RunWardrobeDemo.build
# =============================================================================

require 'sketchup.rb'

load File.expand_path('cbx_cabinet_method.rb', __dir__) if File.exist?(File.expand_path('cbx_cabinet_method.rb', __dir__))
load File.expand_path('cbx_hybrid_engine.rb', __dir__) if File.exist?(File.expand_path('cbx_hybrid_engine.rb', __dir__))

module RunWardrobeDemo
  def self.materials(model)
    definitions = {
      wood: ['18mm Melamine White', [242, 240, 235]],
      alu: ['Alu Sash Profile Anodized', [45, 48, 52]],
      glass: ['Glass Translucent Clear', [200, 230, 245]],
      acp: ['White ACP Cladding', [245, 245, 245]],
      hole: ['Hole Dark', [20, 20, 20]],
      gola: ['Gola Brushed Aluminum', [165, 170, 178]],
      appliance: ['Appliance Black Glass', [35, 38, 43]],
      mirror: ['Wardrobe Mirror', [200, 210, 225]]
    }
    mats = {}
    definitions.each do |key, (name, rgb)|
      material = model.materials[name] || model.materials.add(name)
      material.color = Sketchup::Color.new(*rgb)
      mats[key] = material
    end
    mats[:glass].alpha = 0.40
    mats[:mirror].alpha = 1.0
    mats
  end

  def self.build
    model = Sketchup.active_model
    raise 'No active model.' unless model
    model.start_operation('WardrobeDemo', true)

    ents = model.active_entities
    ents.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('WD_') }.each { |g| g.erase! }

    mats = materials(model)
    method = CBXCabinetMethod.get('BOARD_WARDROBE')
    puts ">> Method: #{method[:id]}  front=#{method[:front][:system]}  infill=#{method[:front][:infill]}"
    puts ">> Connector (finished_end): #{CBXCabinetMethod.resolve_connectors(method, :finished_end).inspect}"

    # ---- 1. HINGED sash robe (rods + rail) ----
    a = CBXHybridEngine.build_wardrobe(
      ents, { width: 900.mm, height: 2200.mm, depth: 600.mm, door: :hinged, rods: 1, drawers: 3, x: 0.mm }, mats
    )
    a.name = 'WD_Hinged'

    # ---- 2. SLIDING 2-leaf robe + mirror ----
    b = CBXHybridEngine.build_wardrobe(
      ents, { width: 1800.mm, height: 2200.mm, depth: 600.mm, door: :sliding, leaves: 2, mirror: true, x: 3000.mm }, mats
    )
    b.name = 'WD_SlidingMirror'

    # ---- 3. SLIDING robe with rods + drawer bank + shelves ----
    c = CBXHybridEngine.build_wardrobe(
      ents, { width: 2400.mm, height: 2200.mm, depth: 600.mm, door: :sliding, leaves: 2, rods: 1, drawers: 3, shelves: 4, x: 5600.mm }, mats
    )
    c.name = 'WD_RodsDrawers'

    # ---- 4. CONTINUOUS robe run (plinth merged across 3 units) ----
    run = CBXHybridEngine.build_wardrobe_run(
      ents,
      [ { width: 900.mm, door: :sliding, leaves: 2, rods: 1 },
        { width: 900.mm, door: :sliding, leaves: 2, drawers: 4 },
        { width: 900.mm, door: :hinged, rods: 2 } ],
      { height: 2200.mm, depth: 600.mm, x: 8800.mm, y: 0.mm, z: 0.mm }, mats
    )
    run.name = 'WD_RobeRun'

    model.commit_operation
    model.active_view.zoom_extents rescue nil

    puts '>> WardrobeDemo built:'
    puts '   1. Hinged sash robe (inner carcase + 2 cover sides + hanging rail + drawers)'
    puts '   2. Sliding 2-leaf robe + mirror infill (top/bottom track)'
    puts '   3. Sliding robe with rods + drawer bank + 4 shelves'
    puts '   4. Continuous robe run of 3 adjoining units (merged plinth)'
    puts '>> OK'
  end
end
