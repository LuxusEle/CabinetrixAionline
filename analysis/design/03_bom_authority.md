# 03 — Authoritative BOM (stop inferring parts)

**Goal.** The report reads an authored, engineered part record. It never re-derives
BOM from group names, material names, or array order, and it **fails closed** when
required data is absent (never prints a guessed quantity).

> Why (roadmap §3): "BOM part IDs are regenerated during each nesting run, which
> prevents durable labels, scan history and recut lineage. Several BOM results have
> fallback quantities when recognition fails; production software must fail visibly
> instead of guessing." That is our weakness today — this fixes it.

---

## 1. The authored `part` record

Produced **only** at generation time by the engine, keyed to an immutable id.

```text
Part {
  part_uuid        : id            // durable, QR/label target
  cabinet_uuid     : id
  method_ver       : MethodId      // the Method + version that authored it
  family           : profile | cladding | sash | gola | handle | skin | hardware
  material_sku     : { sku, finish, thickness, grain_direction }
  stock            : { source_lot_id, length, module }  // for extrusions: bar no
  dimensions       : { w, d, t }   // finished size, canonical mm
  grain_arrow      : direction     // bar direction / sheet grain
  edges            : [ { edge: {L,R,T,B,F,Bt}, code, thickness, texture } ]
  operations       : [ { op: cut|notch|drill|tap|miter|paint_edge, tool, face, status } ]
  hardware         : [ { sku, family, qty, cup/backset } ]
  interchange      : { group, is_chiral }   // left/right not merged blindly
  source           : { rule, constraint_ref }  // traceability to the design intent
}
```

### 1.1 Extrusions vs sheets
- **Aluminium bar/profile** (BoxBar, sash, Gola, handle, plinth): length in mm,
  `stock.length`, `bar_no`; the 1D cut list is a bar-optimiser.
- **ACP sheets** (cladding, skins): W×D, grain arrow, sheet nesting.

---

## 2. Edge + grain + operations (borrowed from incumbents)

| Concept | Source | Cabinetrix use |
|---------|--------|----------------|
| Edgeband / edge assignment template | Mozaik `BandTemp` (up to 4 bandings) + CabMaker edging short-codes (`C-...`) | Which edge gets a bead/trim/clear-anodize; code printed on the label |
| Shelf support / cluster | CabMaker "shelf support clustering" | Where ACP shelf rests / strut clearance |
| Hardware schedule | CabMaker Hardware Listing; Mozaik joint fastener templates | Exact hinge/SKU/qty; `fail` if a fence is unset |
| Part rotation for nesting | CabMaker rotation group | Grain/kerf aware 2D nesting, chiral kept separate |
| Thru-bore to avoid flip-side | Mozaik linebore thru-bore | Tap points that line up → drilled through once |

**Chirality rule (from CabMaker):** never combine left/right into "like parts" when
drilling patterns differ. Keep `is_chiral` parts distinct. This is exactly the sash
end / hinge-stile left-right logic Canvas already models.

---

## 3. Snapshot + versioning

- A `bom_snapshot` is **immutable**, linked to a `design_revision` + calculation
  version (Method + material catalog + rate version).
- Re-running the engine creates a **new** snapshot; history is preserved.
- QR/labels point at a `part_uuid` **and** `bom_snapshot_id` so an obsolete label is
  detectable (stale parts can't be mixed into a new batch).

---

## 4. Validations (fail closed, don't guess)

| Check | Behaviour |
|-------|-----------|
| Missing material SKU | Block export; list the part. Do **not** default to "MDF". |
| Unrecognised part / no authored record | Block — never infer by name/colour/shape |
| Unknown hardware | Block until fenced; no assumed hinge count |
| Chiral parts merged | Reject; split into L/R |
| Part overflow > stock bar / sheet | Split or warn (never silently shrink) |
| No grain arrow | Warn + ask |

---

## 5. Reports the record feeds (unchanged UX, new authority)

- **Cut list (1D bar + 2D sheet)** — from authored `dimensions`, not from geometry.
- **Cut plan / nesting map** — grain- and kerf-aware, `is_chiral` split.
- **Per-box elevation plan** — front/return/top with callouts + hardware marks.
- **Labels** — part id, finished dims, material/thickness/grain arrow, edge codes, QR.
- **BOM + cost** — versioned quantities; separate base cost, overhead, waste,
  labour, markup, tax; LKR native.
- **Door / drawer-box listings** — for ordered-out fronts (like CabMaker Door &
  Drawer Box listings) if a shop outsources sash/infills.

---

## 6. What changes in code, conceptually

- Engine **emits** `Part` records when it creates geometry (single source).
- Export/report/NCC pipeline only **reads** records.
- Add an edgeband/grain/operation template resolution step (Pillar 2 Method) so a
  part's operations are deterministic and repeatable.
- Remove all fallback-count logic; surface missing-data blocks in the UI, not silences.
