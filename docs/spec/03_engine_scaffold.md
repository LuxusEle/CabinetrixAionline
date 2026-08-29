# 03 — Engine Scaffold: where the catalog plugs into CBXHybridEngine

**Purpose.** Show exactly where `00/01` catalog + schema connect into the existing
combined engine in `CabinexAi/cbx_hybrid_engine.rb`, so nothing is lost and the
board wardrobe/kitchen becomes the primary path.

---

## 1. Modules / files

| File | Role | Action |
|---|---|---|
| `cbx_hybrid_engine.rb` | canonical combined engine | keep; add hooks + `build_wardrobe` |
| `cbx_cabinet_method.rb` (new) | `CBXCabinetMethod` catalog loaders | `load` from loader.rb + engine |
| `loader.rb` | loads submodules | add `load cbx_cabinet_method.rb` |
| `cbx_hybrid_planner.rb` | orchestration | widen `kitchen_type` whitelist + wardrobe routing |

---

## 2. Existing engine entry points to touch (line numbers ≈)

### `build_box` (≈L3024) — the dispatcher
Add a `:wardrobe` type. Current switch: `:wall/:corner/:tall/:base` with a
`:style` (`:aluminum | :mdf | :hybrid`). Extend:

```ruby
case type
when :wardrobe
  build_wardrobe(parent_ents, opts.merge(style: style), mats) unless style == :aluminum
  build_wardrobe(parent_ents, opts, mats)   # board/rob is primary
```

### `build_wardrobe` (new, after `build_tall_cabinet` ≈L1200)
Reuses: `create_solid_box`, `build_grooved_mdf_back`, cover-side pattern
(inner carcase + 2 outer cover panels), `build_sash_assembly` (hinged).
Adds wardrobe internals from `method[:wardrobe]`:
`closet_rods` (rail + 2 hanging supports via `create_box_bar`), fixed/adj
shelves, pullout bank, vertical/horizontal dividers, hangers/nailers,
**sliding sash track** (top/bottom u-channel + 2 sash leaves via
`build_sash_assembly` with infill=:mirror). Tags
`'cabinet_type' => 'WARDROBE'`, orig/w/d/h, `'requires_plinth_cover'`,
`'front_system' => 'SLIDING_SASH' | 'HINGED_SASH'`.

### `build_wardrobe_run` (new, after `build_run` ≈L3093)
Loops units → `build_wardrobe`, then runs `build_merged_plinth_runs` +
`build_merged_gola_runs` (track is a separate merge; do NOT merge track into
Gola — different profile).

### `build_base_cabinet` / `build_board_wall` / `build_board_blind_corner` /
`build_board_tall_oven` — existing board builders, already reachable once
planner routing is widened. Keep as-is.

---

## 3. Connector / hole placement hooks

Add to engine, near `create_notched_horizontal_panel` / `paint_black_edges`:

```ruby
def self.resolve_joint_fasteners(method, joint)
  CBXCabinetMethod.resolve_connectors(method, joint)  # dedupe guard inside
end

def self.add_connector_bores(parent_ents, panel, fastener, opts)
  # Minifix: cam pocket (10/15mm) + bolt bore.
  # Confirmat: single stepped bore.
  # Dowel: 2 align bores.
  # Kept as markers (circles/attribs) in SketchUp; real bores → CNC export.
end

def self.add_accessory_cuts(parent_ents, cabinet, accessory, opts)
  # LED groove (6x12mm), wire hole (10mm), feet sockets, drawer bore_guide.
  # Routed into side/back; recorded as CBX attribs for BOM.
end
```

---

## 4. BOM / nesting (≈`generate_bom_and_nesting` L3126)
Add buckets: `:wardrobe_rod`, `:wardrobe_track`, `:mirror_infill` (sheet),
`:connector_minifix`, `:connector_confirmat`, `:hw_drawer_runner`,
`:accessory_led_strip`. Re-use `nest_2d_sheets` for mirror/board sheets; bars
nest via the existing 1D stock-length logic.

---

## 5. BOM authority guard (Pillar 4)
Parts get authored records at generate time (immutable id, material,
thickness, dim grain, edges, ops, hardware) and the report reads the record —
`fail closed`, never infer from geometry/order. This is already partially true;
extend it to wardrobe/connector parts.

---

## 6. Sequencing (no build yet — review gate)

1. `cbx_cabinet_method.rb` (catalog loaders) — pure Ruby, testable headless.
2. `build_wardrobe` + `build_wardrobe_run` (engine).
3. Connector/accessory hooks (engine).
4. Planner whitelist + wardrobe orchestration (planner).
5. BOM buckets + report.
6. Smoke-run `run_board_kitchen_wardrobe.rb` in SketchUp.

> **Guardrail.** Aluminum methods keep box-bar joints (bar-corner/tee), never
> `Dowel/Cam`. The catalog is per-method. No cross-contamination.
