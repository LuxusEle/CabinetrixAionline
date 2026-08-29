# 08 — SketchUp Planner (reconceived around the Method + job graph)

**Goal.** Keep the professional modelling experience, but make the planner a
**view/editor of the canonical job** (Pillar 5) that is driven by a **Method**
(Pillar 2) and emits **authored parts** (Pillar 4). Today `cbx_hybrid_planner.html`
is a 6-step wizard (Room→Openings→Settings→Modular→Previews→BOM). We keep the
stepper UX but re-point its tabs at the new model so the same job can be opened in
Studio Web without re-keying.

> Production boundary (roadmap §23): SketchUp is an **editor/renderer**, not the only
> source of truth. It caches canon IDs + the current revision ID in attribute
> dictionaries and shows sync status: `Unsynced · Syncing · Current · Conflict ·
> Read-only(approved)`.

---

## Wireframe 1 — Stepper mapped to the new model

```
┌──────────────────────────────────────────────────────────────────┐
│ 1.Room 2.Openings 3.Method 4.Modular 5.3D 6.BOM │ ▸ synced ✓ v7  │
│──────────────────────────────────────────────────────────────────│
│  Step 3 of 6:  Aluminium Construction Method                       │
│──────────────────────────────────────────────────────────────────│
│  Begin from:  [Cabinex-FULL (shop) ▾]  inherit ✓                  │
│    Carcase   BoxBar 25.4   stock 6400  split_on_junction ✓       │
│    Cladding  ACP 3mm       notch U  rear_seat on_rear_rail       │
│    Front     Sash 45°      infill [ACP ▾]  lip_reveal 3mm        │
│    Handle    Gola J 24x32  gap_to_mate 3mm                       │
│    Reveals   T3 B3 M3 pair3 adj3 filler0 applied3                │
│    Toe       base_frame 38.1  no_plinth_cover ✓                  │
│    Corner    one_sided_blind  top_return +25mm                   │
│  Scope of edit:  (◉ run  ▢ wall  ▢ cabinet  ▢ part)              │
│  ⚠ override not allowed at this scope → rejected                 │
│  [Preview changed parts]   [Apply]   [Save as shop base method]  │
└──────────────────────────────────────────────────────────────────┘
```

Step 3 is the Method (promoted from today's flat "Project Global Settings"). This is
the single most useful change: the aluminium construction becomes reusable, inheritable,
**and** explainable to the AI.

---

## Wireframe 2 — Modular design, now wall-anchored + ID'd

```
┌──────────────────────────────────────────────────────────────────┐
│  Step 4:  Modular Design         Wall A  (North 4200)  ▸ #B-104  │
│──────────────────────────────────────────────────────────────────│
│  [Base 500][Base 600][Cooker 900][End filler]     [+ module]     │
│    ↳ #B-101        #B-102      #B-103    #B-104 (selected)       │
│──────────────────────────────────────────────────────────────────│
│  Cabinet #B-104   Base 3-Drawer              (immutable ID)      │
│    width [500] height [850] depth [600]  template [Drw3]         │
│    variants:  [glass top] [handle] [mullion]  [duplicate ▸]      │
│  [Apply] [Resize] [Change type] [Delete]  (reversible revision)  │
└──────────────────────────────────────────────────────────────────┘
```

Each box has a **stable `#B-104`** (display code) and an immutable `cabinet_uuid`.
Batch-edit multiple boxes like CabMaker's "batch edit". Reorder never renumbers —
display order is a field, ID is fixed.

---

## Wireframe 3 — 3D previews (unchanged UX, deterministic)

```
┌──────────────────────────────────────────────────────────────────┐
│  Step 5:  3D Views   [Front▼][Return][Top][Iso]     [Regenerate] │
│──────────────────────────────────────────────────────────────────│
│    (aluminium render: BoxBar + sash + Gola, hinge marks)         │
│──────────────────────────────────────────────────────────────────│
│  Validators:  ✓ junction ok ✓ top-Z aligned ✓ no collides       │
│  [ Accept as revision ]  [ Revert ]   (undo-able)                │
└──────────────────────────────────────────────────────────────────┘
```

---

## Wireframe 4 — BOM / report (reads authored parts)

```
┌──────────────────────────────────────────────────────────────────┐
│  Step 6:  BOM & Workshop Report           Snapshot v7 (immutable)│
│──────────────────────────────────────────────────────────────────│
│  Tabs: [Parts][Bar cut][Sheet nest][Hardware][Cost][Workshop]    │
│──────────────────────────────────────────────────────────────────│
│  • authored part record only — never inferred from geometry      │
│  • any missing data → RED block (fail closed)                    │
│  [Rebuild pack] [Export DXF/CSV] [Print] [Sync to cloud]         │
└──────────────────────────────────────────────────────────────────┘
```

---

## Wireframe 5 — Sync status (top-right)

```
┌──────────────────────────────────────────────────────────────────┐
│  ▸ Synced (revision v7)      · open in Studio ▲ · read-only if   │
│    approved  ·  Conflict → [take desktop] [keep local]           │
└──────────────────────────────────────────────────────────────────┘
```

---

## Implementation notes (conceptual)
1. Load job JSON from the cloud into the planner as the working revision.
2. Planner actions emit **typed domain commands** (create_cabinet, resize, set_option
   on a scope) — the engine validates before geometry commits.
3. Write canon IDs + revision back into model attribute dictionaries.
4. Keep `cbx_hybrid_engine.rb` as the sole geometry/part author; it also reads the
   **Method** instead of hard-coded consts (see `02`).
5. Never remote-eval streaming code: the extension is signed/versioned; cloud
   returns data + typed commands (roadmap §16 fix).
