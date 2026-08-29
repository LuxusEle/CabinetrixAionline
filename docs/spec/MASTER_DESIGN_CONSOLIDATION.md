# CABINEX AI — MASTER DESIGN CONSOLIDATION
# (Consolidated from all user inputs across the build session)

> This is the single source of truth for the CabinexAI master cabinet engine.
> Read this first. Every design decision must trace back to a requirement here.

---

## 1. THE VISION (what CabinexAI is)

A **master, all-in-one cabinet software** — not another half-cooked cabinet app. We
start from where others stopped and make it *smart and all-in-one*.

> "No point doing another cabinet app half-cooked. We start from others, stop and
> make it smart and all in one, period."

The product generates **board-based (melamine particleboard) kitchens AND
wardrobes** — with ALL advanced features working together: Gola profile merging,
sash doors (hinged + sliding/mirror), connectors, accessories, plinth combining,
BOM/nesting, reports, DXF export for CAM.

**Nothing is lost.** The existing aluminum BoxBar system is retained as a
selectable construction method; board is the primary path.

---

## 2. THE ARCHITECTURE / LAYERING

```
1. ELEVATION COMPOSER        (elevation_composition.json)
     solves the wall: anchors -> axes -> groups -> candidates -> score
2. CABINET RULE ENGINE       (cabinet_types.json, methods.json, manufacturing_rules.json)
     turns each module into a real carcase + fronts + hardware
3. HARDWARE / ENGINE         (hardware_rules.json, accessories.json, wardrobe_rules.json,
                              connector_placement_matrix.json)
     places exact hinges/drawers/connectors by System 32
```

**Streaming model (confirmed correct, kept):**
`vercel` auth -> `POST /api/engine/load` -> `eval(engine_code)` into SketchUp RAM
-> master combined engine (app_type = board|aluminum switch exists in server.js).

---

## 3. NON-NEGOTIABLE CONSTRUCTION RULES (from references)

### 3a. System 32 (the coordinate system)
- **5mm holes at 32mm centres** on the **internal faces of ALL vertical panels**
  (LMFKB3005A p52). Houses drawer runners, hinges, mounting plates, shelf
  supports, connectors.
- **ONLY vertical panels are line-bored**; horizontal panels get EDGE machining.
- Rods, drawers, hinges, connectors snap to the 32mm grid. **Nothing floats.**

### 3b. Real carcase
- frameless cabinet = **back + base + two ends + TWO rails** (front rail + back
  rail to fix bench top; front rail ON EDGE for sink/hob) (LMFKB3005A p54).
- Back = **external back** most common method.
- Board: **16mm white melamine** for carcase + drawer box; MDF for doors/backs.

### 3c. Connectors are AT the joint (butt joint)
- **Butt joint** = edge of one panel against face of another (p40).
- **KD fittings, 3 groups** (p41-42): Quick-assembly (press-stud: insert in one
  component + metal dowel in other) / Surface (fixed to surface) / **Flush**
  (in pre-machined holes: **dowel + cam, confirmat**) = the cabinet joint family.
- **Steelfix/Minifix** (authoritative dims):
  - cam **Ø15 × 12.5mm**, **B = 34mm** from joint edge to cam centre (bored in
    the horizontal panel face, down -Z)
  - connecting bolt: thread **Ø5×11** into vertical face + collar **Ø7.5×1.5** +
    pin **Ø6.5×32.5** into cam + spherical head
  - edge bore **Ø8×34**; face bore **Ø5×11.5**
  - alignment dowel **Ø8 × 30mm** beech, at 32mm pitch
- **Dowel** Ø8×30 (face 10.5, edge 21); **Confirmat** Ø7×50, head Ø10, pilot Ø5×42.
- **PLACEMENT IS BY DIRECTION VECTOR** (`build_minifix_joint(bolt_center,
  dir_vector,...)`), never guessed [x,y,z].

### 3d. Drawer (production formulas)
- **16mm box** (front/back/sides) + MDF/hardboard base.
- **12-13mm free space each side** for runners (GRASS EB = 29/30mm).
- GRASS formulas: **BB = LWK − 2×EB; BL = NL − 19; RWB = BB/BB−16/BB−84**.
- Standard heights **H63/90/122/186/250**.
- REAL drawer box: 2 sides + front + back + bottom, concealed runners.

### 3e. Doors / fronts
- Cup hinge **35mm cup, 3mm edge, 1mm gap**; mounting plates on **37/32 + 20/32**
  grid; Distance D = 4.5 + B − A. (Hettich TA_2016_01 Vol 1.)
- Door taxonomy (eCabinet p417-420): **Slab** / **MDF profile** / **5-Piece
  (Shaker, stile & rail)**.
- Construction methods (Mozaik p17-18): Frameless / 32mm / Face Frame / Full
  Overlay / Frame Inset / Frameless Inset — the master switch (`Const`).
- Reveal math (CabMaker p300-302): overlay = spacing − gap (197); inset =
  spacing − 2×gap (194); default door gap **3mm**.

### 3f. Wardrobe (corrected — drawer boxes INSIDE)
- Drawer boxes/rods/shelves are **separate interior organizers INSIDE the frame**,
  sized to frame inner width/depth, **BEHIND the door plane** (PAX/KOMPLEMENT,
  Mozaik/eCabinet = confirmed by user).
- Frame standard: widths 500/750/1000, depths 350/580/600, heights 2010/2360.
- Rod under a **structural top shelf**, on grid; positioned by
  **ClosetRodPosition** (rod-top → opening-top); **ClosetThruBore**.
- Sliding: top-running (TopLine XL) — shallow hidden runner, bottom guide set
  back beneath base, Silent System damper, leaves ride front/back track, mirror
  leaves.

---

## 4. GOLA SYSTEM (production spec)

- **Gola depth** 26mm; **L-height** 59mm, **C-height** 73.5mm; wall 1.5mm;
  profile depth 27.2mm; L-profile height 56.5, C-profile 73.
- CNC side pockets: L-cutout 59mm + C-cutout 73.5mm, 26mm inset.
- **Profile channel must OPEN toward the FRONT (−Y)** (user-flagged fix).
- Continuous Gola across a run; merged Gola runs; plinth merged separately
  (different profile — never merged into Gola).
- 16× Minifix per 2×600 drawer bank.

---

## 5. THE "30,000-ft" RULES (how the system must think)

1. **Never scale a cabinet to fill wall width.** Solve the wall by:
   anchors → axes → groups → candidates → score → top 3.
2. **Never coerce a known box type to another.** Board ≠ aluminum ≠ wardrobe.
3. **Two rule types:** HARD constraints (appliance size, plumbing, hinge limits,
   clearance, corner mechanism space, services — a design violating = INVALID)
   and SOFT design constraints (symmetry/repetition/alignment → DESIGN SCORE).
4. **Coordinate frame & direction.** Every part resolves against a face + forward
   vector (front = −Y). Hardware by direction vector, never guessed coords.
5. **No guesswork.** Knowledge comes from references, encoded in JSON, consumed by
   the engine. Anything you can't map to a rule = add a knowledge entry, not guess.
6. **Domain objects stay separate:** CABINET / CARCASS / FRONT / PANEL / OPENING /
   HARDWARE / ACCESSORY / APPLIANCE / MACHINING / MATERIAL. A door is not a
   cabinet; a drawer is not a front; Gola is physical geometry; a LeMans is not
   an image.
7. **BOM & cut list come FROM the model** — never maintained independently.
8. **QA gate:** scrape real geometry the moment boxes are built, log every part's
   direction/facing/placement, compare to expectation, report PASS/FAIL.
9. **Parametric rebuild rule:** change W=600,H=720,D=560,M=18 → W=750,M=16;
   everything (sides, bottom, back, shelf, door, hinge, drawer, runner, drilling,
   cut list, BOM, SketchUp, DXF) must update.

---

## 6. BUILD PHASES (bite-size, finish fast — user-approved order)

### PHASE 1 — KITCHEN BOXES (board, frameless EU → add face-frame USA)
Base: door / drawer bank (2/3/4) / sink / blind corner L-R / angled.
Wall: door / glass / hood (raised) / open-rack.
Tall: plain / glass / pantry / split-pantry / oven+micro+drawers.
Fronts: slab / MDF profile / 5-piece Shaker; face-frame (USA) w/ handles.

### PHASE 2 — WARDROBES (drawer boxes INSIDE)
Hanging (single/double) / internal drawer stack / pullout racks / split tall /
sliding 2-leaf / sliding+mirror / continuous robe bank / cover panels.

### PHASE 3 — CONNECTORS & ACCESSORIES
Minifix (flip Y / direction vector) / Confirmat / dowel / 32mm linebore /
shelf supports / undermount runners + bore guide / hinges (35mm) / closet rod +
sockets / sliding track + inserts / LED groove / wire hole / feet / edgebanding.

> Easy-to-bite first: rod positions, slider inserts, then connectors.

---

## 7. DELIVERABLES / OUTPUTS

- BOM (from model), cut list, edge list, machining list, hardware list.
- Workshop PDF report, technical cutting lists, nesting.
- **DXF export for CAM** — correct **layering** so CAM can read it
  (SHEET_BOARD_18MM, WIN_ROD, HW_CONN, per-user requirement).
- Install drawings.
- Grid/demo runners to visually validate construction.

---

## 8. USER GUIDANCE — PRINCIPLES (from the session, verbatim intent)

- "We start from others, stop and make it smart and all in one, period."
- "I'm guiding you for perfection. Not criticizing."
- "If you can do the dado, you can do the screw."
- "There is framed cabinets also with handles especially in USA, and slab door
  and profile doors — we need them too."
- "In Mozaik they make drawer boxes inside wardrobes, not how you imagined."
- "From the beginning the app should be smart enough to put a sense on the
  directions and where to place objects, maintain a math grid of coordinates of
  everything everywhere so nothing goes veered."
- "Connectors must be between a board joint, not in mid-seam. No point wasting by
  guesswork — study and make a matrix of the placement correctly."
- "You have to copy everything, learn from [the references]. Do not skip."
- "Are we doing connectors? ... handle pull is facing door, screws facing outside."
- "Gola wrong side, connectors came. If you can do dado you can do screw."
- "Read page by page and list out set of example boxes in each category — if we
  do perfect mini steps we can finish faster."
- "I can't see the sliding mirror... rod is not seen... these are not real boxes,
  construction errors are there. How a sliding rail suspend on air. How we hang
  clothes if rod is up front... [the PDF] links are here inside, please read
  first. Do not code, learn and stop, identify what we do mistakes here."
- Knowledge transfer from PDF to code must actually HAPPEN — read the file, extract
  the rule, implement it, verify. Never claim to know without reading.

---

## 9. THE KNOWLEDGE PACK (files in CabinexAi/knowledge/)

| File | Encodes |
|---|---|
| `cabinet_types.json` | Master box taxonomy (base/wall/tall/special) + corner subsystem |
| `hardware_rules.json` | Exact hinge + drawer formulas (GRASS/Blum/Hettich), lifts, sliding |
| `accessories.json` | Corner/base/tall/wardrobe accessories as occupancy envelopes |
| `wardrobe_rules.json` | PAX frames, organizers-INSIDE-frame, rod, sliding doors |
| `manufacturing_rules.json` | System 32, backs, plinth, materials, machining, cut list, QC |
| `methods.json` | Construction method switch + front geometry + reveal math |
| `elevation_composition.json` | THE missing layer: elevation composer, scoring, multi-candidate |
| `domain_model.json` | Architecture: domain tree, engines, study order, final exam |
| `connector_placement_matrix.json` | System32 + connector joint placement + Steelfix/Minifix/production spec |

**Reference PDFs** (in `CabinetrixAionline/references/`): Fabricating Cabinets
Learner Guide, IKEA METOD×3, PAX×2, Installation Requirements, Installing On-Site +
Heettich (TA_2016_01_en_DE.pdf, 1690pp), Blum, GRASS, Hettich/Kesseboehmer online.

**Production reference builders** (canonical — delegate, don't re-create):
- `sketchup/demo_ljoint_connections.rb` (Minifix/dowel/confirmat L-joint)
- `sketchup/gola_drawer_bank_minifix.rb` (Gola drawer bank w/ 16× Minifix)

---

## 10. NEXT STEPS (agreed direction)

1. Adopt production refs as canonical builders (done for grid).
2. Fix Gola orientation (done — flip Y to face front).
3. System 32 line-boring in the real carcase (engine panel-boring).
4. Wardrobe internal drawer boxes inside frame + rod on grid under top shelf.
5. Connector placement matrix → engine consumes it (direction-vector placement).
6. BOM + DXF layering for CAM (board/rods/connector layers).
7. Final study-order exam kitchen + wardrobe (see domain_model.json).
