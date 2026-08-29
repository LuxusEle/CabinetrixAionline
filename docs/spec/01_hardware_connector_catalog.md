# 01 — Unified Hardware / Connector / Accessory Catalog (v0.1)

**Purpose.** The single, deduplicated, vendor-merged catalog that the `CabinexAI`
engine consumes to machine real connectors, hardware, and accessories into board
kitchen + wardrobe + aluminum carcasses — *without losing any option from any
vendor*. This is the "combine all the goodness" spec.

**Sources (page-cited).** CabMaker Suite v11 (363pp), eCabinet Systems v5.2
(511pp), KCD v25 (25pp), Mozaik V7 Parameter Help (176pp), PolyBoard IV (28pp).

> **Design rule (from Mozaik p133):** connectors are **layered fastener
> templates**, up to **8 `JointFast` slots + 1 `PnlFast` (part template)** per
> construction method. Same template must not be picked twice
> (double-drill guard). We model exactly that.

---

## 0. Mental model

A *construction method* owns **joints**, **fasteners**, and **accessories**.
Each *joint* (top/side, back/side, etc.) resolves to a **fastener set**. Each
*cabinet/part type* resolves to a **panel template** (`PnlFast`). Front systems
and wardrobe internals are catalogued the same way.

```
ConstructionMethod
 ├─ Joints[]          -> JointFast[1..8]   (fastener templates per joint)
 ├─ PanelFasteners    -> PnlFast[]          (part template per base/wall/tall/wardrobe)
 ├─ FrontSystem       -> door/drawer + handle model
 ├─ WardrobeInternals -> rods, hangers, pullouts, dividers, slide
 └─ Accessories       -> LED, wire, adjusters, connectors, grippers
```

---

## 1. Joint taxonomy (from eCabinet p492 / Mozaik Bk* set)

| eCabinet term | Mozaik param | Meaning |
|---|---|---|
| Butt joint | (plain) | two panels edge to edge, no mechanical interlock |
| Dowel joint | `JointFast=Dowel` | holes in both panels + wooden/plastic dowel |
| Blind dado | `BkUE/Dadoed Into End`, `BKBlindDado` | a dado that does not pass through (setback) |
| Full dado | `Full Dado` | dado across whole edge, mating panel lengthened to fill |
| Qualified tenon | `Q Tenon` / `BKQDado` | interlocking tenon machined in nest |
| Puzzle joint | `Puzzle Joint` | jigsaw interlock, no screws/clamps |
| KD / RTA | `Confirmat`, `Minifix`, `Cam` | knocked-down ready-to-assemble hardware fasteners (eCabinet p492) |

**Mozaik joint-interface params captured (do not lose):**
- `BkUE` — Back / Unfinished End joint: `Plant On Back` · `Flush With Back` ·
  `Q Tenon` · `Blind Dado` (p86)
- `BkUEW` — Back / Unfinished End for **Wall** cabs (p87)
- `BkTB` — Back / Top joint: adds `Dado Top Into Back` (p88)
- `FinBKUE` — Finished Back / Unfinished End: `Mitred` · `Dadoed Into End` ·
  `Flush With End` (p99)
- `BKBlindDado` — blind dado setback (p94)
- `BKQDado` — qualified-tenon thickness (p95); backs machined **flipside**
- `BKPar` — dado partitions into back: YES/NO (p96)

---

## 2. Fastener library (connector templates)

### 2.1 Lamello / cam / confirmat / rafix / minifix (Mozaik p132-134, eCabinet p492)
| Fastener | Type | Use | Drilling notes |
|---|---|---|---|
| `Confirmat` | thread, screw | unfinished ends, KD | single stepped bore |
| `Minifix` | cam-lock + pre-inserted bolt | knocked-down joint | cam bore + bolt bore (10/15mm) |
| `Cam` (eCabinet) | cam-lock | KD | two holes: cam pocket + bolt |
| `Rafix` | connector | finished ends | two-bore system + dowel |
| `Dowel` | pin | alignment + strength (Mozaik `JointFast=Dowels`) | two align bores |
| `Q Tenon` | interlocks | back/end joints | flipside ops (Mozaik `QTenonFlip` p132) |

**Rule (Mozaik p133):** up to **8 `JointFast`** may be combined per method, e.g.
`Rafix` on finished ends + `Confirmat` on unfinished ends + `Dowels` on both.
Never repeat the same slot (double-drill guard).

### 2.2 Drawer running / coupling (CabMaker p66-68, Mozaik p54-58)
| Item | Params |
|---|---|
| Drawer box system | `Drawer System` on/off; `Drawer Box Material`; `Drawer Spacing N` |
| Drawer count/order | 0–6; `Auto Ht` (last drawer fills space); `Top Side by Side`; `Center` (middle front width) |
| Top drawer options (`sink`) | `Default` · `Tip Out Tray` · `Omit Drawer Front` |
| Stretcher | `MidStretcherW` width (Mozaik p55); `TopDrwStr`/`DrwStr` align `None/FlushTop/FlushBottom/Centered`; `DrwPartition` `None/Single/Double` |
| Undermount runner | (Blum/Hettich-style) — add `soft close`, `full extension`, `drill guide` for box bore |

### 2.3 Reveal / gap math (CabMaker p300-302) — authoritative
| Construction | Formula |
|---|---|
| Frameless **overlay** front height | `Spacing − DoorGap` (200−3 = **197**) |
| Frameless **inset** front height | `Spacing − 2×DoorGap` (200−6 = **194**) |
| Face-frame inset (full frame) | `Spacing − 2×DoorGap` = **194** |
| Face-frame inset (partial frame) | `Spacing − DoorGap` = **197** |

So a `door_gap` (default **3mm**) is the single authoritative reveal knob; engine
must apply it per construction.

---

## 3. Cabinet/part templates (Mozaik `PnlFast` + part attributes)

| Part type | Template target (Mozaik p134) |
|---|---|
| Base cabinet parts | Base template |
| Wall cabinet parts | Wall template |
| Tall cabinet parts | Tall template |
| Wardrobe parts | Wardrobe template (new) |
| Door / drawer front | Door/drawer template + `hole_spacing` h/w |

**Shelf / support holes** (CabMaker p47): `Cluster Size` = number of shelf
support holes per cabinet; `-1` = use CutMaster settings; `0` = off; `N` = count.

---

## 4. Wardrobe internals (CabMaker Options p47-55 — primary source)

> CabMaker gen: closet rods, pullouts, dividers, hangers — exactly the wardrobe
> "options" the user asked us to adopt + evolve.

| Option | Params (range / meaning) |
|---|---|
| **Closet rods** | 0–4 rods; first spacing measured **bottom of cabinet → rod center**; subsequent spacing rod-center → rod-center (p48) |
| **Rod from back** | horizontal position from back to rod center; `-1` = auto centre (p47) |
| **Fixed shelves** | count + optional override openings (first opening, between-shelf spacing) (p49) |
| **Adjustable shelves** | count + override openings; inherits prior value when 0 (p50) |
| **Pullouts** | count; override opening interval; `0` = use `Pullout Clearance` (p51) |
| **Pullout heights/depths** | per-pullout override; `0` = default (p52-53) |
| **Vertical dividers** | count; only when no drawers/shelves/pullouts; grid with horizontal (p54) |
| **Stretchers** | between drawers and doors; ≥1 required for Side-by-Side (p54) |
| **Hangers (nailers)** | `None` · `Top` · `Bottom` · `Both` · `Project` (p55) |

### Sliding / sliding-mirror sash (wardrobe signature — new)
- Top/bottom **track** (u-channel C/U profile) × 2 sliding sash leaves minimum.
- **Sliding sash** = extruded sash frame 45° miter (reuse `build_sash_assembly`),
  infill = 3mm ACP, mirror panel, or glass. Mirror uses the same sash with a
  mirror-material infill block (paintable + protective film layer).
- Overlap need: each lead overlaps front plane so leaves ride front/back track.

---

## 5. Hinge + handle (CabMaker p61, 285-286, Mozaik p54)
| Item | Params |
|---|---|
| Hinge positions | [hinge1..hingeN] heights on stile |
| Hinge allowance / angle | clearance, opening angle, return adjust (p207-209) |
| Base/upper door style + handle | `Base Door Style`, `Base Handle`, `Upper Door Style`, `Upper Handle` |
| Handle offset | L/R handed doors |
| Horizontal handles | on/off + `Offset` (p286) |
| Door handle side | :opening/:left/:right (engine `door_handle_side`) |

---

## 6. Accessories (LED / wire / plumbing — user's "LED grooves, wire holes")

| Accessory | Geometry the engine must cut/route |
|---|---|
| **LED groove** | top/vertical routed groove (e.g. 6×12mm) with diffuser channel for under-cabinet + glass-cabinet strip |
| **Wire hole** | rear/mid vertical 8–10mm pass-through hole in sides/back for wiring |
| **LED driver pocket** | optional concealed box space near top |
| **Adjustable feet / levelers** | plinth adjuster sockets (base) |
| **Spacer / gripper** | shelf front anti-tip |
| **Chamfer / routing** | edge chamfers + miter (cabinet edges still painted in SketchUp via `paint_black_edges`) |

---

## 7. Construction methods map (nothing lost)

| Method id | Carcase | Front | Connect | Notes |
|---|---|---|---|---|
| `BOARD` | melamine 18mm board | slab / sash | Dowel + Cam (KD) or Confirmat | board kitchen (primary) |
| `BOARD_WARDROBE` | melamine 18mm | hinged sash + sliding/mirror sash | cam/dowel | wardrobe internals + track (primary) |
| `ALUMINUM` | BoxBar 25.4mm extrusion | 45° sash + 3mm ACP | box-bar joint + Gola | moat, retained |
| `ALUMINUM_ECONOMY` | economy full-frame | sash | bar-corner | retained |

> **Design guardrail.** Carcase-resolver stays separate from the connector set.
> Aluminum box-bar joints are *not* `Dowel/Cam` — they use bar-corner / bar-tee.
> The catalog is per-method, no cross-contamination.

---

## 8. Next artifacts (this spec feeds these)
- `02_catalog_schema.md` — the typed Ruby/JSON data structures + loader.
- `03_engine_scaffold.md` — where the catalog plugs into `CBXHybridEngine`
  (`em_method`, `resolve_connectors`, `build_wardrobe`).
- `04_planner_routing.md` — widening `kitchen_type` whitelist + orchestration.
