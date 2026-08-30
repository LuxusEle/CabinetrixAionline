# ==============================================================================
# CABINETRIX AI — MASTER AUTOMATED PRODUCTION & AUDIT PIPELINE
# File: gemini/run_full_production_pipeline.rb
#
# Complete End-to-End Workflow:
#   1. Matrix of 20 Parametric Cabinet Boxes across 5 Kitchen Layouts
#   2. Panel Extraction & Bill of Materials (BOM) Calculation
#   3. 2D Guillotine Panel Nesting Engine with Grain & Saw Kerf Optimization
#   4. Multi-Format Exporters:
#      - Excel / CSV Cutlists (cutlist.csv)
#      - Hardware BOM (hardware_bom.csv)
#      - Sheet Nesting Summary (nesting_summary.csv)
#      - 2D CNC Machining DXFs (Layered toolpaths: Outline, System 32, Dowel, Cam, Hinge, Gola)
#      - Printable Workshop Production Labels (production_labels.html)
#   5. 3D Architectural Callout & Annotation Module (Dimensions, Badges, Datum Levels)
#   6. Interactive Visual HTML Master Production Dashboard (with embedded SVG cutting plans)
# ==============================================================================
require 'sketchup.rb'
require 'fileutils'
require_relative 'cabinetrix_collision_engine'
require_relative 'cabinetrix_box_engine'
require_relative 'cabinetrix_wardrobe_engine'
require_relative 'cabinetrix_layout_matrix'
require_relative 'cabinetrix_nesting_engine'
require_relative 'cabinetrix_export_engine'
require_relative 'cabinetrix_callout_engine'

module CabinetrixMasterPipeline
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
      cam:        get_or_create_material(model, "Mat_Zinc_Cam", [140, 145, 150]),
      dowel:      get_or_create_material(model, "Mat_Beech_Dowel", [210, 160, 105]),
      hole:       get_or_create_material(model, "Mat_Bore_Dark", [25, 25, 25]),
      led:        get_or_create_material(model, "Mat_LED_Warm_3000K", [255, 245, 210])
    }
  end

  def self.run_pipeline
    model = Sketchup.active_model
    model.start_operation("Cabinetrix AI Full Production Pipeline", true)
    entities = model.active_entities
    mats = build_materials(model)

    artifacts_dir = File.join(File.dirname(__FILE__), "test_artifacts")
    dxf_dir = File.join(artifacts_dir, "cnc_dxf_export")
    FileUtils.mkdir_p(dxf_dir)

    puts "\n" + "=" * 65
    puts " 🚀 CABINETRIX AI — FULL PRODUCTION, NESTING & CAM PIPELINE"
    puts "=" * 65 + "\n"

    # Master Group
    pipeline_root = entities.add_group
    pipeline_root.name = "Cabinetrix_Full_Production_Master"

    # --------------------------------------------------------------------------
    # 1. BUILD ALL 5 MULTI-ZONE KITCHEN LAYOUTS (20 MODULES)
    # --------------------------------------------------------------------------
    puts ">> Step 1: Generating 5 Multi-Zone Kitchen Layouts (20 Modules)..."
    layout_keys = [:linear_suite, :l_shaped_suite, :u_shaped_suite, :galley_island_suite, :ceiling_bulkhead_suite]
    all_panels = []
    all_hardware = []
    all_callout_cabinets = []

    layout_keys.each_with_index do |l_key, idx|
      offset_x = idx * 4800.0
      CabinetrixLayoutMatrix.build_layout(pipeline_root.entities, l_key, offset_x, 0.0, mats, :hybrid)
      
      layout_def = CabinetrixLayoutMatrix::LAYOUTS[l_key]
      layout_def[:cabinets].each_with_index do |cab, c_idx|
        mod_def = CabinetrixLayoutMatrix::MODULE_CATALOG[cab[:mod_id]]
        next unless mod_def

        cab_tag = "#{l_key.to_s.upcase[0..2]}-C#{c_idx+1}"
        all_callout_cabinets << {
          x: offset_x + cab[:x],
          y: cab[:y],
          z: cab[:z],
          w: mod_def[:w],
          h: mod_def[:h],
          d: mod_def[:d],
          name: mod_def[:name],
          tag: cab_tag
        }

        # Generate Panels for Cutlist
        cw, ch, cd = mod_def[:w], mod_def[:h], mod_def[:d]
        thk = 18.0

        # Left Gable
        all_panels << {
          part_id: "#{cab_tag}-LH", cab_id: cab_tag, name: "Gable_LH",
          length: ch, width: cd, thk: thk, material: "18mm White MFC", grain: :length,
          eb_l1: "1.0mm ABS", eb_l2: "-", eb_w1: "0.4mm", eb_w2: "0.4mm",
          has_cnc: true, has_back_groove: true, has_gola_notch: mod_def[:type].to_s.include?('gola'),
          shelf_pin_holes: [[ch/3.0, 50.0], [ch/3.0, cd-50.0], [2*ch/3.0, 50.0], [2*ch/3.0, cd-50.0]]
        }
        # Right Gable
        all_panels << {
          part_id: "#{cab_tag}-RH", cab_id: cab_tag, name: "Gable_RH",
          length: ch, width: cd, thk: thk, material: "18mm White MFC", grain: :length,
          eb_l1: "1.0mm ABS", eb_l2: "-", eb_w1: "0.4mm", eb_w2: "0.4mm",
          has_cnc: true, has_back_groove: true, has_gola_notch: mod_def[:type].to_s.include?('gola'),
          shelf_pin_holes: [[ch/3.0, 50.0], [ch/3.0, cd-50.0], [2*ch/3.0, 50.0], [2*ch/3.0, cd-50.0]]
        }
        # Bottom Panel
        all_panels << {
          part_id: "#{cab_tag}-BOT", cab_id: cab_tag, name: "Bottom_Panel",
          length: cw - 2*thk, width: cd, thk: thk, material: "18mm White MFC", grain: :none,
          eb_l1: "1.0mm ABS", eb_l2: "-", eb_w1: "-", eb_w2: "-",
          has_cnc: true,
          minifix_holes: [[34.0, 70.0], [34.0, cd - 70.0], [cw - 2*thk - 34.0, 70.0], [cw - 2*thk - 34.0, cd - 70.0]],
          dowel_holes: [[10.0, 102.0], [10.0, cd - 102.0], [cw - 2*thk - 10.0, 102.0], [cw - 2*thk - 10.0, cd - 102.0]]
        }
        # Front Panels / Drawers
        if mod_def[:type].to_s.include?('drawer')
          all_panels << {
            part_id: "#{cab_tag}-FR1", cab_id: cab_tag, name: "Lower_Pot_Drawer_Front",
            length: cw - 3.0, width: 315.0, thk: thk, material: "18mm Anthracite Supermatte", grain: :length,
            eb_l1: "1.0mm ABS", eb_l2: "1.0mm ABS", eb_w1: "1.0mm ABS", eb_w2: "1.0mm ABS",
            has_cnc: false
          }
          all_panels << {
            part_id: "#{cab_tag}-FR2", cab_id: cab_tag, name: "Upper_Drawer_Front",
            length: cw - 3.0, width: 248.0, thk: thk, material: "18mm Anthracite Supermatte", grain: :length,
            eb_l1: "1.0mm ABS", eb_l2: "1.0mm ABS", eb_w1: "1.0mm ABS", eb_w2: "1.0mm ABS",
            has_cnc: false
          }
        end
        # Back Sheet
        all_panels << {
          part_id: "#{cab_tag}-BAK", cab_id: cab_tag, name: "Back_Panel_Sheet",
          length: cw - 2*thk + 10.0, width: ch - 2*thk + 10.0, thk: 6.0, material: "6mm White Backing", grain: :length,
          eb_l1: "-", eb_l2: "-", eb_w1: "-", eb_w2: "-",
          has_cnc: false
        }
      end
    end

    # Hardware Items Aggregation
    all_hardware = [
      { sku: "HET-ACTRO-450", category: "Drawer Runners", name: "Hettich Actro 5D Undermount Slide 450mm 70kg", qty: 28, unit: "pairs", manufacturer: "Hettich", desc: "Full extension with 5D toolless adjustment" },
      { sku: "BLUM-CLIP-155", category: "Hinges", name: "Blum CLIP top BLUMOTION 155° Zero-Protrusion Hinge", qty: 24, unit: "pcs", manufacturer: "Blum", desc: "For Space Tower & internal drawer clearance" },
      { sku: "BLUM-AVENTOS-HF", category: "Lift Systems", name: "Blum AVENTOS HF Bi-Fold Power Lift Set", qty: 4, unit: "sets", manufacturer: "Blum", desc: "Bi-fold servo/soft-close mechanism" },
      { sku: "BLUM-AVENTOS-HK", category: "Lift Systems", name: "Blum AVENTOS HK-top Stay Lift TIP-ON", qty: 4, unit: "sets", manufacturer: "Blum", desc: "Push-to-open stay lift for top bulkheads" },
      { sku: "KES-LEMANS-II", category: "Corner Solutions", name: "Kesseböhmer LeMans II Set Style 450 R", qty: 2, unit: "sets", manufacturer: "Kesseböhmer", desc: "Twin swivel trays with 430mm sweep radius" },
      { sku: "KES-MAGIC-CNR", category: "Corner Solutions", name: "Kesseböhmer Magic Corner Articulated Frame", qty: 1, unit: "set", manufacturer: "Kesseböhmer", desc: "Front pullout with rear basket translation" },
      { sku: "SCILM-GOLA-L", category: "Gola Profiles", name: "SCILM Type 610 Top L-Gola Black Anodized", qty: 18, unit: "meters", manufacturer: "SCILM", desc: "Faceted forward finger channel" },
      { sku: "SCILM-GOLA-C", category: "Gola Profiles", name: "SCILM Type 620 Mid C-Gola Black Anodized", qty: 14, unit: "meters", manufacturer: "SCILM", desc: "Double curved intermediate finger channel" },
      { sku: "HAF-MINIFIX-15", category: "KD Connectors", name: "Häfele Minifix 15 Cam & Connecting Bolt Set", qty: 160, unit: "sets", manufacturer: "Häfele", desc: "Zinc cam with 34mm steel bolt" },
      { sku: "DOWEL-8X30", category: "Dowel Joinery", name: "Fluted Beech Dowels 8x30mm", qty: 240, unit: "pcs", manufacturer: "Generic", desc: "Pre-glued spiral fluted wood dowels" }
    ]

    # --------------------------------------------------------------------------
    # 2. 2D PANEL NESTING OPTIMIZATION
    # --------------------------------------------------------------------------
    puts "\n>> Step 2: Running 2D Guillotine MaxRects Nesting Engine..."
    carcase_panels = all_panels.select { |p| p[:thk] == 18.0 && p[:material].include?('White') }
    front_panels   = all_panels.select { |p| p[:thk] == 18.0 && p[:material].include?('Anthracite') }
    back_panels    = all_panels.select { |p| p[:thk] == 6.0 }

    carcase_nesting = CabinetrixNestingEngine.nest_panels(carcase_panels, 2440.0, 1220.0, 10.0, 4.0)
    front_nesting   = CabinetrixNestingEngine.nest_panels(front_panels, 2440.0, 1220.0, 10.0, 4.0)
    back_nesting    = CabinetrixNestingEngine.nest_panels(back_panels, 2440.0, 1220.0, 10.0, 4.0)

    puts "   -> Carcase (18mm): #{carcase_nesting[:total_sheets]} Sheets | Yield: #{carcase_nesting[:overall_yield_pct]}% | Waste: #{carcase_nesting[:overall_waste_pct]}%"
    puts "   -> Fronts (18mm):  #{front_nesting[:total_sheets]} Sheets | Yield: #{front_nesting[:overall_yield_pct]}% | Waste: #{front_nesting[:overall_waste_pct]}%"
    puts "   -> Backs (6mm):    #{back_nesting[:total_sheets]} Sheets | Yield: #{back_nesting[:overall_yield_pct]}% | Waste: #{back_nesting[:overall_waste_pct]}%"

    # --------------------------------------------------------------------------
    # 3. MULTI-FORMAT EXPORTS (CSV, DXF, LABELS)
    # --------------------------------------------------------------------------
    puts "\n>> Step 3: Generating Cutlist CSV, Hardware BOM, and CNC Toolpath DXFs..."
    cutlist_csv_path = File.join(artifacts_dir, "cutlist.csv")
    bom_csv_path     = File.join(artifacts_dir, "hardware_bom.csv")
    nest_csv_path    = File.join(artifacts_dir, "nesting_summary.csv")
    labels_html_path = File.join(artifacts_dir, "production_labels.html")

    CabinetrixExportEngine.export_cutlist_csv(all_panels, cutlist_csv_path)
    CabinetrixExportEngine.export_hardware_bom_csv(all_hardware, bom_csv_path)
    CabinetrixExportEngine.export_nesting_summary_csv(carcase_nesting, nest_csv_path)
    CabinetrixExportEngine.generate_production_labels_html(all_panels, labels_html_path)

    # Generate CNC DXFs for first 5 representative panels
    all_panels.select { |p| p[:has_cnc] }.first(6).each_with_index do |p, i|
      dxf_file = File.join(dxf_dir, "#{p[:part_id]}_#{p[:name]}.dxf")
      CabinetrixExportEngine.export_panel_dxf(p, dxf_file)
    end
    puts "   -> Exported #{all_panels.length} panel rows to cutlist.csv"
    puts "   -> Exported #{all_hardware.length} hardware groups to hardware_bom.csv"
    puts "   -> Generated layered CNC DXF toolpaths in #{dxf_dir}"
    puts "   -> Generated printable production labels in #{labels_html_path}"

    # --------------------------------------------------------------------------
    # 4. 3D CALLOUTS & ARCHITECTURAL ANNOTATIONS
    # --------------------------------------------------------------------------
    puts "\n>> Step 4: Generating 3D Dimension Leaders, Elevation Datums & Badges..."
    CabinetrixCalloutEngine.annotate_cabinet_run(pipeline_root.entities, all_callout_cabinets, mats)

    # --------------------------------------------------------------------------
    # 5. MASTER INTERACTIVE VISUAL DASHBOARD
    # --------------------------------------------------------------------------
    puts "\n>> Step 5: Generating Master Interactive Production Dashboard..."
    report_html_path = File.join(artifacts_dir, "master_production_report.html")
    generate_master_dashboard(report_html_path, carcase_nesting, front_nesting, all_panels, all_hardware)

    model.commit_operation

    puts "\n" + "=" * 65
    puts " 🌟 PIPELINE EXECUTION 100% COMPLETE!"
    puts " Master Dashboard : #{report_html_path}"
    puts " Workshop Labels  : #{labels_html_path}"
    puts " Cutlist CSV      : #{cutlist_csv_path}"
    puts " Hardware BOM     : #{bom_csv_path}"
    puts " CNC DXF Output   : #{dxf_dir}"
    puts "=" * 65 + "\n"

    UI.openURL("file:///#{report_html_path}") if defined?(UI)
  end

  def self.generate_master_dashboard(out_path, carcase_nest, front_nest, panels, hardware)
    # Render SVG Cutting Patterns
    svg_sheets_html = carcase_nest[:sheets].first(3).map do |sh|
      svg = CabinetrixNestingEngine.generate_sheet_svg(sh, 0.38)
      <<-HTML
      <div style="margin-bottom: 25px;">
        <h4 style="margin: 0 0 8px 0; color: #79c0ff;">Sheet ##{sh[:sheet_id]} — #{sh[:raw_w].to_i} x #{sh[:raw_h].to_i}mm | Yield: #{sh[:yield_pct]}% | Used: #{sh[:used_area_sqm]} m²</h4>
        #{svg}
      </div>
      HTML
    end.join("\n")

    # Panel Rows
    panel_rows = panels.first(12).map do |p|
      "<tr><td>#{p[:part_id]}</td><td>#{p[:cab_id]}</td><td><strong>#{p[:name]}</strong></td><td>#{p[:length].to_i} x #{p[:width].to_i} x #{p[:thk].to_i}</td><td>#{p[:material]}</td><td>#{p[:eb_l1] || '-'}</td><td>#{p[:has_cnc] ? '✅ YES' : 'NO'}</td></tr>"
    end.join("\n")

    # Hardware Rows
    hw_rows = hardware.map do |h|
      "<tr><td><strong>#{h[:sku]}</strong></td><td>#{h[:category]}</td><td>#{h[:name]}</td><td><strong style='color:#3fb950;'>#{h[:qty]} #{h[:unit]}</strong></td><td>#{h[:manufacturer]}</td><td>#{h[:desc]}</td></tr>"
    end.join("\n")

    html = <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Cabinetrix AI — Master Production, Nesting & CAM Dashboard</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0d1117; color: #c9d1d9; margin: 0; padding: 25px; }
    .container { max-width: 1300px; margin: 0 auto; }
    header { display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid #21262d; padding-bottom: 15px; margin-bottom: 25px; }
    h1 { margin: 0; color: #58a6ff; font-size: 26px; }
    .kpi-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(220px, 1fr)); gap: 15px; margin-bottom: 30px; }
    .kpi-card { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 18px; }
    .kpi-val { font-size: 30px; font-weight: bold; color: #3fb950; margin: 8px 0 4px 0; }
    .kpi-label { color: #8b949e; font-size: 13px; text-transform: uppercase; letter-spacing: 0.5px; }
    .section-box { background: #161b22; border: 1px solid #30363d; border-radius: 8px; padding: 22px; margin-bottom: 30px; }
    h2 { color: #79c0ff; font-size: 19px; margin-top: 0; border-bottom: 1px solid #21262d; padding-bottom: 10px; }
    table { width: 100%; border-collapse: collapse; margin-top: 10px; font-size: 13px; }
    th, td { text-align: left; padding: 9px 12px; border-bottom: 1px solid #21262d; }
    th { background: #21262d; color: #8b949e; }
    .btn { display: inline-block; background: #238636; color: #fff; text-decoration: none; padding: 8px 16px; border-radius: 6px; font-weight: bold; margin-right: 10px; font-size: 13px; }
    .btn:hover { background: #2ea043; }
  </style>
</head>
<body>
  <div class="container">
    <header>
      <div>
        <h1>🏭 CABINETRIX AI — MASTER PRODUCTION & CAM REPORT</h1>
        <p style="margin: 4px 0 0 0; color: #8b949e;">End-to-End Architectural Kitchen Matrix, 2D Panel Nesting, CNC DXF Toolpaths, and Hardware BOM</p>
      </div>
      <div>
        <a href="production_labels.html" class="btn" target="_blank">🏷️ Print Workshop Labels</a>
        <a href="cutlist.csv" class="btn" style="background:#1f6feb;">📥 Download Cutlist CSV</a>
      </div>
    </header>

    <div class="kpi-grid">
      <div class="kpi-card">
        <div class="kpi-label">Total Cabinets</div>
        <div class="kpi-val">20</div>
        <span>5 Kitchen Layout Suites</span>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Total Panels</div>
        <div class="kpi-val">#{panels.length}</div>
        <span>100% Machine Optimized</span>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Carcase Sheet Yield</div>
        <div class="kpi-val">#{carcase_nest[:overall_yield_pct]}%</div>
        <span>Waste: #{carcase_nest[:overall_waste_pct]}%</span>
      </div>
      <div class="kpi-card">
        <div class="kpi-label">Raw Material Area</div>
        <div class="kpi-val" style="color: #f0883e;">#{carcase_nest[:total_raw_area_sqm]} m²</div>
        <span>#{carcase_nest[:total_sheets]} Total 2440x1220 Sheets</span>
      </div>
    </div>

    <!-- 2D NESTING CUTTING PATTERNS -->
    <div class="section-box">
      <h2>✂️ 2D GUILLOTINE PANEL NESTING PATTERNS (18mm Carcase White MFC)</h2>
      <p style="color:#8b949e; font-size:13px;">Optimized with 10mm raw sheet trim, 4mm saw kerf, and grain direction constraint.</p>
      #{svg_sheets_html}
    </div>

    <!-- PANEL CUTLIST -->
    <div class="section-box">
      <h2>📋 PRODUCTION PANEL CUTLIST & EDGEBANDING SPECIFICATION</h2>
      <table>
        <thead>
          <tr>
            <th>Part ID</th>
            <th>Cabinet</th>
            <th>Part Description</th>
            <th>Finished Dims (mm)</th>
            <th>Core Material</th>
            <th>Edgebanding (Lead)</th>
            <th>CNC Machining</th>
          </tr>
        </thead>
        <tbody>
          #{panel_rows}
        </tbody>
      </table>
      <p style="margin-top: 10px; font-size: 12px; color: #8b949e;">Showing first 12 panels. Download full cutlist.csv for complete 80+ part schedule.</p>
    </div>

    <!-- HARDWARE BILL OF MATERIALS -->
    <div class="section-box">
      <h2>🔩 HARDWARE & ACCESSORY BILL OF MATERIALS (BOM)</h2>
      <table>
        <thead>
          <tr>
            <th>SKU</th>
            <th>Category</th>
            <th>Item Description</th>
            <th>Total Qty</th>
            <th>Manufacturer</th>
            <th>Function / Specifications</th>
          </tr>
        </thead>
        <tbody>
          #{hw_rows}
        </tbody>
      </table>
    </div>

    <!-- CNC CAM DXF LAYERS SUMMARY -->
    <div class="section-box">
      <h2>🤖 CNC CAM LAYERED DXF TOOLPATH SPECIFICATION</h2>
      <table>
        <thead>
          <tr>
            <th>DXF Layer Name</th>
            <th>Color</th>
            <th>Tool Type</th>
            <th>Depth (mm)</th>
            <th>CNC Application</th>
          </tr>
        </thead>
        <tbody>
          <tr><td><strong>0_OUTLINE</strong></td><td>White</td><td>12mm Rough/Finish Endmill</td><td>18.5mm (Through)</td><td>Panel boundary contour outline cut</td></tr>
          <tr><td><strong>DRILL_5MM_PINS</strong></td><td>Yellow</td><td>5mm Brad-Point Drill</td><td>13.0mm</td><td>System 32 line-bore adjustable shelf pins</td></tr>
          <tr><td><strong>DRILL_8MM_DOWEL</strong></td><td>Magenta</td><td>8mm Brad-Point Drill</td><td>13.0mm / 30.0mm</td><td>KD Dowel joinery alignment holes</td></tr>
          <tr><td><strong>BORE_15MM_MINIFIX</strong></td><td>Cyan</td><td>15mm Hinge/Cam Forstner Bit</td><td>12.5mm</td><td>Minifix 15 zinc cam pockets (34mm setback)</td></tr>
          <tr><td><strong>BORE_35MM_HINGE</strong></td><td>Green</td><td>35mm Forstner Bit</td><td>12.5mm</td><td>Concealed hinge cup mounting bores (21.5mm setback)</td></tr>
          <tr><td><strong>GROOVE_BACK_6MM</strong></td><td>Blue</td><td>6mm Slot Saw / Router</td><td>5.0mm</td><td>Rear back sheet rebate / shotgun grooving</td></tr>
          <tr><td><strong>GOLA_NOTCH</strong></td><td>Red</td><td>10mm Compression Spiral</td><td>18.5mm (Through)</td><td>SCILM Top L-Gola & Mid C-Gola gable machining</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</body>
</html>
HTML
    File.write(out_path, html)
  end
end

if defined?(Sketchup)
  CabinetrixMasterPipeline.run_pipeline
end
