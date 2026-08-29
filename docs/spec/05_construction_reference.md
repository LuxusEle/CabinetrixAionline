# 05 — Construction Reference (authoritative rules, replaces assumption-based file)

**Why this exists.** Every value below is drawn from the actual references we
downloaded/read, NOT from assumption. This is the gospel the box engine must
follow. Supersedes `05_box_examples_by_phase.md` (which was assumption-based).

**Provenance (all read in this project):**
| Source | What it gives us |
|---|---|
| `references/Fabricating_Cabinets_Learner_Guide.pdf` (LMFKB3005A, 64pp) | carcase structure, System 32, plinth, door, drawer, assembly |
| `references/IKEA_METOD_Cabinets_Planning_Guide.pdf` (20pp) | METOD module sizes (widths/HEIGHTS/DEPTHS), drawer/shelf part nos |
| `references/IKEA_METOD_Kitchen_Installation_Guide.pdf` (12pp) | suspension rails, wall-first install, fillers, drawer-rail order |
| `references/IKEA_METOD_Base_Cabinet_Assembly.pdf` (24pp) | base box exploded assembly |
| `references/IKEA_PAX_KOMPLEMENT_Planning_Guide.pdf` (20pp) | PAX frame sizes, KOMPLEMENT drawers/rods/shelves inside, sliding doors |
| `references/IKEA_PAX_Wardrobe_Frame_Assembly.pdf` (24pp) | robe frame assembly |
| Blum catalogue (live web) | hinge 35mm cup/3mm edge, 110°/155°, TB drilling dist, 32/32 grid, 37/32+20/32 plates, LEGRABOX/TANDEMBOX/MOVENTO |
| GRASS Movement Systems 2026 (live web) | **exact drawer formulas** (EB=29/30, BB=LWK−2EB, BL=NL−19, H63/90/122/186/250) |
| Mozaik, CabMaker, eCabinet (project PDFs) | Const/method switch, ClosetRodPosition, door taxonomy, joint fasteners |

---

## 1. CARCASE — the box (LMFKB3005A p54)

A frameless floor cabinet =
- **back** (external back is the common method),
- **base**,
- **two ends**,
- **two rails** (front rail + back rail to fix the bench top; front rail sometimes
  turned ON EDGE for sink/hob).

> Our current builder omits the **rails** and uses a grooved **MDF back**.
> **Fix:** add front+back rails; default to external back; rail-on-edge when sink/hob.

**Board:** 16mm white melamine particleboard (whiteboard) is standard for
carcase + drawer box. MDF for doors/backs of quality jobs. (LMFKB3005A p54, p60)

---

## 2. SYSTEM 32 (LMFKB3005A p52)

> rows of **5mm holes** drilled into the internal faces of **all vertical
> panels**, spaced at **32mm centres**. Holes house drawer runners, catches,
> hinges and adjustable shelf supports.

**Fix:** every vertical end/partition gets a System 32 line-bore (5mm holes at
32mm pitch) on the 32mm grid. Rods, shelves, drawers, hinges must sit ON grid.
Grid axis begins from a datum (typically set from cabinet base/recess).

---

## 3. PLINTH & BASE (LMFKB3005A p53, METOD p13)

- **Ladder-frame base**: made of particleboard/MDF, nailed/stapled/screwed,
  **cross-supports notched at the bottom** for uneven floors. Installed
  on-site full-length along the wall, leveled, THEN cabinets sit on it.
- **Legs** (METOD p13): CAPITA / METOD leg **8 cm**; hidden behind plinth or
  exposed.

**Fix:** model a **separate plinth/base frame** (not a plinth panel) + optional
8cm legs.

---

## 4. DRAWER — exact formulas (GRASS Nova Pro Scala + LMFKB3005A p60)

Drawer = open box, **front + back + sides in 16mm PB + MDF/hardboard base**,
**12–13mm free space each side for runners**, separate drawer front.

GRASS formulas (all mm):
| Symbol | Meaning | Formula |
|---|---|---|
| LWK | inside cabinet width | input |
| NL | nominal (slide) length | input |
| EB | **installation width** | **29 (S16/S19) or 30 (S18)** |
| BB | bottom panel width | `LWK − 2 × EB` |
| BL | bottom panel length | `NL − 19` |
| RWB | back panel width | `BB` (or BB−16 / BB−84 for H186/250) |
| RWH | back panel height | `RW` slide height + 10 |

Standard drawer heights: **H63 / H90 / H122 / H186 / H250**. 16mm chipboard,
Ø 3.5×15 screws, Ø 10×12/13 dowels. Front–bottom connector at KB ≥ 800.

> **Fix:** our drawer used 18mm box + 6mm reveal. Must be **16mm box**,
> **EB=29/30mm**, 5 standard heights, correct BB/BL/RWB.

---

## 5. DOOR / FRONT (LMFKB3005A p58-59, Blum)

- Concealed cup hinge: **35mm cup**, cup edge **3mm** from door edge, mounting
  plate on carcase, **1mm gap** between door and cabinet.
- Blum: 110° / 155° / 107° hinges; **drilling distance TB** (table); mounting
  plate spacing **37/32** and **20/32** (grid-aligned); 32/32 grid.
- Door taxonomy (eCabinet p417-420): **Slab** (flat + edgeband), **MDF profile**
  (machined), **5-Piece/Shaker** (stile & rail).
- Construction methods (Mozaik p17): Frameless, 32mm, Face Frame, Full Overlay,
  Frame Inset, Frameless Inset.

---

## 6. WARDROBE / CLOSET (PAX + Mozaik)

- **Frame**: tall box, standard sizes — PAX widths **50/75/100cm**, depths
  **35/58cm**, heights **201/236cm**.
- **Interior organizers are INSIDE the frame** (KOMPLEMENT): drawer stacks,
  shelves, shoe shelves, pull-outs, hanging rod. Sizes match frame inner
  width/depth. They sit **behind** the door plane.
- **Rod**: positioned by **ClosetRodPosition** (Mozaik p163 = distance from rod
  top to opening top); clothes hang below a **top shelf** (structural).
- **Sliding doors** (PAX p8-9): sold in pairs, metal frame + panels, aluminum
  frame; leaves ride a track with soft-close.

**Fix:** drawer boxes/rods/shelves = separate interior organizers sized to frame
inner dims, behind doors; rod = under structural top shelf on grid.

---

## 7. INSTALL MODELS (METOD p5-10)

- **Suspension rails** for base and wall cabinets, leveled pre-hang.
- **Wall cabinets first** (except single-line with high cabinet → high first).
- **Filler pieces** at walls; support strip to hold filler.
- **Drawer rails fitted to carcase before doors/shelves.**

---

## 8. METHOD SWITCH (Mozaik `Const`/`ConstW`/`ConstT`)
One master switch per box (NOT separate geometry): Frameless / 32mm / Face
Frame / Full Overlay / Frame Inset / Frameless Inset; plus edgebanding template
(Banding 1-4) and dado/tenon joints.

---

## 9. CONNECTORS (LMFKB3005A p50-52, Mozaik JointFast)
- **Butt + screws** (chipboard screws) — most common.
- **Dowel + cam fitting** (KD / knock-down) — System 32 homes these.
- System 32 = dowel+cam standard, pre-machined.

---

## 10. The build order this mandates
1. **System 32** (5mm/32mm grid) as the foundation → all placement snaps to it.
2. **Real carcase**: back + base + 2 ends + **2 rails**.
3. **Ladder-frame base + 8cm legs** (separate member).
4. **Drawer formulas** (16mm, EB=29/30, H63-250, BB/BL/RWB).
5. **Doors**: cup hinge 35mm/3mm edge/1mm gap; slab/MDF/5-piece; method switch.
6. **Wardrobe interior organizers** inside frame behind doors; rod under top
   shelf on grid.
7. **Connectors**: dowel+cam placed by System 32.
