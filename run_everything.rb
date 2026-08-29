require 'sketchup.rb'
require 'json'

module RunEverything
  def self.build
    model = Sketchup.active_model
    raise 'No active model.' unless model

    load File.expand_path('cbx_cabinet_method.rb', __dir__) if File.exist?(File.expand_path('cbx_cabinet_method.rb', __dir__))
    load File.expand_path('cbx_hybrid_engine.rb', __dir__) if File.exist?(File.expand_path('cbx_hybrid_engine.rb', __dir__))

    all = model.active_entities

    # --- distinct zones so displays never overlap ---
    bd_x = 0.mm
    wd_x = 16_000.mm
    crm_x = 32_000.mm

    # ---- 1. Board kitchen demo ----
    load File.expand_path('run_board_demo.rb', __dir__) if File.exist?(File.expand_path('run_board_demo.rb', __dir__))
    if defined?(RunBoardDemo)
      RunBoardDemo.build
      regroup('BD_', all, bd_x, 0, 0)
    end

    # ---- 2. Wardrobe demo ----
    load File.expand_path('run_wardrobe_demo.rb', __dir__) if File.exist?(File.expand_path('run_wardrobe_demo.rb', __dir__))
    if defined?(RunWardrobeDemo)
      RunWardrobeDemo.build
      regroup('WD_', all, wd_x, 0, 0)
    end

    # ---- 3. Catalog matrix (own grid, 3 columns) ----
    load File.expand_path('run_catalog_matrix.rb', __dir__) if File.exist?(File.expand_path('run_catalog_matrix.rb', __dir__))
    if defined?(RunCatalogMatrix)
      RunCatalogMatrix.run
      regroup('CRM_', all, crm_x, 0, 0)
    end

    # ---- 4. Scrape real model data into JSON/TXT report ----
    load File.expand_path('run_report_dump.rb', __dir__) if File.exist?(File.expand_path('run_report_dump.rb', __dir__))
    RunReportDump.dump if defined?(RunReportDump)

    model.active_view.zoom_extents rescue nil
    puts '====> RunEverything: ALL DISPLAYS BUILT, ZONED, AND REPORTED <===='
  end

  # Move every group whose name starts with prefix by [dx,dy,dz].
  def self.regroup(prefix, entities, dx, dy, dz)
    t = Geom::Transformation.translation([dx, dy, dz])
    entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?(prefix) }.each do |g|
      g.transform!(t)
    end
  end
end
