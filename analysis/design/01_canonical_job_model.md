# 01 — Canonical Job Model (One Digital Thread)

**Goal.** Make a versioned, neutral job graph the single source of truth. The
SketchUp model, the phone, the web app and the shop are **views or editors** of the
same records. This is the foundation for Pillar 5 and the container for Pillar 4.

> Why it matters (from the roadmap verdict): "Declare the canonical project graph —
> not the SketchUp file, screenshots or chat history — as the source of truth.
> Without this, every later feature becomes a fragile integration project."

---

## 1. Authority hierarchy

```
Approved revision          immutable — production/commercial authority
Working design revision    rooms, walls, runs, cabinets, constraints, references
Derived engineering        parts, operations, BOM, nesting, previews (reproducible)
Rendered views             SKP, GLB, PNG, PDF, DXF, labels (replaceable artifacts)
```

- Derived files may be regenerated.
- An **approval must always point to an immutable design + BOM snapshot**, never a live model.
- Part identity comes from records, **never** from group names or array order.

---

## 2. Core entities (one per row, all with `uuid` + `revision_id`)

### 2.1 Identity / tenant
| Entity | Notes |
|--------|-------|
| `organization`, `workspace`, `member`, `role` | RLS tenant isolation |
| `customer`, `site`, `supplier` | |

### 2.2 Design (the graph sketchup + web + phone share)
| Entity | Key fields | Authority |
|--------|-----------|-----------|
| `project` | name, unit, datum, revision | Designer |
| `room` | floor/ceiling datum, unit, orientation, boundary polygon | Designer |
| `wall` | start/end point, length, height samples, thickness, surface, `wall_uuid` | Designer |
| `opening` | type, wall, offset, width, height/sill, trim, swing | Designer |
| `obstacle` | column/beam/pipe/box, bounds, clearance | Designer |
| `run` | wall, method, modules, `run_uuid` | Designer |
| `cabinet` | type, dims, template, `cabinet_uuid`, constraints, mnemonic `#B-104` | Designer |
| `constraint` | rule, scope, value, threshold | System |

### 2.3 Engineering (Pillar 4 lives here)
| Entity | Key fields |
|--------|-----------|
| `product_template` | door, drawer, tall, hood, bench, appliance surround |
| `construction_method` | **the aluminum Method — see 02** |
| `part` | `part_uuid`, cabinet, material, thickness, WxDxT, grain, edges, operations, hardware |
| `joint`, `machining_operation` | type, tool, face, depth, status |
| `hardware_item` | SKU, qty, family |

### 2.4 Commercial
`quote`, `quote_revision`, `estimate_revision`, `approval`, `deposit`, `change_order`, `invoice_ref`
- Every **accepted AI change after approval = a change-order candidate**.
- Estimate revisions carry **effective date + expiry**; never recalc a sent quote with today's prices.

### 2.5 Production
`bom_snapshot` (immutable), `work_order`, `station`, `task`, `label`, `scan_event`,
`exception`, `recut` / `defect`.
- Labels/QR resolve an immutable `part_uuid` / `work_order_id`.

### 2.6 Materials / waste
`material`, `stock_item`, `lot`, `sheet`, `remnant`, `reservation`, `consumption`, `return`.
- Remnant is an **inventory transaction** (create/reserve/consume/split/scrap) with QR + real location.

### 2.7 Media / AI
`attachment`, `photo`, `annotation`, `reference_image`, `ai_thread`, `ai_command`,
`proposal`, `validation_result`.
- Photos are evidence; **never** the source of dimensions (no reliable scale in a photo).

### 2.8 Delivery / lifecycle
`purchase_order`, `receipt`, `load_manifest`, `installation`, `punch_item`, `handover`, `warranty_case`.

---

## 3. References: named mentions resolve to UUIDs
`@Wall-B`, `#B-104`, `%B104-LS`, `!SITE-028`.

| Token | Resolves to | Rule |
|-------|-------------|------|
| `@Wall-B` | `wall_uuid` | Name can change; UUID + lineage do not |
| `@Run-A1` | `run_uuid` | A wall may hold several runs/zones |
| `#B-104` | `cabinet_uuid` | Never renumber after issue; display order is a separate field |
| `%B104-LS` | `part_uuid` | Introduced when the part model is authoritative |
| `!SITE-028` | `attachment_uuid`/`issue_uuid` | Reference evidence without dumping media into prompts |

- The stored chat command keeps **both visible text and resolved IDs**, so renaming later does not corrupt history.
- If a referenced cabinet was deleted/superseded, UI shows lineage and asks whether to retarget the replacement.

---

## 4. Rules + inheritance scope

Shop method → project → room → run → cabinet → part/edge **override**.
Each property declares the deepest scope it may be set at (mirrors roadmap's
`set_option` guard: "property must be allowed at that inheritance scope").

---

## 5. Revisions + events (append-only)
- `design_revision` (author, reason, parent, timestamp) — can be superseded, never overwritten.
- `event` log: **every** human or AI mutation is replayable and attributable.
- Sync: local **outbox** with globally unique command IDs; every write carries the
  base revision it was written against; server accepts / rejects / conflicts —
  **never** silent last-write-wins on geometry.
- Status seen in SketchUp: `Unsynced · Syncing · Current · Conflict · Read-only(approved)`.

---

## 6. Units + rounding
- Canonical values in **mm**; display units and manufacturing rounding are separate policies.

---

## 7. What stays in SketchUp vs what must not
**In SketchUp (cached):** canonical IDs + current revision ID in attribute
dictionaries; geometry/materials for professional editing; a local snapshot with
explicit sync status.

**NOT only in SketchUp:** customer approvals, prices, purchase state, scan events,
defects, audit log, remnant inventory, the only copy of photos/evidence/AI decisions,
and any part identity derived from mutable names/order.
