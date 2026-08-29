# =============================================================================
# Cabinex AI — Construction Method & Connector Catalog Loader
# (c) 2026 Cabinex AI. All Rights Reserved.
# Reads the unified hardware/connector/accessory catalog (docs/spec/01 and
# 02) into engine-consumable Ruby hashes. Every construction method owns its
# own joint set + fastener set + accessories so connectors are NEVER shared
# across methods (aluminum keeps box-bar joints; board uses cam/dowel).
# =============================================================================

require 'json'

module CBXCabinetMethod
  BOARD_THICKNESS_DEFAULT = 18.0
  BOARD_BACK_DEFAULT = 6.0

  METHODS = {
    'BOARD' => {
      id: 'BOARD', version: 1,
      carcase: { system: :board, thickness_mm: 18.0, back_mm: 6.0, material_key: :wood },
      front: {
        system: :slab, door_gap_mm: 3.0, infill: :acp, sash_miter_deg: 45.0,
        handle: { side: :opening, profile: :finger, offset_mm: 32.0 }
      },
      toe: { mode: :plinth, height_mm: 100.0, setback_mm: 50.0 },
      joins: [
        { joint: :back_to_side, style: :blind_dado, setback_mm: 0.0 },
        { joint: :top_to_back, style: :dado, tenon_mm: 9.0 },
        { joint: :partition_to_back, style: :dado_into_back },
        { joint: :partition_to_shell, style: :dado }
      ],
      fasteners: {
        joint: [
          { template: :confirmat, on: [:unfinished_end] },
          { template: :dowel, on: [:all] }
        ],
        panel: { base: [:confirmat, :dowel], wall: [:confirmat], tall: [:confirmat, :dowel], robe: [:minifix, :dowel] }
      },
      holes: { shelf_cluster_count: -1, shelf_line_holes_mm: 32.0 },
      accessories: {
        led_groove: { enabled: true, section_mm: [6.0, 12.0], location: :under_top },
        wire_hole: { enabled: true, mm: 10.0, per_side: :rear },
        feet: { enabled: true, type: :adjustable },
        drawer: { box: :undermount, soft_close: true, full_extension: true, bore_guide: true, box_material_key: :wood }
      },
      wardrobe: {}
    }.freeze,

    'BOARD_WARDROBE' => {
      id: 'BOARD_WARDROBE', version: 1,
      carcase: { system: :board, thickness_mm: 18.0, back_mm: 6.0, material_key: :wood },
      front: {
        system: :sash, door_gap_mm: 3.0, infill: :mirror, sash_miter_deg: 45.0,
        handle: { side: :opening, profile: :finger, offset_mm: 32.0 },
        slide: { type: :top_bottom, leaves: 2, track_depth_mm: 50.0, track_profile: :u_channel }
      },
      toe: { mode: :plinth, height_mm: 100.0, setback_mm: 50.0 },
      joins: [
        { joint: :back_to_side, style: :blind_dado, setback_mm: 0.0 },
        { joint: :top_to_back, style: :dado, tenon_mm: 9.0 },
        { joint: :partition_to_back, style: :dado_into_back },
        { joint: :partition_to_shell, style: :dado }
      ],
      fasteners: {
        joint: [
          { template: :minifix, on: [:finished_end, :top] },
          { template: :confirmat, on: [:unfinished_end] },
          { template: :dowel, on: [:all] }
        ],
        panel: { base: [:minifix, :dowel], wall: [:confirmat], tall: [:minifix, :confirmat], robe: [:minifix, :dowel] }
      },
      holes: { shelf_cluster_count: -1, shelf_line_holes_mm: 32.0 },
      accessories: {
        led_groove: { enabled: true, section_mm: [6.0, 12.0], location: :under_top },
        wire_hole: { enabled: true, mm: 10.0, per_side: :rear },
        feet: { enabled: true, type: :adjustable },
        drawer: { box: :undermount, soft_close: true, full_extension: true, bore_guide: true, box_material_key: :wood }
      },
      wardrobe: {
        rods: [{ from_bottom_mm: 900.0 }],
        rods_from_back_mm: -1,
        fixed_shelves: 3, adj_shelves: 2, override_openings_mm: [],
        pullouts: [{ height_mm: 0, depth_mm: 0 }],
        dividers: { vertical: 0, horizontal: 0 },
        hangers: :none, stretchers: 1
      }
    }.freeze,

    'ALUMINUM' => {
      id: 'ALUMINUM', version: 1,
      carcase: { system: :aluminum, thickness_mm: 0.0, back_mm: 0.0, material_key: :alu },
      front: {
        system: :sash, door_gap_mm: 3.0, infill: :acp, sash_miter_deg: 45.0,
        handle: { side: :opening, profile: :finger, offset_mm: 32.0 }
      },
      toe: { mode: :aluminum_foot_frame, height_mm: 38.1, setback_mm: 0.0 },
      joins: [
        { joint: :bar_corner, style: :box_bar, setback_mm: 0.0 },
        { joint: :bar_tee, style: :box_bar, tenon_mm: 0.0 }
      ],
      fasteners: { joint: [], panel: { base: [], wall: [], tall: [], robe: [] } },
      holes: { shelf_cluster_count: -1, shelf_line_holes_mm: 32.0 },
      accessories: {},
      wardrobe: {}
    }.freeze
  }.freeze

  module_function

  def get(id)
    method = METHODS[id.to_s]
    raise ArgumentError, "Unknown construction method: #{id}" unless method
    Marshal.load(Marshal.dump(method))
  end

  def from_json(json)
    data = JSON.parse(json)
    get(data['id'] || 'BOARD')
  end

  def to_json(method)
    JSON.pretty_generate(method)
  end

  def resolve_connectors(method, joint)
    fasteners = (method && method[:fasteners][:joint]) || []
    matched = fasteners.select { |f| Array(f[:on]).include?(joint) || Array(f[:on]).include?(:all) }
    dedupe_check!(matched, joint)
    matched.map { |f| f[:template] }
  end

  def resolve_panel_fasteners(method, part_type)
    (method && method[:fasteners][:panel][part_type]) || []
  end

  def dedupe_check!(list, joint)
    templates = list.map { |f| f[:template] }
    dups = templates.tally.select { |_, count| count > 1 }.keys
    raise "Fastener template duplication on #{joint}: #{dups.join(', ')}" unless dups.empty?
  end
  private_class_method :dedupe_check!
end
