# 04 — Unified Box / Cabinet-Type Catalog (the boxes our app builds)

**Purpose.** The authoritative, vendor-merged list of every box/cabinet type the
master engine must build, grounded in the reference PDFs. This is the "list of
boxes they explain" mapped to the builders we already have (or must add). Every
box is described once; construction method (board/aluminum) and connectors come
from the catalog, never duplicated per type.

**Sources.** CabMaker v11 (p43 Cabinet Type/Style, p127 Tall configs, p133-153
Mid section / oven / closet / pantry), eCabinet 5.2 (Catalog + corner/lazy-susan
p298-414), Mozaik V7 (cabinet/shelf params p47-84, backs p84), KCD v25 (library
sets: frame / frameless / overlay-frame / closet, p4).

---

## 1. Primary split (CabMaker p43 — Base vs Upper, 10 styles)

| Group | Styles (CabMaker) | Our builder |
|---|---|---|
| **Base** | Standard · Sink · Angled · Return · Left Blind · Right Blind · Angled Sink · Angled Left End · Angled Right End · Fridge | `build_base_cabinet` / `build_board_blind_corner` / `build_board_tall_oven` |
| **Upper (wall)** | Standard · Angled · Return | `build_board_wall` (board) / `build_aluminum_top_cabinet` (alu) |
| **Tall** | Standard · Tall configurations | `build_tall_cabinet` (plain) / `build_board_tall_oven` (oven) / `build_wardrobe` (robe) |

---

## 2. Full box-type list (with intended construction)

### BASE BOXES (board kitchen primary)
| Id | Box | Notes / vendor source | Engine builder |
|---|---|---|---|
| BASE_DOOR | standard base, 1–2 leaf doors | CabMaker Standard | `build_base_cabinet(subtype: :door)` |
| BASE_DRAWER | base drawer bank (2/3/4) | CabMaker Drawers p66-68; undermount runners | `build_base_cabinet(subtype: :drawers)` |
| BASE_DRAWER_STACK | 2 drawer boxes in a row (Gola combine test) | our self-exercise | `build_run` contiguous |
| BASE_SINK | sink base (false front + doors) | CabMaker Sink / `sink` | `build_base_cabinet(subtype: :sink)` |
| BASE_BLIND_L | left blind corner (one-sided) | CabMaker Left Blind; eCabinet corner | `build_board_blind_corner(blind_side: :left)` |
| BASE_BLIND_R | right blind corner | CabMaker Right Blind | `build_board_blind_corner(blind_side: :right)` |
| BASE_ANGLED | angled base (angled front) | CabMaker Angled / Angled Sink | NEW `build_board_angled_base` |
| BASE_RETURN | return base | CabMaker Return | NEW `build_board_return_base` |
| BASE_RACK | open rack / pullout base | our open-rack | `build_board_wall(open_rack: true)` reuse |
| BASE_FRIDGE | fridge housing | CabMaker Fridge | NEW `build_board_fridge_tall` |

### WALL / UPPER BOXES
| Id | Box | Source | Builder |
|---|---|---|---|
| WALL_DOOR | wall cabinet, doors | Mozaik Wall | `build_board_wall` |
| WALL_GLASS | wall w/ glass/glazed door | our glass sash | `build_board_wall` + sash |
| WALL_HOOD | cooker hood wall (shortened/raised 6in) | our hood bay | `build_board_wall(hood: true)` |
| WALL_RACK | open-rack wall | our open rack | `build_board_wall(open_rack: true)` |
| WALL_ANGLED | angled wall/return | CabMaker Return | NEW |

### TALL BOXES
| Id | Box | Source | Builder |
|---|---|---|---|
| TALL_MDF | plain tall (doors/covers) | CabMaker Tall | `build_tall_cabinet` |
| TALL_GLASS | tall w/ glass sash door | our inset sash | `build_tall_cabinet` + sash |
| TALL_PANTRY | full pantry (shelves full height) | CabMaker Full Pantry p127/136 | NEW `build_board_pantry` |
| TALL_SPLIT_PANTRY | split pantry (top/bottom) | CabMaker Split Pantry | NEW |
| TALL_OVEEN | oven + microwave + drawers | CabMaker Oven p127/152 | `build_board_tall_oven` |
| TALL_CLOSET | tall closet | CabMaker Full Closet p136 | `build_wardrobe` (hinged) |

### WARDROBE / CLOSET BOXES (the robe set)
| Id | Box | Source | Builder |
|---|---|---|---|
| ROBE_HINGED | robe w/ hanging → hinged sash | CabMaker Closet; our robe | `build_wardrobe(door: :hinged)` |
| ROBE_SLIDING | robe w/ 2-leaf sliding sash | our sliding track | `build_wardrobe(door: :sliding)` |
| ROBE_MIRROR | robe w/ sliding mirror sash | our mirror infill | `build_wardrobe(door: :sliding, mirror: true)` |
| ROBE_RODS | hanging rods + drawers + shelves | CabMaker Closet Rods p48 / Pullouts p51 / adj shelves | `build_wardrobe(rods:, drawers:, shelves:)` |
| ROBE_DRAWERBANK | robe drawer bank | CabMaker Drawers | `build_wardrobe(drawers:)` |
| ROBE_RUN | continuous robe bank (merged plinth) | our robe run | `build_wardrobe_run` |

### CORNER / SPECIAL (eCabinet p298-414)
| Id | Box | Source | Builder |
|---|---|---|---|
| CORNER_LAZYSUSAN | lazy-susan corner | eCabinet Lazy Susan p413/493 | NEW `build_board_lazy_susan` |
| CORNER_BLIND | blind corner (door + blind divider) | CabMaker / eCabinet corner | `build_board_blind_corner` |
| CORNER_TPLIND | top blind return | our top blind | `build_board_wall` + return |

---

## 3. Construction-method matrix (nothing duplicated)

| Box group | BOARD (kitchen) | BOARD_WARDROBE | ALUMINUM |
|---|---|---|---|
| Base straight | board carcase + cam/dowel | — | BoxBar run |
| Base corner | blind corner (board) | — | aluminum L tunnel |
| Wall | board wall | — | aluminum top |
| Tall plain | `build_tall_cabinet` | — | aluminum anchored tall |
| Oven tall | `build_board_tall_oven` | — | — |
| Robe | — | `build_wardrobe` | — |

> **Guardrail.** A box type never re-implements geometry for a method — it calls
> the method's carcase builder and reads connectors from `CBXCabinetMethod`.
> Adding a new box = one builder + one matrix row, not new connector work.

---

## 4. Gaps to implement (NEW builders flagged above)
`build_board_angled_base`, `build_board_return_base`, `build_board_fridge_tall`,
`build_board_pantry`, `build_board_split_pantry`, `build_board_lazy_susan`.
Plus the planner routing (Phase 2) that reaches any of these from `kitchen_type`.

---

## 5. Why use this list (instead of "just a few boxes")
This is the same reason incumbents (CabMaker/eCabinet/KCD/Mozaik) win on 3D
confidence: they enumerate every real carton a shop builds, so a designer never
hits "type not found." By mapping each to an engine builder + method connector,
we get completeness without re-writing connector/hardware logic per box.
