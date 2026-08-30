# ==============================================================================
# CABINETRIX AI — 2D PANEL NESTING & CUTTING OPTIMIZATION ENGINE
# File: gemini/cabinetrix_nesting_engine.rb
#
# Production Features:
#   • 2D Guillotine / MaxRects Bin-Packing for Sheet Goods Optimization
#   • Grain Direction Awareness (Grain along Length vs None)
#   • Standard Sheet Sizes (2440x1220mm, 2800x2070mm) with 10mm Trim & 4mm Saw Kerf
#   • Material Grouping (18mm Carcase, 18mm Fronts, 6mm Backs, 15mm Birch Drawers)
#   • Computes Yield %, Waste %, Linear Cut Meterage, and Sheet Count
#   • Interactive SVG & HTML Visual Cutting Diagram Generation
# ==============================================================================

module CabinetrixNestingEngine
  DEFAULT_SHEET_SIZES = {
    carcase_18: { w: 2440.0, h: 1220.0, thk: 18.0, name: "18mm White Moisture Resistant MDF/MFC" },
    front_18:   { w: 2440.0, h: 1220.0, thk: 18.0, name: "18mm Anthracite Supermatte Polyurethane" },
    back_6:     { w: 2440.0, h: 1220.0, thk: 6.0,  name: "6mm White Backing Board" },
    drawer_15:  { w: 2440.0, h: 1220.0, thk: 15.0, name: "15mm Solid Birch Plywood" }
  }

  SHEET_TRIM = 10.0 # 10mm edge trim on all 4 sheet sides
  SAW_KERF   = 4.0  # 4mm CNC router / saw blade width

  # ----------------------------------------------------------------------------
  # 1. 2D BIN PACKING ALGORITHM (MAXRECTS GUILLOTINE HEURISTIC)
  # ----------------------------------------------------------------------------
  def self.nest_panels(parts, sheet_w = 2440.0, sheet_h = 1220.0, trim = SHEET_TRIM, kerf = SAW_KERF)
    usable_w = sheet_w - (2 * trim)
    usable_h = sheet_h - (2 * trim)

    # Sort parts by max dimension descending (Best Fit Decreasing)
    sorted_parts = parts.sort_by { |p| -([p[:length], p[:width]].max * [p[:length], p[:width]].min) }

    sheets = []
    
    sorted_parts.each do |part|
      placed = false
      p_len = part[:length].to_f
      p_wid = part[:width].to_f
      grain_locked = (part[:grain] == :length || part[:grain] == "length")

      # Try to fit into existing sheets
      sheets.each do |sheet|
        sheet[:free_rects].each_with_index do |rect, r_idx|
          # Orientation 1: Normal
          if p_len <= rect[:w] && p_wid <= rect[:h]
            sheet[:placed_parts] << part.merge(
              x: rect[:x], y: rect[:y],
              placed_w: p_len, placed_h: p_wid,
              rotated: false
            )
            split_free_rect(sheet[:free_rects], r_idx, rect, p_len, p_wid, kerf)
            placed = true
            break
          # Orientation 2: Rotated 90° (if grain allows)
          elsif !grain_locked && p_wid <= rect[:w] && p_len <= rect[:h]
            sheet[:placed_parts] << part.merge(
              x: rect[:x], y: rect[:y],
              placed_w: p_wid, placed_h: p_len,
              rotated: true
            )
            split_free_rect(sheet[:free_rects], r_idx, rect, p_wid, p_len, kerf)
            placed = true
            break
          end
        end
        break if placed
      end

      # Open a new sheet if part did not fit
      unless placed
        new_sheet = {
          sheet_id: sheets.length + 1,
          raw_w: sheet_w, raw_h: sheet_h,
          usable_w: usable_w, usable_h: usable_h,
          trim: trim,
          placed_parts: [],
          free_rects: [{ x: trim, y: trim, w: usable_w, h: usable_h }]
        }

        # Place part in bottom-left of new sheet
        rect = new_sheet[:free_rects][0]
        if p_len <= rect[:w] && p_wid <= rect[:h]
          new_sheet[:placed_parts] << part.merge(
            x: rect[:x], y: rect[:y],
            placed_w: p_len, placed_h: p_wid,
            rotated: false
          )
          split_free_rect(new_sheet[:free_rects], 0, rect, p_len, p_wid, kerf)
        elsif !grain_locked && p_wid <= rect[:w] && p_len <= rect[:h]
          new_sheet[:placed_parts] << part.merge(
            x: rect[:x], y: rect[:y],
            placed_w: p_wid, placed_h: p_len,
            rotated: true
          )
          split_free_rect(new_sheet[:free_rects], 0, rect, p_wid, p_len, kerf)
        else
          # Oversized part warning
          new_sheet[:placed_parts] << part.merge(
            x: rect[:x], y: rect[:y],
            placed_w: p_len, placed_h: p_wid,
            rotated: false, error: "OVERSIZED"
          )
        end

        sheets << new_sheet
      end
    end

    # Calculate Yield & Waste Stats
    total_raw_area = sheets.length * (sheet_w * sheet_h)
    total_used_area = 0.0
    total_cut_meters = 0.0

    sheets.each do |sh|
      sh_used_area = 0.0
      sh[:placed_parts].each do |p|
        p_area = p[:placed_w] * p[:placed_h]
        sh_used_area += p_area
        total_cut_meters += ((2 * p[:placed_w]) + (2 * p[:placed_h])) / 1000.0
      end
      sh[:used_area_sqm] = (sh_used_area / 1_000_000.0).round(3)
      sh[:raw_area_sqm] = (sheet_w * sheet_h / 1_000_000.0).round(3)
      sh[:yield_pct] = ((sh_used_area / (sheet_w * sheet_h)) * 100.0).round(1)
      total_used_area += sh_used_area
    end

    overall_yield = total_raw_area > 0 ? ((total_used_area / total_raw_area) * 100.0).round(1) : 0.0
    overall_waste = (100.0 - overall_yield).round(1)

    {
      sheets: sheets,
      total_sheets: sheets.length,
      total_parts: parts.length,
      total_raw_area_sqm: (total_raw_area / 1_000_000.0).round(2),
      total_used_area_sqm: (total_used_area / 1_000_000.0).round(2),
      total_waste_area_sqm: ((total_raw_area - total_used_area) / 1_000_000.0).round(2),
      overall_yield_pct: overall_yield,
      overall_waste_pct: overall_waste,
      total_cut_meters: total_cut_meters.round(1)
    }
  end

  def self.split_free_rect(free_rects, idx, rect, pw, ph, kerf)
    free_rects.delete_at(idx)
    
    # Right remainder
    rem_right_w = rect[:w] - pw - kerf
    if rem_right_w > 50.0
      free_rects << {
        x: rect[:x] + pw + kerf,
        y: rect[:y],
        w: rem_right_w,
        h: ph
      }
    end

    # Top remainder
    rem_top_h = rect[:h] - ph - kerf
    if rem_top_h > 50.0
      free_rects << {
        x: rect[:x],
        y: rect[:y] + ph + kerf,
        w: rect[:w],
        h: rem_top_h
      }
    end
  end

  # ----------------------------------------------------------------------------
  # 2. SVG CUTTING PATTERN GENERATOR
  # ----------------------------------------------------------------------------
  def self.generate_sheet_svg(sheet, scale = 0.35)
    svg_w = sheet[:raw_w] * scale
    svg_h = sheet[:raw_h] * scale

    svg = []
    svg << "<svg width='#{svg_w.round}' height='#{svg_h.round}' viewBox='0 0 #{sheet[:raw_w]} #{sheet[:raw_h]}' xmlns='http://www.w3.org/2000/svg' style='background:#1e222b;border:2px solid #444c56;border-radius:6px;margin:10px 0;'>"
    
    # Sheet Trim Boundary
    svg << "  <rect x='#{sheet[:trim]}' y='#{sheet[:trim]}' width='#{sheet[:usable_w]}' height='#{sheet[:usable_h]}' fill='#161b22' stroke='#30363d' stroke-dasharray='8 4' stroke-width='2'/>"

    # Placed Panels
    colors = ['#388bfd', '#2ea043', '#e3b341', '#f0883e', '#a371f7', '#db61a2', '#58a6ff', '#56d364']
    sheet[:placed_parts].each_with_index do |p, i|
      c = colors[i % colors.length]
      svg << "  <g>"
      svg << "    <rect x='#{p[:x]}' y='#{p[:y]}' width='#{p[:placed_w]}' height='#{p[:placed_h]}' fill='#{c}' fill-opacity='0.25' stroke='#{c}' stroke-width='2'/>"
      svg << "    <text x='#{p[:x] + 10}' y='#{p[:y] + 25}' fill='#f0f3f6' font-size='22' font-weight='bold' font-family='sans-serif'>#{p[:name]}</text>"
      svg << "    <text x='#{p[:x] + 10}' y='#{p[:y] + 52}' fill='#8b949e' font-size='18' font-family='sans-serif'>#{p[:placed_w].to_i} x #{p[:placed_h].to_i}mm | #{p[:cab_id]}</text>"
      if p[:eb_code]
        svg << "    <text x='#{p[:x] + 10}' y='#{p[:y] + 76}' fill='#e3b341' font-size='15' font-family='sans-serif'>EB: #{p[:eb_code]}</text>"
      end
      svg << "  </g>"
    end

    svg << "</svg>"
    svg.join("\n")
  end
end
