# =============================================================================
# Cabinex AI — Phase 1 Board Demo (boxes + cuts + openings + Gola/plinth combine)
# (c) 2026 Cabinex AI. All Rights Reserved.
#
# Quick visual acceptance of the master combined engine's BOARD builders:
#   - 3-drawer base
#   - 2-door base (door base)
#   - top / wall cabinet
#   - normal tall unit
#   - tall with bottom drawers + oven + microwave + top door (the board tall oven)
# Then run the MERGED Gola + MERGED plinth combining logic across the base run.
# No tooling/CNC — just boxes, cuts, openings, Gola + plinth combine.
#
# USAGE (SketchUp Ruby console):
#   load "C:/Users/asank/Documents/CabinexAi/run_board_demo.rb"
#   RunBoardDemo.build
# =============================================================================

require 'sketchup.rb'

load File.expand_path('cbx_cabinet_method.rb', __dir__) if File.exist?(File.expand_path('cbx_cabinet_method.rb', __dir__))
load File.expand_path('cbx_hybrid_engine.rb', __dir__) if File.exist?(File.expand_path('cbx_hybrid_engine.rb', __dir__))

module RunBoardDemo
  BOARD_W = 600.mm
  BOARD_H = 870.mm
  BOARD_D = 600.mm
  TOP_W = 600.mm
  TOP_H = 720.mm
  TOP_D = 350.mm
  TALL_W = 600.mm
  TALL_H = 2133.mm
  TALL_D = 600.mm
  PLINTH = 100.mm

  def self.materials(model)
    definitions = {
      wood: ['18mm Melamine White', [242, 240, 235]],
      alu: ['Alu Sash Profile Anodized', [45, 48, 52]],
      glass: ['Glass Translucent Clear', [200, 230, 245]],
      acp: ['White ACP Cladding', [245, 245, 245]],
      hole: ['Hole Dark', [20, 20, 20]],
      gola: ['Gola Brushed Aluminum', [165, 170, 178]],
      appliance: ['Appliance Black Glass', [35, 38, 43]],
      rack: ['Open Rack Warm White', [232, 224, 210]]
    }
    mats = {}
    definitions.each do |key, (name, rgb)|
      material = model.materials[name] || model.materials.add(name)
      material.color = Sketchup::Color.new(*rgb)
      mats[key] = material
    end
    mats[:glass].alpha = 0.40
    mats
  end

  def self.build
    model = Sketchup.active_model
    raise 'No active model.' unless model
    model.start_operation('BoardDemo', true)

    ents = model.active_entities
    # clear previous demo
    ents.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('BD_') }.each { |g| g.erase! }

    mats = materials(model)
    method = CBXCabinetMethod.get('BOARD')
    puts ">> Method: #{method[:id]}  carcase=#{method[:carcase][:system]}  back=#{method[:carcase][:back_mm]}mm"

    # ---- 1+2. ONE CONTIGUOUS BASE RUN: 3-drawer + 3-drawer + 2-door ----
    # build_run(style: :mdf) lays them at local cur_x, then merges the Gola
    # (L/C profiles joined across adjacent cabinets) AND the plinth cover into
    # one continuous run, so the combining logic is visible across all three.
    base_run = ents.add_group
    base_run.name = 'BD_ContiguousBaseRun'
    CBXHybridEngine.build_run(
      base_run.entities,
      [
        { width: BOARD_W, subtype: :drawers, drawer_count: 3 },
        { width: BOARD_W, subtype: :drawers, drawer_count: 3 },
        { width: 900.mm, subtype: :doors, drawer_count: 0 }
      ],
      { width: BOARD_W + BOARD_W + 900.mm, height: BOARD_H, depth: BOARD_D, style: :mdf,
        x: 0.mm, y: 0.mm, z: 0.mm }, mats
    )

    # ---- 3. TOP / WALL cabinet ----
    wall = CBXHybridEngine.build_board_wall(
      ents, { width: TOP_W, height: TOP_H, depth: TOP_D, x: 4200.mm, y: 0.mm, z: 1500.mm }, mats
    )
    wall.name = 'BD_TopCabinet'

    # ---- 4. NORMAL TALL (board tall carcase + inset glass sash) ----
    tall = CBXHybridEngine.build_tall_cabinet(
      ents, { width: TALL_W, height: TALL_H, depth: TALL_D, x: 5200.mm, y: 0.mm, z: 0.mm, plinth: PLINTH }, mats
    )
    tall.name = 'BD_TallNormal'

    # ---- 5. TALL WITH OVENS + DRAWERS (board tall oven) ----
    ovens = CBXHybridEngine.build_board_tall_oven(
      ents, { width: TALL_W - 2 * 18.mm, height: TALL_H, depth: TALL_D, x: 6400.mm, y: 0.mm, z: 0.mm, plinth: PLINTH }, mats
    )
    ovens.name = 'BD_TallOvens'

    model.commit_operation
    model.active_view.zoom_extents rescue nil

    puts '>> BoardDemo built:'
    puts '   1. CONTIGUOUS base run (3-drawer + 3-drawer + 2-door)'
    puts '      -> merged Gola (L/C joined across all 3 cabinets)'
    puts '      -> merged plinth cover (one continuous run)'
    puts '   2. Top / wall cabinet'
    puts '   3. Normal tall (inner carcase + 2 cover sides + glass sash)'
    puts '   4. Tall with bottom drawers + oven 595 + microwave 455 + top door'
    puts '>> Merged Gola + plinth runs applied by build_run across the run.'
    puts '>> OK'
  end
end
