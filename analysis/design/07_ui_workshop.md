# 07 — Workshop (labels / QR, cut-plan, per-box elevation)

**Job to be done.** Get the right instruction to the right operator at the point of
work, with durable identity and a printed fallback. This extends the existing
`cbx_workshop_report.html` strengths (multi-view, BOM, per-box pages) but binds
everything to **immutable part IDs + an approved snapshot**.

> Rule (roadmap §13): "A QR opens current role-appropriate data; it does not replace
> identity or authorization." Never encode sensitive job data in a QR — resolve to an ID.

---

## Wireframe 1 — Job / work order board (tablet landscape)

```
┌──────────────────────────────────────────────────────────────────┐
│  Work Order 2214-B   Home-Galle · due Fri   ⚠ 1 exception        │
│──────────────────────────────────────────────────────────────────│
│  Stage: [Cut ▸][Machine][Edge][Assemble][QC][Install]   (done ▸) │
│──────────────────────────────────────────────────────────────────│
│  [Bar cut 38]  [Sheets 12]  [Assemblies 14]  [Labels 120]        │
│  Search job/room/wall/cabinet/part/material/scan ▾                │
└──────────────────────────────────────────────────────────────────┘
```

Status pills: `uncut · cut · machined · edged · assembled · QC · packed ·
issue · recut`. Tap a pill to filter; scan a label to jump.

---

## Wireframe 2 — Bar cut plan (1D aluminium) — the saw view

```
┌──────────────────────────────────────────────────────────────────┐
│  Bar cut plan        BoxBar 25.4 · stock 6400 · kerf 4 · 38 parts │
│──────────────────────────────────────────────────────────────────┐
│  Bar #  |  Part      | Dim   | Cut |  Remnant |  Note / Chirality │
│  1  ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒████████  ▀   6400 → 248  --                   │
│  2  ▒▒▒▒▒▒████     ██████████      6400 → 512  [L] left stile      │
│  3  ▒▒▒▒▒██████████████  ▀█████    6400 → 990  [R] right stile     │
│──────────────────────────────────────────────────────────────────│
│  ✓ every bar ≤ 6400 · auto-split rule on    ▶ sequence: MITER 45° │
│  [Mark part done]  [Print]  [Label]  [Kerb input]                 │
└──────────────────────────────────────────────────────────────────┘
```

Two rows for a single bar show **continuous split** at the stock cut. Chiral parts
(L/R) are kept separate and tagged.

---

## Wireframe 3 — Sheet / nesting cut (2D ACP)

```
┌──────────────────────────────────────────────────────────────────┐
│  Sheet cut plan  ACP 3mm  2440 x 1220 · grain ↑ · nest 96%       │
│──────────────────────────────────────────────────────────────────│
│  ┌──────────────────────────────────────────────────────────────┐ │
│  │  [part][part]  [part]     [remnant ◻ 600x300 → keep QR]       │ │
│  │  [part]  [remnant ◻ 900x700 → keep]                           │ │
│  │  [part][part][part]  [part]                                  │ │
│  └──────────────────────────────────────────────────────────────┘ │
│  Material: white ACP · edge code C  · kerf 4 · trim 10            │
│  [Mark sheet done]  [Save remnant ▾]                              │
└──────────────────────────────────────────────────────────────────┘
```

A remnant is captured as an inventory record with QR + real location (roadmap §14),
not a note.

---

## Wireframe 4 — Per-box elevation plan (the worker's drawing)

```
┌──────────────────────────────────────────────────────────────────┐
│  Cabinet #B-104  Base 3-Drawer 500w x 600d x 850h   Assembly 02/14 │
│──────────────────────────────────────────────────────────────────│
│  FRONT ELEVATION            [Iso] [Front] [Return] [Top]          │
│  ┌─────────────────────────────┐     Hinge: RED ● ● (hinge stile) │
│  │  [ ] top drawer  (Gola J)   │     Handle: opening stile         │
│  │  [ ] mid                    │     Reveal 3mm, pair n/a          │
│  │  [ ] bottom                 │     Base: 38.1 box-bar floor      │
│  └─────────────────────────────┘                                   │
│──────────────────────────────────────────────────────────────────│
│  Parts:  BoxBar 25.4 x n · sash x3 · ACP skin x2 · sill x1       │
│  QR ▮▮▮▮  resolves part_uuid + bom v7   [Step sequence]           │
│──────────────────────────────────────────────────────────────────│
│  [Complete]  [Hold - issue]  [Recut ▾]                            │
└──────────────────────────────────────────────────────────────────┘
```

This is the packaging of CabMaker's "Manage Scenes / assembly images" but tied to
an **approved revision** and to **part IDs**, so a scan is traceable and a recut
keeps lineage.

---

## Wireframe 5 — Label (physical)

```
┌──────────────────────────────────────────────────────────────────┐
│  JOB 2214 · ROOM Kitchen · WALL A · CAB #B-104                    │
│  PART %B104-LS   LEFT SASH STILE  (chiral L — do not mirror)      │
│  DIM  2480 x 21.2   ACP/alu   MATERIAL CABINEX-BAR-25.4          │
│  GRAIN ↑  EDGE C   REV v7   BATCH 02                              │
│  ┌────────────┐                                                   │
│  │   QR ▮▮▮▮   │ → part_uuid + bom_snapshot_id                    │
│  └────────────┘                                                   │
└──────────────────────────────────────────────────────────────────┘
```

**Minimum fields:** job/room/wall/cabinet/part display IDs; part name; finished
dimensions; material/thickness/finish; grain arrow; edge-band codes; face/orientation;
revision + batch; QR → immutable part/work-order ID.

---

## Wireframe 6 — Exception / recut (traceability)

```
┌──────────────────────────────────────────────────────────────────┐
│  Exception — CAB #B-104  recut                          [Close] │
│──────────────────────────────────────────────────────────────────│
│  Reason: [chip on cut ▾]   [photo]   Disposition: [🔁 recut]     │
│  New part ID %B104-LS-R1  · cost LKR 1,240 · adds 35 min         │
│  Linked to work order 2214-B · updated BOM? [⚠ yes v8 required]  │
│──────────────────────────────────────────────────────────────────│
│  Recalculate quote?  (◉ change-order candidate ▢ silent)         │
└──────────────────────────────────────────────────────────────────┘
```

Any recut after approval automatically flags a **change-order candidate**.

---

## Interaction / design rules
1. **One primary action per surface**; large targets; workshop-language labels.
2. **Offline-first** for the workshop (cache the approved GLB + labels locally).
3. **QR resolves identity**, never raw job data.
4. **Printed pack is fallback + archive**; the live view is the operating interface.
5. **Label/batch stamped** so an obsolete label is visibly stale (recut lineage).

---

## Printing notes (from current report + CabMaker)
- Multi-view report: front / return / top / iso per module (already working).
- Batch/sheet labels via a 1-D label printer; PDF fallback on A4 split at kerf.
- Cost estimator stays, with rate fields; keep LKR + per-linear ft labour split.
