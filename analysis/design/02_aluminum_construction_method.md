# 02 — Aluminum Construction Method (the Moat)

**The single most valuable thing to build.** Every incumbent (CabMaker, eCabinet,
KCD, Mozaik, PolyBoard) optimises **panels** for board/wood. Cabinex builds an
**extrusion** product — BoxBar carcase, 3mm ACP cladding, 45° sash, Gola/handle.
That difference is our moat *only if* it is expressed as a reusable, inheritable,
deterministic **construction method**, not hand-tuned globals inside one engine file.

> Existing seed: `cbx_hybrid_planner.html` Step 3 "Project Global Settings"
> (construction logic, bar-to-carcase mapping, profile measurements). This document
> promotes that flat config into a first-class, versioned, inheritable **Method**.

---

## 1. What a Method must own (aluminum-native)

The analogy is Mozaik's parameter model and PolyBoard's "Méthodes/Sous-méthodes"
(material, edge, retrait/débord, usinage), but the objects are **aluminum parts and
profiles**, not board dados.

| Group | Cabinetrix Method owns |
|-------|------------------------|
| **Carcase system** | BoxBar structural vs Economy full-frame vs cladding-skin; box-bar section (25.4mm); stock length (6400mm); bar split policy |
| **Members** | rails, uprights, struts, shelf rails; front/back pairs; U-cut positions for horizontal skins |
| **Skin/cladding** | 3mm ACP thickness; rear-plane seating; push/pull clearance notches; tunnel bridges at blind returns; hood-bay omission |
| **Front system** | sash 45° miter, sash section, infill type (3mm ACP / glass), lip reveal, mullion, panelized ends |
| **Handle/Gola** | Gola profile (J/C), inverted-L handle section (default 24×32), pull positions, gap between mate |
| **Joint type** | bar-corner, bar-tee, miter, box-bar-to-strut; ACP notch-clearance, end-cap |
| **Hardware/marks** | hinge cup markers, screw linebore (aluminum tap points), handle drill, hinge-box override |
| **Reveal topology** | intrinsics, pair gap, between-mate, adjacent-cabinet, filler, applied end, unfinished/finished end |
| **Toe/base** | base bottom frame (38.1mm) is the base; no duplicate plinth; continuous vs ladder toe |
| **Corners** | L joins = one-sided blind corner; top blind return = top depth + 25mm; fillers/scribes |

---

## 2. Method schema (the object)

```text
ConstructionMethod {
  id            : MethodId          // immutable, e.g. "M-ALU-FULL"
  version       : int               // append-only
  owner_scope   : Organization | Shop
  inherits      : MethodId?          // chain to a base shop method
  carcase       : CarcaseSystem { type: BoxBar|Economy, bar: 25.4mm, stock: 6400mm }
  cladding      : Cladding { panel: 3mm, rear_seat: exposed|on-rail, notch: U, tunnel: bool }
  front         : FrontSystem { sash_section, miter: 45deg, infill: ACP|Glass, lip_reveal }
  handle        : Handle { gola: J|C, section: {w:24, d:32}, gap_to_mate, pull_positions[] }
  joints        : [JointRule]        // types + clearances + end_caps
  hardware      : Hardware { hinge_cup: {size,backset}, tap_linebore: {...}, handle_drill }
  reveals       : RevealMap { top, bottom, side_unfinished, side_finished, mid,
                              pair_gap, adjacent, filler, applied_end, inset }
  toe           : Toe { mode: base_frame|continuous|ladder_detached, ht, recess, miter }
  corners       : Corner { junction: one_sided_blind, top_return_off: +25mm, return_depths{} }
  allowed_overrides : [PropertyRef]  // deepest scope each property may be set at
}
```

### 2.1 Reveal topology — mirrors Mozaik's `FLRev*` set
CabMaker/Mozaik model face-frame and frameless reveals on **board** fronts.
Aluminum sash has the **same topology**; we map it to sash instead of stile/rail.
`top / bottom / side-unfinished / side-finished / mid(meet) / pair-gap /
adjacent-cabinet / filler / applied-end / inset`. `pair_gap` is per-pair and the
final gap = 2×`adjacent` when two cabinet fronts meet (Mozaik's `FLRevC` rule).

### 2.2 Handless / Gola — directly from CabMaker "Handless Extrusions"
CabMaker already has `J Profile`, `C Profile`, `Gaps`, `Notch Positions`,
`Calculate Notches`, `Gaps at Notch`. These are the exact primitives for the
aluminum Gola + inverted-L handle. Borrow the **notch math** so a continuous Gola
run splits cleanly at stack boundaries and stock length with zero web waste.

### 2.3 Inheritable + versioned
Shop **base Method** → project → room → run → cabinet → part/edge **override**.
Any `allowed_overrides` breach is rejected by the engine (same guard Cabinex already
uses for top-Z alignment of wall rows).

---

## 3. Method instance example (what a shop actually saves)

```text
Cabinex-Method "LKR Standard Aluminum Kitchen" v3 (auth: asank)
  carcase : BoxBar 25.4mm, stock 6400mm, split_at_junction=true
  cladding: ACP 3mm, rear_seat=on_rear_rail, notch=U_pushpull(clear 0.5mm),
            tunnel_bridge at blind returns=true
  front   : sash 45-deg, section SASH_T6, infill=ACP|Glass toggle,
            lip_reveal=3mm, mullion=none, panelized_end=false
  handle  : gola=J, section 24x32, gap_to_mate=3mm, pulls=[top,dual]
  reveals : top=3, bottom=3, side_fin=0, side_unfin=0, mid=3,
            pair_gap=3, adjacent=3, filler=0, applied_end=3, inset=3
  toe     : mode=base_frame (38.1mm box-bar floor frame), no_plinth_cover=true
  corners : junction=one_sided_blind, top_return_off=+25mm,
            base_return_depth=625, top_return_depth=375
```

---

## 4. Why this is the moat (not just an improvement)

1. **No incumbent can drop this in.** Their geometry/machining is panel-based; a
   BoxBar extrusion aluminium system is a different engine. We already have it.
2. **It composes.** One Method + wall graph + module list = every kitchen run.
   Add a cabinet template, not new code.
3. **It is answerable by AI.** A typed `set_method` / `set_option` on a named scope
   is both manageable and **deterministically validateable** (Pillar 5).
4. **Shop rule reuse becomes the retention product.** Proven aluminium
   construction/materials/handle bundles become reusable templates (roadmap §20).

---

## 5. What to build first (aluminium-first, not board-first)

1. **Method schema** + a default `Cabinex-FULL` method matching the current v5.0
   behaviour, so switching to a Method is a no-op refactor.
2. **Reveal + joint + handle parameter objects** wired so the engine reads the
   Method instead of hard-coded consts.
3. **A Method library** UI: pick base → override per scope → see a live diff of
   resulting parts (pillars 4/5 render this visibly).
4. **Gola/handle notch calculator** (from CabMaker) for continuous runs.

> Guardrail: **do not** re-implement Mozaik's entire board parameter surface. Only
> the aluminum-relevant subset. Board depth is incumbent territory — we don't compete there.
