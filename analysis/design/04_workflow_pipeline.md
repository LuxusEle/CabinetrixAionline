# 04 — End-to-End Workflow: Capture → Shop

**The one prompt to rule them all.** Turns your described flow into an explicit,
gated pipeline that both the phone app, the web app and SketchUp share. Each phase
has an owner, an input, an output, gates and a "good" definition.

---

## 1. The pipeline (state machine)

```text
[0 Capture]  site + photos + point-to-point marks
   │              → START (job, room, datum, unit, orientation)
   ▼
[1 Sketch]  auto 2D wall sketch: walls + obstacles + services
   │              → user edit → VERIFY (coverage + confidence)
   ▼
[2 Assign]  dropdown: what goes on which wall (runs + modules)
   │              → 2D wall preview in-app → OK
   ▼
[3 Method]  aluminium Construction Method (from Pillar 2) + settings
   │              → engine validates (method + joints + reveals)
   ▼
[4 Design]  aluminium cabinets → 3D views (front / return / top / iso)
   │              → deterministic validation + impact preview
   ▼
[5 Freeze]  versioned BOM + cost (LKR) → owner freeze → approval
   │              → approval is a REVISION BOUNDARY
   ▼
[6 Shop]    work order → labels/QR → cut plan → per-box elevation → station scans
   ▼
[7 Install] load manifest → install → punch list → warranty case
```

### 1.1 Phases in detail

| Phase | Surface | Owner | Input | Output | Gate |
|-------|---------|-------|-------|--------|------|
| **0 Capture** | Site PWA | Measurer | Room, datum | walls/lengths, photos, annotations | All critical dims entered + photo |
| **1 Sketch** | Site PWA | Measurer | marks | editable 2D wall sketch + obstacles + services | Coverage + diagonal check; warn on out-of-square |
| **2 Assign** | Site PWA → Studio | Designer | wall graph | run/module assignment | Every wall has intent (or is void) |
| **3 Method** | Studio / planner | Designer | assignment | aluminium Method + settings | Method valid (no illegal override) |
| **4 Design** | Studio / SketchUp | Designer | Method | 3D + parts + hardware marks | Deterministic geometry validation |
| **5 Freeze** | Studio | Owner | 3D | BOM snapshot + estimate + approval | Immutable snapshot; approval points to it |
| **6 Shop** | Workshop PWA | Operator | approval | labels, chevron cut plan, per-box elevation, scans | Part × station scans reconciled |
| **7 Install** | Workshop PWA | Installer | load manifest | punch list → sign-off | All punch items closed |

---

## 2. Capture details (the part you asked to design well)

### 2.1 Walk clockwise, mark point-to-point
1. **Start.** pick room + floor/ceiling datum + unit (mm).
2. **Walk walls** clockwise. For each wall: measure length; mark **point-to-point**
   endpoints on the live sketch (click start → click end → enter length → drag to
   correct a midpoint → auto-snap the sketch).
3. **Openings/services/obstacles** on each wall: type, offset, width, height/sill,
   swing (door), photo.
4. **Diagonals** when room looks square; compare implied geometry, show tolerance.
5. **Clip heights** for full-height / built-ins; capture 2+ levels.
6. **VERIFY screen** — coverage + confidence per wall; missing critical items are
   called out; re-measure gate before design.

### 2.2 Sketch graph (PolyBoard "free-shape base" analogy)
A room/wall is a **polygon**, not just A/B/C. Each side is typed
`front | return | blind`. Obstacles/services are attached to sides. This is the
PolyBoard free-shape base concept generalised to a room — so a future U, L,
micro-kitchen, odd-junction or non-square run is a first-class case, not a special case.

### 2.3 Accuracy rules (from roadmap §10 + Leica DISTO plan)
- A photo has **no reliable scale** — require an entered dimension, known reference,
  or a connected laser reading.
- Ask for diagonals; show tolerance warnings.
- Services & appliance requirements are **hard constraints**, not photo notes.
- Before production, require a critical-dimension checklist with who verified each value.
- Capture works offline; writes to a local **outbox** and syncs (`Unsynced →
  Syncing → Current · Conflict · Read-only(approved)`).

---

## 3. Assign screen: "what goes on which wall"

- Left: wall list (with sketch thumbnail + status).
- Right per wall: **dropdown** of module categories (Base / Drawer stack / Tall tower /
  Wall / Hood bay / Open rack / Appliance surround / End filler). Pick a module →
  set width → the run fills; residual space shown as filler, never silently stretched.
- Live **2D wall preview** (the temp 2D inside the app) updates as you add modules;
  "OK" commits the run at its anchor.

---

## 4. Aluminium design → 3D → validate

- Uses the **Method** (Pillar 2) to build geometry through the existing engine.
- View set: front elevation, return, top plan, iso (same as current Step 5).
- Before commit: deterministic validation (width/depth/height range, junction,
  clearances, door swings, appliance gaps) — from roadmap §9 and §23.

---

## 5. Freeze / approval (revision boundary)

- Working design is editable; **freeze** = immutable snapshots (design + BOM +
  estimate).
- Customer approval link: review, annotate, accept / request change.
- Any accepted AI/question change after approval → **change-order**, not silent edit.

---

## 6. Shop deliverables (what workers see — see 07)

- **Bar cut plan** (1D aluminium) + **sheet cut plan** (2D ACP) with grain + kerf.
- **Per-box elevation** with part codes + hardware marks.
- **Labels / QR** → durable `part_uuid` + `bom_snapshot_id`.
- **Assembly sequence** per cabinet module.

---

## 7. Anything else "better from the books" to fold in

| Book idea | Where it fits |
|-----------|---------------|
| KCD **Set Shop Standards / Wall Defaults** | The Method library + room/wall defaults (Phase 3) |
| KCD **island/peninsula** double-sided back | `front | return` types + two-sided assignments |
| PolyBoard **zones / multi-zones** (insert into zone) | Assignment by interior zone, not just "on wall" |
| CabMaker **Manage Scenes / assembly images** | Auto-create per-cabinet views for the shop pack |
| CabMaker **Door & Drawer listings** | Outsourced sash/infill orders (optional) |
| eCabinet **cost — historical ratio + labour based** | Cost model with actuals feedback |
| Mozaik **cut list + edgeband + hardware templates** | Authoritative part operations (Pillar 4) |
