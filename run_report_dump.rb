# =============================================================================
# Cabinex AI — Model Data Report Dump (reporting loop)
# (c) 2026 Cabinex AI. All Rights Reserved.
#
# Scrapes the REAL current SketchUp model: every group's role + CBX attributes
# + actual bounding-box dims, folds them into a BOM-style part list, and writes
# two files so you can paste them back to the engineer:
#   cabinex_model_report.json   - machine-readable
#   cabinex_model_report.txt    - human summary
#
# USAGE (SketchUp Ruby console):
#   load "C:/Users/asank/Documents/CabinexAi/run_report_dump.rb"
#   RunReportDump.dump
# =============================================================================

require 'sketchup.rb'
require 'json'

module RunReportDump
  OUT_JSON = File.expand_path('cabinex_model_report.json', __dir__)
  OUT_TXT = File.expand_path('cabinex_model_report.txt', __dir__)
  MAX_DEPTH = 6

  def self.dump
    model = Sketchup.active_model
    raise 'No active model.' unless model

    groups = []
    collect(model.active_entities, groups, 0)

    parts = groups.map { |g| part_record(g) }.compact

    # BOM-style rollups for rapid review
    rollup = {
      total_groups: parts.length,
      by_role: tally(parts, :role),
      by_material: tally(parts, :material_name),
      by_cabinet_type: tally(groups_attrs(parts), :cabinet_type),
      total_board_sqm: parts.select { |p| p[:thickness_mm].to_f > 12.0 }.sum { |p| (p[:len_mm] * p[:wid_mm]) / 1_000_000.0 }.round(2),
      total_alu_bars_mm: parts.select { |p| (p[:role] || '').match?(/Sash|Bar|Rail|Rod|Track|Gola|Plinth/) }.sum { |p| p[:len_mm].to_f }.round(0)
    }

    # INTENDED vs ACTUAL for sliding/mirror wardrobe fronts + rods + tracks.
    intended_vs_actual = compare_intent(parts)

    report = {
      generated: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      model_name: model.title,
      group_count: parts.length,
      rollup: rollup,
      intended_vs_actual: intended_vs_actual,
      parts: parts
    }

    File.write(OUT_JSON, JSON.pretty_generate(report))
    write_txt(report)

    puts ">> Model report written:"
    puts "   #{OUT_JSON}"
    puts "   #{OUT_TXT}"
    puts "   Groups: #{parts.length}  Board sqm: #{rollup[:total_board_sqm]}  Alu bars mm: #{rollup[:total_alu_bars_mm]}"
    puts "   By material: #{rollup[:by_material].inspect}"
    puts "   By cabinet: #{rollup[:by_cabinet_type].inspect}"
    if intended_vs_actual[:mismatches].empty?
      puts "   INTENT vs ACTUAL: <all matching>"
    else
      puts "   INTENT vs ACTUAL MISMATCHES: #{intended_vs_actual[:mismatches].length}"
      intended_vs_actual[:mismatches].each do |m|
        puts "     - #{m[:group]}: intended #{m[:intended]} / actual #{m[:actual]} (#{m[:field]})"
      end
    end
  end

  def self.part_record(g)
    attrs = g[:attrs]
    role = g[:name].to_s
    b = g[:bounds]
    dims = [b[:width], b[:depth], b[:height]].map { |v| v.round(1) }.sort.reverse
    len = (attrs['length_mm'] || dims[0]).round(1)
    wid = (attrs['width_mm'] || (dims[1] || dims[0])).round(1)
    thk = (attrs['thickness_mm'] || (dims[2] || 0.0)).round(1)

    {
      role: role,
      material_name: g[:material],
      len_mm: len,
      wid_mm: wid,
      thk_mm: thk,
      bbox_mm: "#{dims[0]}x#{dims[1]}x#{dims[2]}",
      depth: g[:depth],
      owner: g[:owner],
      cabinet_type: attrs['cabinet_type'],
      front_system: attrs['front_system'],
      sliding_leaves: attrs['sliding_leaves'],
      closet_rods: attrs['closet_rods'],
      drawers: attrs['drawers'],
      shelves: attrs['shelves'],
      mirror_infill_intended: attrs['mirror_infill'],
      connector_hint: attrs['side_panel_type'] || attrs['base_support'] || attrs['shared_floor_frame']
    }
  end

  def self.collect(ents, out, depth, parent_role = nil)
    return if depth > MAX_DEPTH
    ents.each do |e|
      next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
      next if e.name.to_s.empty?
      attrs = {}
      begin
        e.attribute_dictionary('CBX')&.each_pair { |k, v| attrs[k] = v }
      rescue
        attrs = {}
      end
      mat = begin
        m = e.material
        m ? m.name : nil
      rescue
        nil
      end
      bounds = e.bounds
      this_role = attrs['role'] || e.name.to_s
      owner = attrs['owner_role'] || parent_role
      out << {
        name: e.name,
        material: mat,
        attrs: attrs,
        depth: depth,
        owner: owner,
        bounds: {
          width: bounds.width.to_mm,
          depth: bounds.depth.to_mm,
          height: bounds.height.to_mm
        }
      }
      # A tagged cabinet (has cabinet_type) becomes the owner of its subtree.
      child_parent = attrs['cabinet_type'] ? this_role : parent_role
      collect(e.entities, out, depth + 1, child_parent)
    end
  end

  def self.groups_attrs(parts)
    parts
  end

  # For every group tagged cabinet_type=WARDROBE, compare the INTENDED front
  # config (sliding_leaves, mirror_infill, closet_rods attrs) against the ACTUAL
  # geometry tags beneath it (Slide_Leaf / Mirror / Closet_Rod groups).
  def self.compare_intent(parts)
    wardrobe_roots = parts.select { |p| p[:cabinet_type] == 'WARDROBE' }
    rows = []
    mismatches = []

    wardrobe_roots.each do |root|
      prefix = root[:role].to_s
      intended_leaves = root[:sliding_leaves].to_i
      intended_mirror = root[:mirror_infill_intended] == true ? 1 : 0
      intended_rods = root[:closet_rods].to_i

      # Actual geometry under this wardrobe root: match children whose role name
      # is prefixed with the root's own role name.
      anchor = root[:role].to_s
      children = parts.select { |p| p[:owner] == anchor }
      actual_leaves = children.count { |p| p[:role].to_s.include?('Slide_Leaf') }
      actual_mirror = children.count { |p| p[:role].to_s.include?('Mirror') }
      actual_rods = children.count { |p| p[:role].to_s.match?(/Closet_Rod|Hanging_Rail/) }

      row = {
        group: root[:role].to_s,
        front_system: root[:front_system],
        sliding_leaves: { intended: intended_leaves, actual: actual_leaves },
        mirror: { intended: intended_mirror, actual: actual_mirror },
        closet_rods: { intended: intended_rods, actual: actual_rods }
      }
      rows << row

      mismatches << { group: prefix, field: 'sliding_leaves', intended: intended_leaves, actual: actual_leaves } if intended_leaves > 0 && actual_leaves != intended_leaves
      mismatches << { group: prefix, field: 'mirror', intended: intended_mirror, actual: actual_mirror } if intended_mirror > 0 && actual_mirror != intended_mirror
      mismatches << { group: prefix, field: 'closet_rods', intended: intended_rods, actual: actual_rods } if intended_rods > 0 && actual_rods != intended_rods
    end

    { wardrobes: rows, mismatches: mismatches }
  end

  def self.tally(parts, key)
    parts.group_by { |p| (p[key] || '~').to_s }.transform_values(&:length)
  end

  def self.write_txt(report)
    lines = []
    lines << "CABINEX MODEL REPORT  #{report[:generated]}"
    lines << "Model: #{report[:model_name]}   Groups: #{report[:group_count]}"
    lines << "Board sqm: #{report[:rollup][:total_board_sqm]}   Alu bars mm: #{report[:rollup][:total_alu_bars_mm]}"
    lines << "By material: #{report[:rollup][:by_material].inspect}"
    lines << "By cabinet: #{report[:rollup][:by_cabinet_type].inspect}"
    lines << ""
    lines << "INTENDED vs ACTUAL (wardrobe fronts / sliding leaves / mirror / rods)"
    lines << "-" * 80
    if report[:intended_vs_actual][:wardrobes].empty?
      lines << "  (no wardrobe roots found)"
    else
      report[:intended_vs_actual][:wardrobes].each do |w|
        lines << format('  %-34s leanes %d/%d  mirror %d/%d  rods %d/%d',
                        w[:group][0, 34], w[:sliding_leaves][:actual], w[:sliding_leaves][:intended],
                        w[:mirror][:actual], w[:mirror][:intended],
                        w[:closet_rods][:actual], w[:closet_rods][:intended])
      end
    end
    unless report[:intended_vs_actual][:mismatches].empty?
      lines << ""
      lines << "MISMATCHES: intended != actual"
      report[:intended_vs_actual][:mismatches].each do |m|
        lines << format('  - %-30s %-14s intended=%s actual=%s', m[:group][0, 30], m[:field], m[:intended], m[:actual])
      end
    end
    lines << ""
    lines << "ROLE / MATERIAL / DIMS (len x wid x thk) / cabinet / front"
    lines << "-" * 80
    report[:parts].each do |p|
      lines << format('%-34s %-22s %9s  cab=%-12s front=%-14s',
                       p[:role][0, 34], p[:material_name].to_s[0, 22],
                       "#{p[:len_mm]}x#{p[:wid_mm]}x#{p[:thk_mm]}",
                       p[:cabinet_type].to_s, p[:front_system].to_s)
    end
    File.write(OUT_TXT, lines.join("\n"))
  end
end
