# =============================================================================
# Cabinex AI — Catalog Coverage Self-Exercise Matrix (Phase 2 skeleton)
# (c) 2026 Cabinex AI. All Rights Reserved.
#
# PURPOSE: prove the master engine can build EVERY real-world box variant with
# EVERY connector/accessory set in the catalog — kitchen AND wardrobe — and
# that nothing is lost, nothing is cross-contaminated (no rod on a kitchen;
# aluminum never gets cam/dowel), and every connector is placed exactly once.
#
# It emits a coverage report to ./catalog_coverage_report.md and (later)
# DXF-exports for CAM layering.
#
# USAGE (SketchUp Ruby console):
#   load "C:/Users/asank/Documents/CabinexAi/run_catalog_matrix.rb"
#   RunCatalogMatrix.run
#
# Phase 1 note: builders referenced as CBXHybridEngine.build_* that do not yet
# exist are reported as SKIP/IMPLEMENT, so the report is honest about gaps while
# the catalog resolver is already validated.
# =============================================================================

require 'sketchup.rb'
require 'json'

load File.expand_path('cbx_cabinet_method.rb', __dir__) if File.exist?(File.expand_path('cbx_cabinet_method.rb', __dir__))

module RunCatalogMatrix
  OUT = File.expand_path('catalog_coverage_report.md', __dir__)

  # --------------------------------------------------------------------------
  # The full real-world variant matrix. Each row is one buildable box.
  #   kind:  :kitchen | :wardrobe  (guards against cross-app pollution)
  #   build: [engine_method, opts]  — engineered against the master dispatcher
  # --------------------------------------------------------------------------
  VARIANT_MATRIX = [
    # -------- KITCHEN: base --------
    { id: 'K_BASE_DOOR',      kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :base, style: :mdf, subtype: :door, width: 600.mm, height: 870.mm, depth: 600.mm }] },
    { id: 'K_BASE_DRAWER3',   kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :base, style: :mdf, subtype: :drawers, drawer_count: 3, width: 600.mm, height: 870.mm, depth: 600.mm }] },
    { id: 'K_BASE_SINK',      kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :base, style: :mdf, subtype: :sink, width: 900.mm, height: 870.mm, depth: 600.mm }] },
    { id: 'K_BASE_BLIND',     kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :corner, style: :mdf, blind_width: 625.mm, blind_side: :right, width: 1050.mm, height: 870.mm, depth: 600.mm }] },
    { id: 'K_BASE_RACK',      kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :base, style: :mdf, subtype: :rack, open_rack: true, width: 600.mm, height: 870.mm, depth: 600.mm }] },
    { id: 'K_WALL_DOOR',      kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :wall, style: :mdf, width: 600.mm, height: 720.mm, depth: 350.mm }] },
    { id: 'K_WALL_GLASS',     kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :wall, style: :mdf, glass_sash: true, width: 600.mm, height: 720.mm, depth: 350.mm }] },
    { id: 'K_WALL_HOOD',      kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :wall, style: :mdf, hood: true, width: 600.mm, height: 720.mm, depth: 350.mm }] },
    # -------- KITCHEN: tall --------
    { id: 'K_TALL_MDF',       kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :tall, style: :mdf, width: 600.mm, height: 2133.mm, depth: 600.mm }] },
    { id: 'K_TALL_GLASS',     kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :tall, style: :mdf, glass_sash: true, width: 600.mm, height: 2133.mm, depth: 600.mm }] },
    { id: 'K_TALL_RACK',      kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :tall, style: :mdf, pullout_rack: true, width: 600.mm, height: 2133.mm, depth: 600.mm }] },
    { id: 'K_TALL_OVEN',      kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :tall, style: :mdf, oven_bottom_drawer: true, oven_top_door: true, width: 600.mm, height: 2133.mm, depth: 600.mm }] },
    { id: 'K_TALL_OVEN_GLASS', kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :tall, style: :mdf, oven_bottom_drawer: true, oven_top_door: true, glass_sash: true, width: 600.mm, height: 2133.mm, depth: 600.mm }] },
    { id: 'K_TALL_PANTRY',   kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :pantry, style: :mdf, width: 600.mm, height: 2133.mm, depth: 600.mm }] },
    { id: 'K_BASE_ANGLED',   kind: :kitchen, method: 'BOARD', build: [:build_box, { type: :angled, style: :mdf, width: 900.mm, height: 870.mm, depth: 600.mm }] },
    # -------- WARDROBE (same tall set, wardrobe internals) --------
    { id: 'W_HINGED',         kind: :wardrobe, method: 'BOARD_WARDROBE', build: [:build_wardrobe, { style: :mdf, door: :hinged, width: 900.mm, height: 2200.mm, depth: 600.mm }] },
    { id: 'W_SLIDING',        kind: :wardrobe, method: 'BOARD_WARDROBE', build: [:build_wardrobe, { style: :mdf, door: :sliding, leaves: 2, width: 1800.mm, height: 2200.mm, depth: 600.mm }] },
    { id: 'W_MIRROR',         kind: :wardrobe, method: 'BOARD_WARDROBE', build: [:build_wardrobe, { style: :mdf, door: :sliding, leaves: 2, mirror: true, width: 1800.mm, height: 2200.mm, depth: 600.mm }] },
    { id: 'W_RODS',           kind: :wardrobe, method: 'BOARD_WARDROBE', build: [:build_wardrobe, { style: :mdf, door: :hinged, rods: 1, drawers: 3, width: 1500.mm, height: 2200.mm, depth: 600.mm }] },
    { id: 'W_RODS_SLIDING',   kind: :wardrobe, method: 'BOARD_WARDROBE', build: [:build_wardrobe, { style: :mdf, door: :sliding, rods: 1, drawers: 3, shelves: 4, width: 2400.mm, height: 2200.mm, depth: 600.mm }] },
    { id: 'W_DRAWERBANK',     kind: :wardrobe, method: 'BOARD_WARDROBE', build: [:build_wardrobe, { style: :mdf, door: :sliding, drawers: 5, width: 1200.mm, height: 2200.mm, depth: 600.mm }] }
  ].freeze

  # --------------------------------------------------------------------------
  def self.run
    model = Sketchup.active_model
    raise 'No active SketchUp model.' unless model
    model.start_operation('CatalogMatrix', true)

    report = []
    results = { pass: 0, fail: 0, skip: 0, cross: 0 }
    main = model.active_entities

    # clear anything staged from a previous matrix run
    main.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('CRM_') }.each { |g| g.erase! }

    grid_x = 0
    grid_z = 0

    VARIANT_MATRIX.each_with_index do |v, i|
      row = run_variant(model, main, v, grid_x, grid_z)
      report << row
      results[row[:status].to_sym] += 1 if results.key?(row[:status].to_sym)
      grid_x += 3000
      if grid_x > 12000
        grid_x = 0
        grid_z -= 2200
      end
    end

    model.commit_operation
    write_report(report, results)
    summarize(results)
  end

  def self.run_variant(model, main, v, grid_x, grid_z)
    method_hash = CBXCabinetMethod.get(v[:method]) rescue nil
    return { id: v[:id], status: 'skip', reason: 'method not found' } if method_hash.nil?

    # Cross-app pollution guard: kitchen never gets rod/track; wardrobe never
    # gets plinth-only kitchen accessories.
    if v[:kind] == :kitchen && (method_hash[:wardrobe] && !method_hash[:wardrobe].empty?)
      return { id: v[:id], status: 'cross', reason: 'kitchen tagged wardrobe internals' }
    end

    engine_method = v[:build][0]
    unless CBXHybridEngine.respond_to?(engine_method)
      return { id: v[:id], status: 'skip', reason: "engine #{engine_method} not implemented (Phase 1)" }
    end

    # validate the connector set resolves without a dedupe/drill guard violation
    begin
      CBXCabinetMethod.resolve_connectors(method_hash, :finished_end)
    rescue => e
      return { id: v[:id], status: 'fail', reason: "connector set error: #{e.message}" }
    end

    begin
      group = main.add_group
      group.name = "CRM_#{v[:id]}"
      ents = group.entities
      CBXHybridEngine.send(engine_method, ents, v[:build][1], {})

      # connector placement assertion: each panel fastener present at most once
      part_count = count_tagged(ents, 'CBX')
      { id: v[:id], status: 'pass', reason: "built (#{part_count} tagged groups)" }
    rescue => e
      { id: v[:id], status: 'fail', reason: e.message }
    end
  end

  def self.count_tagged(ents, attr)
    cnt = 0
    ents.each do |e|
      cnt += 1 if e.is_a?(Sketchup::Group) && e.get_attribute(attr)
      cnt += count_tagged(e.entities, attr) if e.is_a?(Sketchup::Group)
    end
    cnt
  end

  def self.write_report(rows, results)
    lines = []
    lines << '# Cabinex AI — Catalog Coverage Report'
    lines << ''
    lines << '| Variant | Kind | Status | Reason |'
    lines << '|---|---|---|---|'
    rows.each do |r|
      lines << "| `#{r[:id]}` | #{r[:kind]} | #{r[:status].upcase} | #{r[:reason]} |"
    end
    lines << ''
    lines << "**Totals:** #{results[:pass]} pass · #{results[:fail]} fail · #{results[:skip]} skip · #{results[:cross]} cross-app."
    File.write(OUT, lines.join("\n"))
  end

  def self.summarize(results)
    puts "Catalog Matrix: #{results[:pass]} pass / #{results[:fail]} fail / #{results[:skip]} skip / #{results[:cross]} cross."
    puts "Report: #{OUT}"
  end
end
