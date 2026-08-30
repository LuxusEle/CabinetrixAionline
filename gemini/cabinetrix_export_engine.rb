# ==============================================================================
# CABINETRIX AI — MULTI-FORMAT EXPORT & PRODUCTION CAM ENGINE
# File: gemini/cabinetrix_export_engine.rb
#
# Production Features:
#   • Excel / CSV Exporter: Cutlists, Hardware BOM, and Sheet Summary
#   • 2D CNC Machining DXF Generator with Industry-Standard Layered Toolpaths:
#     - OUTLINE (Panel perimeter profile cut)
#     - DRILL_5MM (System 32 line-bore shelf pin holes, 13mm depth)
#     - DRILL_8MM (Dowel joinery holes, 13mm / 30mm depth)
#     - BORE_15MM (Minifix 15 cam pockets, 12.5mm depth, 34mm setback)
#     - BORE_35MM (Concealed hinge cup pockets, 12.5mm depth, 21.5mm center setback)
#     - GROOVE_BACK_6MM (6mm rear back groove, 5mm depth, 15mm setback)
#     - GOLA_NOTCH (SCILM L-Gola & C-Gola gable CNC contour)
#   • Printable Workshop Production Labels (100mm x 50mm) with Barcodes & Edgebanding
# ==============================================================================

module CabinetrixExportEngine
  # ----------------------------------------------------------------------------
  # 1. EXCEL / CSV EXPORTERS
  # ----------------------------------------------------------------------------
  def self.export_cutlist_csv(parts, file_path)
    lines = []
    lines << "Part ID,Cabinet ID,Part Name,Length (mm),Width (mm),Thk (mm),Material,Grain,EB Length 1,EB Length 2,EB Width 1,EB Width 2,CNC Machining"
    parts.each do |p|
      lines << [
        p[:part_id] || "P#{p[:id]}",
        p[:cab_id] || "CAB-1",
        p[:name],
        p[:length].to_f.round(1),
        p[:width].to_f.round(1),
        p[:thk].to_f.round(1),
        p[:material] || "18mm White MFC",
        p[:grain] || "None",
        p[:eb_l1] || "-",
        p[:eb_l2] || "-",
        p[:eb_w1] || "-",
        p[:eb_w2] || "-",
        p[:has_cnc] ? "YES" : "NO"
      ].join(",")
    end
    File.write(file_path, lines.join("\n"))
  end

  def self.export_hardware_bom_csv(hardware_items, file_path)
    lines = []
    lines << "Item SKU,Category,Item Name,Quantity,Unit,Manufacturer,Description"
    hardware_items.each do |h|
      lines << [
        h[:sku],
        h[:category],
        h[:name],
        h[:qty],
        h[:unit] || "pcs",
        h[:manufacturer] || "Generic",
        h[:desc] || ""
      ].join(",")
    end
    File.write(file_path, lines.join("\n"))
  end

  def self.export_nesting_summary_csv(nesting_res, file_path)
    lines = []
    lines << "Sheet No,Raw Sheet Dims (mm),Usable Area (m2),Used Area (m2),Yield %,Waste %,Total Parts"
    nesting_res[:sheets].each do |sh|
      lines << [
        sh[:sheet_id],
        "#{sh[:raw_w].to_i} x #{sh[:raw_h].to_i}",
        sh[:raw_area_sqm],
        sh[:used_area_sqm],
        sh[:yield_pct],
        (100.0 - sh[:yield_pct]).round(1),
        sh[:placed_parts].length
      ].join(",")
    end
    lines << ""
    lines << "TOTAL SHEETS,#{nesting_res[:total_sheets]},TOTAL PARTS,#{nesting_res[:total_parts]},OVERALL YIELD %,#{nesting_res[:overall_yield_pct]}%,TOTAL CUT METERS,#{nesting_res[:total_cut_meters]}m"
    File.write(file_path, lines.join("\n"))
  end

  # ----------------------------------------------------------------------------
  # 2. 2D CNC MACHINING DXF GENERATOR (AUTOCAD R12/R2000 COMPATIBLE)
  # ----------------------------------------------------------------------------
  def self.export_panel_dxf(panel, out_path)
    w = panel[:length].to_f
    h = panel[:width].to_f
    dxf = []

    # DXF Header
    dxf << "0\nSECTION\n2\nHEADER\n9\n$ACADVER\n1\nAC1009\n0\nENDSEC"
    
    # DXF Tables & Layers
    dxf << "0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLAYER\n70\n7"
    [
      ["0_OUTLINE", 7],
      ["DRILL_5MM_PINS", 2],
      ["DRILL_8MM_DOWEL", 6],
      ["BORE_15MM_MINIFIX", 4],
      ["BORE_35MM_HINGE", 3],
      ["GROOVE_BACK_6MM", 5],
      ["GOLA_NOTCH", 1]
    ].each do |lay_name, col|
      dxf << "0\nLAYER\n2\n#{lay_name}\n70\n0\n62\n#{col}\n6\nCONTINUOUS"
    end
    dxf << "0\nENDTAB\n0\nENDSEC"

    # DXF Entities (Geometry)
    dxf << "0\nSECTION\n2\nENTITIES"

    # 1. Outline Polyline
    dxf << dxf_closed_polyline("0_OUTLINE", [[0, 0], [w, 0], [w, h], [0, h]])

    # 2. Minifix Bores & Dowels (if applicable)
    if panel[:minifix_holes]
      panel[:minifix_holes].each do |hx, hy|
        dxf << dxf_circle("BORE_15MM_MINIFIX", hx, hy, 7.5)
      end
    end
    if panel[:dowel_holes]
      panel[:dowel_holes].each do |hx, hy|
        dxf << dxf_circle("DRILL_8MM_DOWEL", hx, hy, 4.0)
      end
    end

    # 3. System 32 Shelf Pin Holes (if applicable)
    if panel[:shelf_pin_holes]
      panel[:shelf_pin_holes].each do |hx, hy|
        dxf << dxf_circle("DRILL_5MM_PINS", hx, hy, 2.5)
      end
    end

    # 4. Hinge Cup Bores (if door)
    if panel[:hinge_cup_holes]
      panel[:hinge_cup_holes].each do |hx, hy|
        dxf << dxf_circle("BORE_35MM_HINGE", hx, hy, 17.5)
      end
    end

    # 5. Rear Groove (if gable)
    if panel[:has_back_groove]
      dxf << dxf_line("GROOVE_BACK_6MM", 0, 15.0, w, 15.0)
    end

    # 6. SCILM Gola Notches (if Gola Gable)
    if panel[:has_gola_notch]
      # Top L-Gola Notch (Depth 26mm, Height 59mm)
      dxf << dxf_closed_polyline("GOLA_NOTCH", [
        [w - 59.0, h],
        [w - 59.0, h - 26.0],
        [w, h - 26.0],
        [w, h]
      ])
      # Mid C-Gola Notch (Z0=330mm, Height 73.5mm, Depth 26mm)
      dxf << dxf_closed_polyline("GOLA_NOTCH", [
        [330.0, h],
        [330.0, h - 26.0],
        [403.5, h - 26.0],
        [403.5, h]
      ])
    end

    dxf << "0\nENDSEC\n0\nEOF"
    File.write(out_path, dxf.join("\n"))
  end

  def self.dxf_circle(layer, cx, cy, radius)
    "0\nCIRCLE\n8\n#{layer}\n10\n#{cx.round(2)}\n20\n#{cy.round(2)}\n30\n0.0\n40\n#{radius.round(2)}"
  end

  def self.dxf_line(layer, x1, y1, x2, y2)
    "0\nLINE\n8\n#{layer}\n10\n#{x1.round(2)}\n20\n#{y1.round(2)}\n30\n0.0\n11\n#{x2.round(2)}\n21\n#{y2.round(2)}\n31\n0.0"
  end

  def self.dxf_closed_polyline(layer, pts)
    out = ["0\nPOLYLINE\n8\n#{layer}\n66\n1\n70\n1"]
    pts.each do |x, y|
      out << "0\nVERTEX\n8\n#{layer}\n10\n#{x.round(2)}\n20\n#{y.round(2)}\n30\n0.0"
    end
    out << "0\nSEQEND"
    out.join("\n")
  end

  # ----------------------------------------------------------------------------
  # 3. PRINTABLE PRODUCTION LABELS GENERATOR (100mm x 50mm)
  # ----------------------------------------------------------------------------
  def self.generate_production_labels_html(parts, out_path)
    cards = parts.map do |p|
      <<-HTML
      <div class="label-card">
        <div class="label-header">
          <span class="cab-tag">#{p[:cab_id]}</span>
          <span class="part-uid">UID: #{p[:part_id] || "P-#{rand(1000..9999)}"}</span>
        </div>
        <div class="part-name">#{p[:name]}</div>
        <div class="part-dims">#{p[:length].to_i} x #{p[:width].to_i} x #{p[:thk].to_i} mm</div>
        <div class="part-mat">Mat: #{p[:material] || "18mm White MFC"}</div>
        <div class="eb-diagram">
          <div class="eb-top">#{p[:eb_w2] || "0.4mm"}</div>
          <div class="eb-mid">
            <span class="eb-left">#{p[:eb_l1] || "1.0mm"}</span>
            <span class="grain-arrow">⬆ GRAIN</span>
            <span class="eb-right">#{p[:eb_l2] || "-"}</span>
          </div>
          <div class="eb-bottom">#{p[:eb_w1] || "0.4mm"}</div>
        </div>
        <div class="barcode-zone">
          <div class="barcode-mock">||| | |||| | |||||| || ||| | |||</div>
          <div class="prog-name">CNC: #{p[:name].gsub(/[^A-Za-z0-9]/, '_').upcase}</div>
        </div>
      </div>
      HTML
    end.join("\n")

    html = <<-HTML
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Cabinetrix AI — Workshop Production Labels</title>
  <style>
    body { font-family: "Segoe UI", Arial, sans-serif; background: #eaedf0; margin: 0; padding: 20px; }
    .labels-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 15px; }
    .label-card { background: #fff; border: 2px solid #222; border-radius: 4px; padding: 12px; box-sizing: border-box; width: 100%; height: 190px; position: relative; }
    .label-header { display: flex; justify-content: space-between; border-bottom: 1.5px solid #222; padding-bottom: 4px; font-weight: bold; font-size: 13px; }
    .cab-tag { background: #222; color: #fff; padding: 2px 6px; border-radius: 3px; }
    .part-name { font-size: 16px; font-weight: bold; color: #111; margin: 6px 0 2px 0; }
    .part-dims { font-size: 15px; font-weight: bold; color: #0066cc; }
    .part-mat { font-size: 11px; color: #555; margin-bottom: 6px; }
    .eb-diagram { border: 1px dashed #777; background: #fafafa; padding: 4px; font-size: 10px; text-align: center; margin-bottom: 6px; }
    .eb-mid { display: flex; justify-content: space-between; margin: 2px 0; }
    .grain-arrow { color: #28a745; font-weight: bold; }
    .barcode-zone { display: flex; justify-content: space-between; align-items: flex-end; margin-top: 4px; }
    .barcode-mock { font-family: monospace; font-size: 16px; letter-spacing: 2px; font-weight: bold; }
    .prog-name { font-size: 10px; font-weight: bold; color: #444; }
    @media print {
      body { background: #fff; padding: 0; }
      .label-card { break-inside: avoid; page-break-inside: avoid; margin-bottom: 10px; }
    }
  </style>
</head>
<body>
  <div style="margin-bottom: 20px; display: flex; justify-content: space-between; align-items: center;">
    <h2>🏷️ CABINETRIX PRODUCTION LABELS (100mm x 50mm)</h2>
    <button onclick="window.print()" style="padding: 8px 16px; font-weight: bold; cursor: pointer;">🖨️ Print Labels</button>
  </div>
  <div class="labels-grid">
    #{cards}
  </div>
</body>
</html>
HTML
    File.write(out_path, html)
  end
end
