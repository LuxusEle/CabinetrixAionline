# 02 — Engine-Consumable Catalog Schema (v0.1)

**Purpose.** The typed data structures + loader the `CBXHybridEngine` reads to
place connectors, hardware, and accessories. Mirrors `01_..._catalog.md`. This is
Ruby hash-based (matches the existing `opts[:...]` / `mats[:...]` engine style);
a JSON twin is emitted for the planner/AI layer.

---

## 1. Schema (`CBXCabinetMethod`)

```ruby
CBXCabinetMethod = {
  id:            "BOARD_WARDROBE",      # frozen identifier
  version:       1,                     # append-only
  carcase:       { system: :board,      # :board | :aluminum
                   thickness_mm: 18.0,
                   back_mm: 6.0,        # grooved board back (BOARD_BACK)
                   material_key: :wood },
  front:         {
                   system: :sash,       # :slab | :sash | :finger
                   door_gap_mm: 3.0,    # authoritative reveal knob (CabMaker p300)
                   infill: :mirror,     # :acp | :glass | :mirror
                   sash_miter_deg: 45.0,
                   handle: { side: :opening,
                             profile: :finger,   # :none | :finger | :gola
                             offset_mm: 32.0 },
                   slide:   { type: :top_bottom,  # :top_bottom | :nil
                              leaves: 2,
                              track_depth_mm: 50.0,
                              track_profile: :u_channel } },
  toe:           { mode: :plinth,       # :plinth | :aluminum_foot_frame
                   height_mm: 100.0,
                   setback_mm: 50.0 },
  joins: [
    { joint: :back_to_side,     style: :blind_dado, setback_mm: 0.0 },  # BkUE
    { joint: :top_to_back,      style: :dado,       tenon_mm: 9.0 },    # BkTB/BKQDado
    { joint: :partition_to_back, style: :dado_into_back | :none },      # BKPar
    { joint: :partition_to_shell, style: :dado }                        # partitions dadoed
  ],
  fasteners: {
    # Mozaik JointFast 1-8 + PnlFast, upto 8 never repeated (p133)
    joint: [ { template: :minifix, on: [:finished_end, :top] },
             { template: :confirmat, on: [:unfinished_end] },
             { template: :dowel, on: [:all] } ],
    panel: { base:  [:minifix, :dowel],
             wall:  [:confirmat],
             tall:  [:minifix, :confirmat],
             robe:  [:minifix, :dowel] }
  },
  holes: { shelf_cluster_count: -1,        # CabMaker 'Cluster Size' (p47); -1 engine-default
           shelf_line_holes_mm: 32.0 },    # 32mm/37mm system spacing
  accessories: {
    led_groove: { enabled: true, section_mm: [6.0, 12.0], location: :under_top },
    wire_hole:  { enabled: true, mm: 10.0, per_side: :rear },
    feet:       { enabled: true, type: :adjustable },
    drawer: { box: :undermount,        # :preassembled | :undermount
              soft_close: true, full_extension: true,
              bore_guide: true,        # drill guide for screw/runner
              box_material_key: :wood }
  },
  wardrobe: {
    rods:          [ { from_bottom_mm: 900.0 } ] ,  # CabMaker 'Closet Rods' (p48)
    rods_from_back_mm: -1,                         # -1 = auto centre (p47)
    fixed_shelves: 3,
    adj_shelves:   2,
    override_openings_mm: [],
    pullouts:      [ { height_mm: 0, depth_mm: 0 } ],  # 0 = default (p51-53)
    dividers:      { vertical: 0, horizontal: 0 },
    hangers:       :none,                           # :none|:top|:bottom|:both|:project
    stretchers:    1 }
}
```

---

## 2. Loader API (`CBXCabinetMethod.resolve_*`)

```ruby
module CBXCabinetMethod
  DEFAULTS = { "BOARD_WARDROBE" => METHOD_BOARD_WARDROBE, ... }.freeze

  def self.get(id) -> hash                 # returns a deep-copied method
  def self.from_json(json) -> hash         # planner/AI payload -> method
  def self.to_json(method) -> string       # feed planner report / AI
  def self.resolve_connectors(method, joint) -> array[fastener]
     # selects from method[:fasteners][:joint] whose :on includes joint or :all
     # guard: dedupe by template (Mozaik p133 double-drill guard)
  def self.resolve_panel_fasteners(method, part_type) -> array
```

---

## 3. Rubocop/lint alignment
- Keep hash keys as symbols; units in `.mm` lengths converted at build time via
  the existing `to_mm` idiom in `cbx_hybrid_engine.rb`.
- Constants default with `unless const_defined?` (matches existing Gola/MDF consts).
- No comments unless required (repo style: terse `#` only at section headers).

---

## 4. Where this lives
- Engine source: `CabinexAi/cbx_hybrid_engine.rb` (canonical, combined).
- This spec is design-only; the loader module goes in its own file
  `cbx_cabinet_method.rb` so it can be `load`ed by both the engine and loader.rb.
