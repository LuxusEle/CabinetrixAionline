# 05 — Box Examples By Phase (bite-size build order)

**Purpose.** The exact example boxes to build, in mini-steps, organized by the
3 phases the user chose: **1) Kitchen boxes → 2) Wardrobe boxes → 3) Connectors/
accessories.** Each step is small enough to finish, test, and move on — the
"perfect mini steps" approach. Grounded in the vendor PDFs and corrected for the
real-world pattern that **drawer boxes go INSIDE wardrobes** (Mozaik/eCabinet),
not just shelf fronts.

**Sources.** Mozaik p17-18 (6 construction methods), p135-137 (32mm linebore
base/wall/tall), p162-163 (ClosetThruBore, ClosetRodPosition), p173 (edgeband
template); eCabinet p417-420 (door taxonomy: MDF / Slab / 5-Piece), p413 (Lazy
Susan), p446 (centers/heights); CabMaker p43 (types), p47-55 (closet rods /
pullouts / hangers / dividers), p66-68 (drawers).

---

## 0. Construction methods (Mozaik `Const`/`ConstW`/`ConstT` — p17/18)
Every box is built under ONE of these; this is the master switch, NOT a separate
geometry set:

| Method | Type | Front | Handle | Market |
|---|---|---|---|---|
| `frml` **Frameless** | box | overlay slab/sash | — | EU board |
| `32mm` | frameless + linebore | overlay, hardware on 32mm grid | — | EU |
| `ff` **Face Frame** | framed | overlay | visible handle | USA |
| `ff_full_overlay` | framed | full-overlay (EU look) | — | USA/EU |
| `ff_inset` | framed | doors inset flush into frame | visible | USA upper |
| `frml_inset` | frameless | fronts inset flush | — | EU inset |

> `Const` also sets **edgebanding** (Mozaik p173: up to 4 bandings — box parts,
> doors/drawer fronts, drawer box parts) and **dado/tenon** joints.

---

## PHASE 1 — KITCHEN BOXES (board, frameless EU first; then add face-frame USA)

### 1.1 Base boxes
| # | Box | Build | Test |
|---|---|---|---|
| 1 | Standard base — 2 overlay doors | `build_base_cabinet(subtype: :door)` | ✔ built |
| 2 | Base drawer bank (2/3/4) | `build_base_cabinet(subtype: :drawers)` | ✔ built |
| 3 | Base drawer stack ×2 adjoining (Gola combine) | `build_run` contiguous | ✔ built |
| 4 | Sink base (false front + doors) | `build_base_cabinet(subtype: :sink)` | ✔ |
| 5 | Right/Left blind corner | `build_board_blind_corner` | ✔ |
| 6 | Angled base (corner) | `build_board_angled_base` | ✔ added |
| 7 | **Frameless inset sink/oven front** | base + frml_inset | NEW |

### 1.2 Wall boxes
| # | Box | Build | Test |
|---|---|---|---|
| 8 | Wall cabinet — overlay doors | `build_board_wall` | ✔ |
| 9 | Wall w/ glazed glass door | wall + sash | ✔ |
| 10 | Cooker-hood wall (raised 6in) | wall + hood | ✔ |
| 11 | Open-rack wall | wall + open_rack | ✔ |

### 1.3 Tall boxes
| # | Box | Build | Test |
|---|---|---|---|
| 12 | Plain tall (doors/covers) | `build_tall_cabinet` | ✔ |
| 13 | Tall w/ glass sash | tall + sash | ✔ |
| 14 | Tall pantry (5 shelves) | `build_board_pantry` | ✔ added |
| 15 | Split pantry | pantry (top/bottom) | NEW |
| 16 | Tall oven + microwave + drawers | `build_board_tall_oven` | ✔ |
| 17 | Tall oven + glass top door | oven + glass | ✔ |

### 1.4 Face-frame (USA) door fronts — NEW
| # | Box | Build | Test |
|---|---|---|---|
| 18 | Slab door (flat + edgeband) | `build_door_front(system: :slab)` | NEW |
| 19 | MDF profile door (machined) | `build_door_front(system: :mdf_profile)` | NEW |
| 20 | 5-Piece / shaker door (stile+rail) | `build_door_front(system: :shaker)` | NEW |
| 21 | Face-frame stile+rail + hinge mount | `build_face_frame` | NEW |

---

## PHASE 2 — WARDROBE BOXES (corrected: drawer boxes INSIDE the robe)

> Real pattern (Mozaik/eCabinet/CabMaker): a wardrobe is a **tall box** whose
> interior is split into **hanging zone** (rod + upper shelf) and **storage
> zone** (stack of internal drawer boxes or adjustable shelves) — all BEHIND
> the doors. The rod is placed by **ClosetRodPosition** (Mozaik p163: distance
> from rod top to opening top) and rods are **thru-bored / linebored** on the
> 32mm system (Mozaik p162 `ClosetThruBore`).

| # | Robe | Interior layout | Build | Test |
|---|---|---|---|---|
| 22 | Hanging robe | rod + top shelf (single/double hang) | `build_wardrobe(door: :hinged, rods: 1, top_shelf: true)` | ✔ |
| 23 | Robe + **internal drawer stack** | 3-5 internal drawer boxes between shelves | `build_wardrobe(drawers: 3, internal: true)` | FIX |
| 24 | Robe + pullout racks | wire/laundry pullouts | `build_wardrobe(pullouts:)` | NEW |
| 25 | Split tall wardrobe | double-hang upper + lower rods | `build_wardrobe(rods: 2, stacked: true)` | NEW |
| 26 | Sliding 2-leaf robe | top/bottom track | `build_wardrobe(door: :sliding)` | ✔ |
| 27 | Sliding + mirror leaf | mirror infill | `build_wardrobe(door: :sliding, mirror: true)` | ✔ |
| 28 | Continuous robe bank | merged plinth / shared covers | `build_wardrobe_run` | ✔ |

**FIX NEEDED:** the internal drawer boxes currently sit at Z≈120mm tall front
heights but with a rod layout that doesn't match a real robe. Correction: a robe
is vertical-hang (rod at ~1700mm below a 2400 o/h) then a base storage zone with
**drawer boxes inside** — implement `internal: true` so drawers are built
INSIDE (behind the door plane) nested between shelves, per Mozaik/eCabinet.

---

## PHASE 3 — CONNECTORS & ACCESSORIES (bite the easy rod/slider parts first)

> Partly done (catalog `01`, schema `02`). Remaining geometry/machining.

### 3.1 Connectors (Mozaik `JointFast 1-8` + `PnlFast`)
| # | Item | Placement |
|---|---|---|
| 29 | Minifix cam + bolt (KD) | end-panel → top/bottom (cam pocket 10/15mm + bolt bore) |
| 30 | Confirmat screw | unfinished ends |
| 31 | Dowel pair | all joint lines |
| 32 | 32mm linebore | shelf hole lines on ends/partitions (Mozaik p135-137) |
| 33 | Shelf support holes | 1/3/5/7 holes per shelf (Mozaik p136) |

### 3.2 Accessories
| # | Item | Placement |
|---|---|---|
| 34 | Undermount drawer runners + bore guide | internal drawer boxes (soft-close/full-extension) |
| 35 | Hinges + hinge holes | framed/frameless door front |
| 36 | **Closet rod + rod sockets** | rod at ClosetRodPosition (p163) |
| 37 | **Sliding track + slider inserts** | top/bottom u-channel, wheel inserts (the parts you see in the image) |
| 38 | LED groove | under-top / glass box |
| 39 | Wire hole | rear vertical pass-through |
| 40 | Edgebanding (Banding 1-4, p173) | map to part edges |

---

## 3. The bit-size plan (finish fast)
1. **Kitchen boxes** already largely build (see ✔ list) → verify in matrix.
2. **Wardrobe**: fix internal drawers (#23), then rod position (#36) & slider
   inserts (#37) — the "easy to bite" parts.
3. **Connectors** (#29-33) after geometry is stable.
4. Add **edgebanding + face-frame** (#21, #40) last.
