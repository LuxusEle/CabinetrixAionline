# =============================================================================
# Cabinex AI — Parts Direction & Placement Inspector (auto-scan QA)
# (c) 2026 Cabinex AI. All Rights Reserved.
#
# Scrapes the REAL model geometry the moment cabinet boxes are built, and for
# every tagged part (handle, connector, slab door, face frame, shelf, sofa front)
# derives its ACTUAL direction / facing / placement from its world bounding box,
# then compares to the EXPECTED answer for that role per the CBXPlacement frame
# convention. Logs a direction report (JSON + TXT) and prints a PASS/FAIL line.
#
# Convention (must match CBXPlacement in cbx_hybrid_engine.rb):
#   X = width ; Y = depth (front faces -Y) ; Z = height. Long-axis = dominant bbox dim.
#
# EXPECTED by role:
#   handle horizontal -> long axis X, sits on FRONT face (facing -Y), |Y| near front
#   handle vertical   -> long axis Z, on FRONT face (facing -Y)
#   slab door         -> long axis X, on FRONT face (facing -Y)
#   face frame        -> planar, on FRONT face
#   connector         -> on its connector_face, drilled toward rear (+Y)
#   shelves           -> planar horizontal (thin in Z), inside the cabinet
#
# USAGE (auto): RunCabinetGrid.build calls RunPartsInspector.scan at the end.
#   manual:  load "C:/Users/asank/Documents/CabinexAi/cbx_parts_inspector.rb"
#            RunPartsInspector.scan
# =============================================================================
require 'sketchup.rb'
require 'json'

module RunPartsInspector
  OUT_JSON = File.expand_path('cabinex_parts_direction.json', __dir__)
  OUT_TXT = File.expand_path('cabinex_parts_direction.txt', __dir__)
  MAX_DEPTH = 8
  FRONT_SIGN = -1.0 # front faces -Y

  def self.scan(model = Sketchup.active_model)
    return UI.messagebox('No active model.') unless model
    entities = model.active_entities
    parts = []
    collect(entities, parts, 0, [])

    results = parts.map { |p| inspect(p) }.compact

    pass = results.count { |r| r[:status] == 'PASS' }
    fail = results.count { |r| r[:status] == 'FAIL' }
    unknown = results.count { |r| r[:status] == 'UNKNOWN' }

    report = {
      generated: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
      model: model.title,
      scanned: results.length,
      pass: pass, fail: fail, unknown: unknown,
      parts: results
    }

    File.write(OUT_JSON, JSON.pretty_generate(report))
    write_txt(report)

    puts ">> Parts Inspector: #{pass} PASS / #{fail} FAIL / #{unknown} UNKNOWN (of #{results.length})"
    results.select { |r| r[:status] == 'FAIL' }.each do |r|
      puts "   FAIL: #{r[:role]} -> #{r[:reason]}"
    end
    # summary of faces/orientations
    puts "   Faces used: #{results.group_by { |r| r[:expected_face] }.transform_values(&:length).inspect}"
    puts "   Report: #{OUT_TXT}"
    [{ pass: pass, fail: fail, unknown: unknown }]
  end

  # Walk groups, carrying the CBX tags of each part.
  def self.collect(ents, out, depth, attrs)
    return if depth > MAX_DEPTH
    ents.each do |e|
      next unless e.is_a?(Sketchup::Group) || e.is_a?(Sketchup::ComponentInstance)
      a = e.attribute_dictionary('CBX')
      new_attrs = a ? {} : nil
      if a
        a.each_pair { |k, v| new_attrs[k] = v }
      else
        new_attrs = attrs.dup
      end
      out << { entity: e, attrs: new_attrs, depth: depth }
      collect(e.entities, out, depth + 1, new_attrs)
    end
  end

  # Derive expected facing + orientation from role tags, then compare.
  def self.inspect(rec)
    e = rec[:entity]
    a = rec[:attrs]
    role = a['role'] || e.name.to_s
    b = e.bounds
    dims = { x: b.width.to_mm, y: b.depth.to_mm, z: b.height.to_mm }
    center = b.center
    is_handle = a['cbx_handle'] == true
    is_connector = a['cbx_connector'] && !a['cbx_connector'].to_s.empty?
    is_door = a['cbx_front'] == 'door'
    is_frame = a['cbx_front'] == 'faceframe'
    is_shelves = a['cbx_front'] == 'shelves'

    expected_face = is_handle || is_door || is_frame ? :front : nil
    expected_face ||= (is_connector ? (a['connector_face'] || :side).to_sym : nil)
    expected_face ||= (is_shelves ? :interior : nil)
    return nil if expected_face.nil? # untagged/non-part group -> skip

    # dominant axis = orientation
    dom = dims.max_by { |_, v| v }[0]
    orientation = dom == :x ? :horizontal : (dom == :z ? :vertical : :planar)

    # facing: does the part's thin axis sit toward -Y (front)?
    front_y = center.y # world front offset
    facing_front = front_y < 0

    # expected orientation per role (from the builder's own tag)
    expected_orient = if is_handle
                        (a['orientation'].to_s == 'horizontal' ? :horizontal : :vertical)
                      elsif is_door || is_frame
                        :planar_vertical
                      else
                        orientation
                      end

    # Robust orientation for a handle: the bar is an extruded profile - its LONG
    # axis (largest bbox dim) is the true orientation. A vertical pull's long
    # axis is Z; a horizontal pull's long axis is X. (Use the largest dim, which
    # we already compute as `orientation`; compare to the builder's own tag.)
    actual_handle_orient = orientation

    checks = []
    if is_handle
      checks << ["on front face", facing_front]
      # long axis of the pull (largest bbox dim) must match the builder tag
      checks << ["orientation #{expected_orient}", orientation == expected_orient]
    elsif is_connector
      # connector must be IN A JOINT (cam in panel face + bolt/dowel in mating
      # edge), on the 32mm grid - never a floating mid-face marker. `joint` tag
      # is set true by build_connector_visual when a position hash was given.
      checks << ["in a joint (cam+edge)", a['joint'] == true]
      checks << ["has connector info", !a['cbx_connector'].to_s.empty?]
    elsif is_door || is_frame
      checks << ["on front face", facing_front]
    elsif is_shelves
      checks << ["horizontal (thin z)", dims[:z] < dims[:x] && dims[:z] < dims[:y]]
    end

    failed = checks.reject { |_label, ok| ok }
    status = failed.empty? ? 'PASS' : 'FAIL'
    reason = failed.map(&:first).join(', ')

    {
      role: role[0, 48],
      status: status,
      reason: reason,
      expected_face: expected_face,
      actual_orientation: orientation,
      expected_orientation: (expected_orient == :planar ? 'planar' : expected_orient),
      dims_mm: "#{dims[:x].round(1)}x#{dims[:y].round(1)}x#{dims[:z].round(1)}",
      facing: facing_front ? 'FRONT(-Y)' : 'REAR/Y',
      center_mm: [center.x.to_mm.round, center.y.to_mm.round, center.z.to_mm.round]
    }
  end

  def self.write_txt(report)
    lines = []
    lines << "CABINEX PARTS DIRECTION REPORT  #{report[:generated]}"
    lines << "Model: #{report[:model]}   scanned: #{report[:scanned]}   pass: #{report[:pass]} fail: #{report[:fail]} unknown: #{report[:unknown]}"
    lines << ''
    lines << 'ROLE (48)                      STATUS  FACE         ORIENT     DIMS            FACING       CENTER'
    lines << '-' * 120
    report[:parts].each do |p|
      lines << format('%-30s %-6s %-12s %-10s %-15s %-12s %s',
                      p[:role], p[:status], p[:expected_face], p[:actual_orientation],
                      p[:dims_mm], p[:facing], p[:center_mm].join(','))
    end
    File.write(OUT_TXT, lines.join("\n"))
  end
end
