# 09 — Build Order, Decisions to Lock, Risks

**Decision first:** do **not** grow the SketchUp engine's option breadth for a
release cycle. Prove the **aluminium Method + one digital thread** on a few real
jobs. Map to roadmap levels: L0 trust → L1 capture-to-approved-design (MVP) →
L2 sold-job operations. Everything below is scoped by level.

---

## 1. Build order (each step is testable + sellable)

### L0 — Trust foundation (no customer data until this passes)
- [ ] Canonical schema + entity IDs (wall/run/cabinet/part) — `01`
- [ ] Append-only revisions + command/event log — `01`
- [ ] Rule inheritance + validation service — `01`
- [ ] Unit (mm) + rounding policy
- [ ] Org/workspace tenancy + RLS tests + private storage (Supabase)
- [ ] Signed/versioned extension; **remove remote Ruby eval** and demo/fallback auth
- [ ] Backup/restore + versioned API contract

**Exit:** two users can't read each other's data; a revision can be replayed; prod auth fails closed.

### L1 — Capture to approved design (the credible MVP) — **your current focus**
- [ ] Site PWA: capture + photo annotation + point-to-point + verify — `05`
- [ ] Room/wall graph (polygon, not just A/B/C) + obstacles/services — `04`
- [ ] Assign "what goes on which wall" dropdown + 2D wall preview — `06`
- [ ] **Aluminium Method schema + `Cabinex-FULL` default** (no-op refactor of v5.0) — `02`
- [ ] Engine reads Method instead of hard-coded consts (reveals, joints, handle, toe)
- [ ] Gola/handle notch calculator for continuous runs — from CabMaker
- [ ] **Authored part record + fail-closed BOM** — `03`
- [ ] Versioned BOM/cost (LKR) + owner freeze + customer approval link
- [ ] SketchUp sync: load job JSON, write IDs back, sync status — `08`
- [ ] @walls / #cabinets mentions + a small typed AI command set
  (create/move/resize/change-type) with validate → preview → accept — `01`/`06`

**North-star:** a site measurer captures a room; a designer opens the same project,
assigns runs, edits via the Method, reviews impact, gets a versioned BOM/quote and
sends an approval link; the owner opens it in SketchUp with no re-keying.

### L2 — Sold-job operations
- [ ] Change orders (post-approval edits = change-order candidates)
- [ ] Workshop PWA: labels/QR, cut plan, per-box elevation, station scans, defects/recut — `07`
- [ ] Offline workshop cache; printable fallback from the same approved revision
- [ ] Procurement need list (on-hand / reserve / short / substitution)

### L3+ (defer explicitly)
- [ ] Full CNC post-processors (machine acceptance suite required)
- [ ] Mixed-stock remnant optimizer; ERP scheduling; co-editing; procurement/accounting connectors

---

## 2. Decisions to lock now

| # | Decision | Lock |
|---|----------|------|
| 1 | Source of truth | Canonical cloud job graph with local cache; SKP is a synced representation |
| 2 | AI authority | Proposal-only; deterministic validation + explicit acceptance |
| 3 | MVP | Capture → assign → Method → 3D → versioned BOM/quote → approval → SketchUp sync |
| 4 | Manufacturing promise | Basic BOM/cut info first; no full CAM claim until machine contracts pass tests |
| 5 | Construction method | **Aluminium-native Method (Pillar 2) is the moat — protect it** |
| 6 | BOM authority | Authored part records, fail-closed; no inference, no default counts — `03` |
| 7 | Identifiers | Immutable UUIDs + durable display codes; never array-position identity |
| 8 | Commercial boundary | Approved design/BOM/estimate immutable; later edits → changes |
| 9 | Workshop format | Labels/QR + per-box elevation; printed pack from the same approved revision |
| 10 | Distribution | Signed/versioned packaged extension; stop code streaming |
| 11 | Pricing | Shop/workspace subscription with included AI; avoid per-token on iteration |

---

## 3. Risks and mitigations

| Severity | Risk | Mitigation |
|----------|------|-----------|
| Critical | Cloud-streamed eval / remote code | Signed packaged extension; server returns data+typed commands |
| Critical | Geometry as database (SKP names/order break IDs/BOM) | Canonical neutral model; SKP is an editor |
| Critical | Manufacturing error from AI inference | Typed ops, deterministic validation, impact preview, owner acceptance, freeze |
| Critical | Incorrect site measurement | Method/confidence, critical-dimension + re-measure gate before release |
| **High** | **Method refactor breaks v5.0 output** | Ship `Cabinex-FULL` as an exact no-op of current behaviour; golden jobs to compare |
| High | Authoring parts breaks existing report | Generate parts at build; report reads them; keep old report as regression baseline |
| High | Scope collapse (site+CAM+ERP+marketplace together) | Ship levels with exit criteria; finish L1 before L2/L3 |
| High | Token pricing suppresses AI iteration | Workspace/seat subscription; meter only expensive media/3D |
| High | Heuristic BOM hides missing data | Fail closed; surface missing-data blocks |
| High | Workshop adoption (small touch, office jargon) | Large targets, offline tolerance, printed fallback |
| Medium | Supplier/material price drift | Effective-dated catalogs + substitutions require approval |
| Medium | Customer privacy (site photos/addresses) | Private buckets, least privilege, retention, consent, secure links |

---

## 4. Feedback loop / north-star metric

- **Median time from completed site capture → customer-approved revision.**
- **Approved proposals per week** (AI acceptance) and **margin variance** (estimate vs actual).
- Track these before building more option breadth.

## 5. One-line verdict
> Don't build another cabinet generator. Build the **aluminium construction method**
> as the engine's reusable brain (`02`), author **parts, not inferred BOM** (`03`),
> and carry the whole job as **one digital thread** (`01`, `04`) across site, web,
> SketchUp and the shop (`05`–`08`).
