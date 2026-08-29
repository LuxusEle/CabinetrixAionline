# Cabinetry Knowledge Pack

Machine-readable construction knowledge for the **CabinexAI** master cabinet
engine and its coding agent. These JSON files encode REAL cabinetry rules drawn
from the references we downloaded and read — so the engine consumes knowledge
directly instead of re-interpreting manuals.

> **Purpose.** You (the coding agent) must NOT re-derive cabinet math or invent
> dimensions. Load these files, read the rules, and drive every geometry decision
> from them. Anything you can't map to a rule here means the pack needs a new
> entry — add it, don't guess.

## Files

| File | What it encodes | Source |
|---|---|---|
| `cabinet_types.json` | Master box taxonomy (base/wall/tall/special) + corner subsystem | METOD, PAX, LMFKB3005A, Mozaik |
| `hardware_rules.json` | **Exact** hinge + drawer formulas (GRASS Nova Pro Scala, Blum), lift systems, sliding doors | Blum, GRASS, Hettich |
| `accessories.json` | Corner/base/tall/wardrobe accessories as occupancy envelopes | Kessebohmer, Blum, METOD, KOMPLEMENT |
| `wardrobe_rules.json` | PAX frame families, interior-organizers-INSIDE-frame, rod, sliding doors | PAX/KOMPLEMENT, Mozaik, TopLine XL |
| `manufacturing_rules.json` | System 32, backs, plinth, materials, machining, cut list, install, QC | LMFKB3005A, Blum, GRASS, METOD install |
| `methods.json` | Construction method switch (frameless/32mm/face frame/inset) + front geometry + reveal math | Mozaik Const, CabMaker reveal, eCabinet doors |
| `elevation_composition.json` | **ELEVATION COMPOSER** — the missing layer ABOVE the cabinet engine: hard/soft constraints, axes, focal groups, modular widths, drawer tiers, scoring, multi-candidate solve | Blum Configurator, IKEA METOD, NKBA |
| `domain_model.json` | Architecture: domain tree, collision + compatibility engines, BOM/cut-list, plug-in hardware, 6-week study order | Level 34–42 |

## Architecture — three layers (in build order)
```
1. ELEVATION COMPOSER   (elevation_composition.json)
     solves the wall: anchors -> axes -> groups -> candidates -> score
2. CABINET RULE ENGINE  (cabinet_types.json, methods.json, manufacturing_rules.json)
     turns each module into a real carcase + fronts + hardware
3. HARDWARE / ENGINE    (hardware_rules.json, accessories.json, wardrobe_rules.json)
     places exact hinges/drawers/connectors by System 32
```
The Composer produces balanced candidate elevations; the cabinet engine builds
them; only then is hardware placed. Never start from "draw some boxes."

## The reference PDFs (in `CabinetrixAionline/references/`)
Fabricating Cabinets Learner Guide (64pp), IKEA METOD (x3), IKEA PAX (x2),
Installation Requirements (48pp), Installing On-Site (61pp). Plus Blum / GRASS /
Hettich / Kessebohmer online catalogues.

## Core mental model
```
ROOM -> RUN -> CABINET -> OPENING -> COMPONENT -> HARDWARE -> MACHINING
```
NOT `ROOM -> DRAW SOME BOXES`. See `cabinet_types.json#mental_model`.

## Non-negotiable rules (minimum for a valid cabin, per these files)
1. **System 32** (manufacturing_rules.json): 5mm holes at 32mm pitch in all
   vertical panels; rods/drawers/hinges/shelves snap to grid. This is the
   coordinate system for interiors.
2. **Real carcase**: back + base + two ends + **two rails** (front rail on edge
   for sink/hob).
3. **Drawer formulas** (hardware_rules.json): EB=29/30, BB=`LWK-2*EB`,
   BL=`NL-19`, 16mm box, heights H63/90/122/186/250. Never hard-code a drawer.
4. **Wardrobe interior organizers INSIDE the frame**, behind door plane; rod
   UNDER a structural top shelf, on grid.
5. **Plinth** = ladder-frame / 8cm legs — not a panel.
6. **Hinges**: 35mm cup, 3mm edge, 1mm gap; mounting plates on 37/32/20/32 grid.
7. Materials are independent (changing 18->16 must propagate everywhere).

## Domain objects to keep SEPARATE (never confuse)
`CABINET / CARCASS / FRONT / PANEL / OPENING / HARDWARE / ACCESSORY / APPLIANCE /
MACHINING / MATERIAL`. A door is not a cabinet; a drawer is not a front; a Gola
profile is not decoration; a LeMans is not an image.

## Parametric rebuild rule (final test)
Change base cabinet W=600,H=720,D=560,M=18 to W=750 then M=16 — everything
(sides, bottom, back, shelf, door, hinge relation, drawer, runner, drilling,
cut list, BOM, SketchUp model, DXF) must update. If it breaks, architecture is
wrong.

## How to extend
Add a new box/hardware/accessory by adding an entry to the matching JSON, then
make the engine render it. Never add a box type by duplicating connector or
hardware code.
