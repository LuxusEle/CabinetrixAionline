# ==============================================================================
# CABINETRIX AI — 2D PANEL NESTING & MACHINING VISUALIZER ENGINE
# File: gemini/cabinetrix_nesting_engine.rb
#
# Production Standard:
#   • 2D Guillotine / MaxRects Bin-Packing Optimization
#   • Visual CNC Machining Operations Overlay on Every Nested Panel:
#     - 🟡 Yellow Circles (Ø 5mm System 32 shelf pin holes)
#     - 🟣 Magenta Circles (Ø 8mm Dowel joinery holes)
#     - 🔵 Cyan Circles (Ø 15mm Minifix 15 cam pockets, 34mm setback)
#     - 🟢 Green Circles (Ø 35mm Concealed hinge cup pockets)
#     - 🟦 Dashed Blue Lines (6mm Backing sheet slot groove)
#     - 🟥 Red Notches (SCILM Top L-Gola & Mid C-Gola gable CNC cutouts)
#   • Full Multi-Sheet Interactive SVG Gallery for All Raw Boards
# ==============================================================================

module CabinetrixNestingEngine
  DEFAULT_SHEET_SIZES = {
    carcase_18: { w: 2440.0, h: 1220.0, thk: 18.0, name: "18mm White Moisture Resistant Carcase MFC" },
    front_18:   { w: 2440.0, h: 1220.0, thk: 18.0, name: "18mm Anthracite Supermatte Face Poly" },
    back_6:     { w: 2440.0, h: 1220.0, thk: 6.0,  name: "6mm White Grooved Backing Board" }
  }

  SHEET_TRIM = 10.0 # 10mm edge trim on all 4 sheet sides
  SAW_KERF   = 4.0  # 4mm CNC router saw blade width

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
          new_sheet[:placed_parts] << part.merge(
            x: rect[:x], y: rect[:y],
            placed_w: p_len, placed_h: p_wid,
            rotated: false, error: "OVERSIZED"
          )
        end

        sheets << new_sheet
      end
    end

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
    rem_right_w = rect[:w] - pw - kerf
    if rem_right_w > 50.0
      free_rects << { x: rect[:x] + pw + kerf, y: rect[:y], w: rem_right_w, h: ph }
    end
    rem_top_h = rect[:h] - ph - kerf
    if rem_top_h > 50.0
      free_rects << { x: rect[:x], y: rect[:y] + ph + kerf, w: rect[:w], h: rem_top_h }
    end
  end

  # ----------------------------------------------------------------------------
  # 2. SVG CUTTING PATTERN GENERATOR (WITH DETAILED CNC DRILL & CUT OVERLAYS)
  # ----------------------------------------------------------------------------
  def self.generate_sheet_svg(sheet, scale = 0.35)
    svg_w = sheet[:raw_w] * scale
    svg_h = sheet[:raw_h] * scale

    svg = []
    svg << "<svg width='#{svg_w.round}' height='#{svg_h.round}' viewBox='0 0 #{sheet[:raw_w]} #{sheet[:raw_h]}' xmlns='http://www.w3.org/2000/svg' style='background:#14171f;border:2px solid #30363d;border-radius:6px;margin:8px 0;'>"
    
    # Sheet Trim Line
    svg << "  <rect x='#{sheet[:trim]}' y='#{sheet[:trim]}' width='#{sheet[:usable_w]}' height='#{sheet[:usable_h]}' fill='#161b22' stroke='#484f58' stroke-dasharray='8 4' stroke-width='2'/>"

    # Placed Panels
    colors = ['#1f6feb', '#238636', '#d29922', '#8957e5', '#db61a2', '#388bfd', '#2ea043', '#f0883e']
    sheet[:placed_parts].each_with_index do |p, i|
      c = colors[i % colors.length]
      px, py, pw, ph = p[:x], p[:y], p[:placed_w], p[:placed_h]

      svg << "  <g id='part_#{p[:part_id]}'>"
      svg << "    <rect x='#{px}' y='#{py}' width='#{pw}' height='#{ph}' fill='#{c}' fill-opacity='0.22' stroke='#{c}' stroke-width='2.5'/>"

      # Part Text Label
      svg << "    <text x='#{px + 12}' y='#{py + 26}' fill='#f0f6fc' font-size='22' font-weight='bold' font-family='monospace'>#{p[:name]}</text>"
      svg << "    <text x='#{px + 12}' y='#{py + 52}' fill='#8b949e' font-size='17' font-family='sans-serif'>#{pw.to_i} x #{ph.to_i}mm | #{p[:cab_id]}</text>"
      if p[:eb_l1]
        svg << "    <text x='#{px + 12}' y='#{py + 76}' fill='#e3b341' font-size='14' font-family='sans-serif'>EB: #{p[:eb_l1]}</text>"
      end

      # ========================================================================
      # VISUAL CNC DRILL & CUT MACHINING OVERLAYS
      # ========================================================================
      # 1. SCILM Gola Notches (if Gable)
      if p[:name].include?('Gable') && (p[:has_gola_notch] || p[:has_cnc])
        # Top L-Gola Notch (59mm x 26mm)
        svg << "    <rect x='#{px + pw - 59}' y='#{py + ph - 26}' width='59' height='26' fill='#f85149' fill-opacity='0.6' stroke='#da3633' stroke-width='2'/>"
        svg << "    <text x='#{px + pw - 55}' y='#{py + ph - 8}' fill='#fff' font-size='12' font-weight='bold'>L-GOLA</text>"

        # Mid C-Gola Notch (73.5mm x 26mm at Z=330)
        if pw >= 600
          svg << "    <rect x='#{px + 330}' y='#{py + ph - 26}' width='73.5' height='26' fill='#f85149' fill-opacity='0.6' stroke='#da3633' stroke-width='2'/>"
          svg << "    <text x='#{px + 335}' y='#{py + ph - 8}' fill='#fff' font-size='12' font-weight='bold'>C-GOLA</text>"
        end
      end

      # 2. Rear Back Panel Slot Groove (Blue Dashed Line)
      if p[:name].include?('Gable') || p[:has_back_groove]
        svg << "    <line x1='#{px}' y1='#{py + 25}' x2='#{px + pw}' y2='#{py + 25}' stroke='#58a6ff' stroke-width='4' stroke-dasharray='10 5' />"
        svg << "    <text x='#{px + pw/2 - 40}' y='#{py + 20}' fill='#58a6ff' font-size='12'>6mm BACK GROOVE</text>"
      end

      # 3. System 32 Line-Bore Shelf Pins (Yellow Circles Ø 5mm)
      if p[:name].include?('Gable') || p[:shelf_pin_holes]
        [0.3, 0.5, 0.7].each do |ratio|
          hx1, hy1 = px + (pw * ratio), py + 50
          hx2, hy2 = px + (pw * ratio), py + ph - 50
          svg << "    <circle cx='#{hx1}' cy='#{hy1}' r='7' fill='#e3b341' stroke='#ffd33d' stroke-width='1.5'/>"
          svg << "    <circle cx='#{hx2}' cy='#{hy2}' r='7' fill='#e3b341' stroke='#ffd33d' stroke-width='1.5'/>"
        end
      end

      # 4. Minifix 15 Cam Pockets (Cyan Circles Ø 15mm) & Dowels (Magenta Circles Ø 8mm)
      if p[:name].include?('Bottom') || p[:name].include?('Roof') || p[:name].include?('Stretcher')
        # Minifix Cam Bores (34mm setback)
        [[px + 34, py + 40], [px + 34, py + ph - 40], [px + pw - 34, py + 40], [px + pw - 34, py + ph - 40]].each do |cx, cy|
          svg << "    <circle cx='#{cx}' cy='#{cy}' r='12' fill='#79c0ff' fill-opacity='0.6' stroke='#388bfd' stroke-width='2'/>"
          svg << "    <circle cx='#{cx}' cy='#{cy}' r='3' fill='#fff'/>"
        end
        # Dowels (32mm from Minifix)
        [[px + 10, py + 72], [px + 10, py + ph - 72], [px + pw - 10, py + 72], [px + pw - 10, py + ph - 72]].each do |dx, dy|
          svg << "    <circle cx='#{dx}' cy='#{dy}' r='7' fill='#d2a8ff' stroke='#a371f7' stroke-width='1.5'/>"
        end
      end

      # 5. Concealed 35mm Hinge Cup Bores (Green Circles Ø 35mm)
      if p[:name].include?('Door')
        [[px + 22, py + 100], [px + 22, py + ph - 100]].each do |hx, hy|
          svg << "    <circle cx='#{hx}' cy='#{hy}' r='18' fill='#56d364' fill-opacity='0.6' stroke='#2ea043' stroke-width='2.5'/>"
          svg << "    <text x='#{hx + 24}' y='#{hy + 5}' fill='#56d364' font-size='12' font-weight='bold'>35mm HINGE</text>"
        end
      end

      svg << "  </g>"
    end

    svg << "</svg>"
    svg.join("\n")
  end
end
