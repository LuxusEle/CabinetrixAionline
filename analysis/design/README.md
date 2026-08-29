# Cabinex Blueprints — Aluminum Construction Method + One Digital Thread

**Scope.** UI + workflow design only. No code. These documents convert the three
strategic pillars from the reading into a buildable plan, then design the UIs so
you can review screens before implementation.

**Status / context (from `PROJECT_STATE.md` v5.0.0).** The SketchUp extension is
aluminum-only (BoxBar + 3mm ACP + 45° sash + Gola/handle), live on
`https://cabinex-cloud.vercel.app`. The **web portal is still just a downloader**
(`OnlineCabinet/vercel_backend/public/{index,download,admin}.html`). The planner
is a 6-step wizard inside SketchUp (`cbx_hybrid_planner.html`):
Room/Walls → Openings → Project Settings → Modular Design → 3D Previews → BOM/Reports.

---

## The three pillars being designed here

### Pillar 2 — Aluminum construction-method layer (the durable moat)
Every competitor (CabMaker, eCabinet, KCD, Mozaik, PolyBoard) is a
**board / sheet-good** system that optimizes **panels**. Cabinex builds an
**extrusion** product (BoxBar carcase + ACP cladding + sash/Gola/handle). We do
not need *their* board model — we need an **aluminum-native "method"** that owns
every joint, profile, reveal, notch and hardware decision and drives the engine
deterministically, inherited `shop → project → room → run → cabinet → part`.
This is the thing no incumbent can copy quickly.
→ `02_aluminum_construction_method.md`

### Pillar 4 — Authoritative BOM (stop inferring)
Parts are **authored at generation time** into durable records (immutable ID,
material, thickness, dim, grain, edges, operations, hardware) and snapshotted per
approved revision. The report reads the record; it never re-derives BOM from
geometry names or array order, and it **fails closed** instead of guessing counts.
→ `03_bom_authority.md`

### Pillar 5 — One job, one digital thread
Site capture → wall sketch → annotate/assign → aluminum design → 3D → versioned
BOM/cost → approval → workshop labels/QR/cut-plan/elevations → install, all over a
**single canonical project graph** with immutable IDs and append-only revisions.
Web, phone, SketchUp and the shop are views/editors of the same records.
→ `01_canonical_job_model.md`, `04_workflow_pipeline.md`

---

## Document map

| File | Covers | Grounded in |
|------|--------|-------------|
| `01_canonical_job_model.md` | Domain model, IDs, revisions, authority, offline | Cabinetrix roadmap §7–9, §15, §23 |
| `02_aluminum_construction_method.md` | **The moat** — aluminum Method schema + parameter catalog | Mozaik params, PolyBoard sous-méthodes, CabMaker Handless Extrusions |
| `03_bom_authority.md` | Engineered part record, edges/grain/operations, snapshot, fail-closed | CabMaker reports, Mozaik edgeband + hardware, roadmap §12 |
| `04_workflow_pipeline.md` | End-to-end flow, phases, gates, state machine | Roadmap §5, §10; PolyBoard free-shape base; KCD wall flow |
| `05_ui_site_capture.md` | Site PWA wireframes (measure → mark → sketch → verify) | Roadmap §10 |
| `06_ui_studio_web.md` | Studio Web wireframes (app shell, wall graph, method panel) | KCD, Mozaik, CabMaker |
| `07_ui_workshop.md` | Workshop wireframes (labels/QR, cut-plan, per-box elevation) | CabMaker scenes/labels, roadmap §13 |
| `08_ui_planner_sketchup.md` | Planner reconceived around the Method + job graph | Existing 6-step wizard |
| `09_phasing_risks.md` | Build order, decisions to lock, risks | Roadmap §18, §23, §26 |

---

## What this does NOT cover (intentionally deferred)
- CNC post-processors — see roadmap §19 (defer for a machine-specific acceptance suite).
- Automatic photo-to-buildable design — photos are style/evidence intent only.
- Full procurement/accounting — export purchase needs first.

## Mapping to source folders (for when you implement)
- **Engine / part authoring:** `cabinex_ai/cbx_hybrid_engine.rb`, `cbx_hybrid_planner.rb`
- **Planner UI:** `cabinex_ai/cbx_hybrid_planner.html`
- **Web portal (currently downloader):** `OnlineCabinet/vercel_backend/public/`
- **Cloud backend:** `OnlineCabinet/vercel_backend/server.js` + Supabase
- **Job model / SaaS workspace:** `cabinetrix/` (the strategic target repo)
