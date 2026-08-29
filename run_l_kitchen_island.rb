# =============================================================================
# CABINETRIX — LUXURY GOLA KITCHEN (delegates to the proven master builder)
# (c) 2026 Cabinex AI.
#
# This runner LOADS the high-quality gemini master builder (CabinetrixLuxuryKitchen)
# WITHOUT editing it, and calls its GEOMETRY-ONLY entry build_full_kitchen(mode).
# The master produces the authentic result (Gola overlap fronts, 5-piece
# undermount boxes, alu sash glass doors, waterfall island, triple rear
# stretchers, selective drilling). We suppress its auto-run + report so we only
# get clean geometry - no menu, no report, engine-only.
#
# USAGE (SketchUp Ruby console):
#   load "C:/Users/asank/Documents/CabinetrixAionline/run_l_kitchen_island.rb"
#   RunLKitchen.build
# =============================================================================
require 'sketchup.rb'

module RunLKitchen
  # Load a guarded COPY of the gemini master (the gemini/ folder file itself is
  # never edited; we use our build/ copy whose auto-run is suppressed).
  GEMINI = "C:/Users/asank/Documents/CabinetrixAionline/build/luxury_gola_kitchen_master.rb"

  def self.load_master
    Object.const_set(:CABINETRIX_NO_AUTORUN, true) unless defined?(CABINETRIX_NO_AUTORUN)
    load GEMINI if File.exist?(GEMINI)
    defined?(CabinetrixLuxuryKitchen) && (CabinetrixLuxuryKitchen.respond_to?(:build_full_kitchen) || CabinetrixLuxuryKitchen.respond_to?(:build))
  end

  def self.build(mode: :hybrid)
    model = Sketchup.active_model
    raise 'No active model.' unless model
    raise 'Gemini master builder not found.' unless load_master

    model.start_operation('LuxuryGolaKitchen', true)
    begin
      ents = model.active_entities
      # clear previous run
      ents.grep(Sketchup::Group).select { |g| g.name.to_s =~ /Cabinetrix|Box_0|Kitchen/i }.each { |g| g.erase! }
      mats = CabinetrixLuxuryKitchen.get_materials(model)
      # geometry ONLY (build_full_kitchen never opens the report)
      if CabinetrixLuxuryKitchen.respond_to?(:build_full_kitchen)
        CabinetrixLuxuryKitchen.build_full_kitchen(ents, mats, mode: mode)
      else
        CabinetrixLuxuryKitchen.build(mode: mode)
      end
      model.active_view.zoom_extents rescue nil
      model.commit_operation
      puts '>> Luxury Gola Kitchen built (gemini master, geometry-only):'
      puts '    Tall oven tower + larder, Gola base run, glass wall units, waterfall island'
      puts '>> Gola overlap fronts, 5-piece undermount boxes, alu sash glass, triple rear stretchers'
      puts '>> OK (no menus, no reports - engineering proof only)'
    rescue => err
      model.abort_operation
      puts ">> Kitchen build error: #{err.message}"
      puts err.backtrace.first(5).join("\n")
    end
  end
end
