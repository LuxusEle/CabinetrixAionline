# 06 — Studio Web (the real app, not a downloader)

**Job to be done.** Turn a captured/assigned room into an approved,
versioned aluminium kitchen without re-keying, and surface the Method (Pillar 2)
so the shop's aluminium construction and prices are reusable rules.

The web portal today (`OnlineCabinet/vercel_backend/public/{index,download,admin}.html`)
is just a downloader. This is the app shell to grow it into. Studio Web is the
**design surface**; SketchUp remains the pro modelling surface; the phone is capture;
the shop is execution.

---

## Wireframe 1 — App shell (I can grow this from the current `index.html`)

```
┌──────────────────────────────────────────────────────────────────┐
│  ◧ Cabinex Studio    [Projects ▾] [Shops] [Customers]   [⚙] [→] │
│──────────────────────────────────────────────────────────────────│
│  Project #2214  Home - Galle     ▸ Draft      [Create new design]│
│──────────────────────────────────────────────────────────────────│
│  Left rail   |   Main canvas          |   Right panel          │
│──────────────────────────────────────────────────────────────────│
│  CONTEXT     |                        |  Properties            │
│  - Customer  |                        |  ─────────────         │
│  - Site      |                        |  Method: Cabinex-FULL  │
│  - Rooms     |    [growing from       |  » Carcase  BoxBar 25.4 │
│      Kitchen |     current planner:   |  » Cladding ACP 3mm     │
│  - Method    |     2D wall graph +    |  » Front    Sash 45°     │
│  - Revisions |     3D view + report]  |  » Handle   Gola J 24x32│
│              |                        |  » Reveals  T3 B3 M3    │
│              |                        |  ----------             │
│              |                        |  [Open Method library]  │
│──────────────────────────────────────────────────────────────────│
│  Bottom status bar:   Synced · Budget LKR 1.24M · 0 warnings    │
└──────────────────────────────────────────────────────────────────┘
```

---

## Wireframe 2 — Wall graph (2D) + assign (Phase 1–2)

The "temp 2D" preview inside the app. Walls are a polygon; each side gets an
inline dropdown to say what goes on it.

```
┌──────────────────────────────────────────────────────────────────┐
│  Edit layout                              [ ↺ ] [ ↻ ] [ ✓ Done ] │
│──────────────────────────────────────────────────────────────────│
│  Wall A (North) 4200mm                              [＋run]      │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ [Base 3-Drawer 500▾][Base 2-Door 600▾][End filler][Cooker] │  │
│  ├───────────────────────────────────────────────────────────┤  │
│  │  run fills left→right; residual → filler, never stretched │  │
│  └───────────────────────────────────────────────────────────┘  │
│  Wall B (East) 3200mm                                [＋run]    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ [Hood bay][Wall 600][Appliance surround][Tall 2400]  [＋]  │  │
│  └───────────────────────────────────────────────────────────┘  │
│  Wall C (South) 4200mm  ▸ window 1.0m 0.0–1.0m       [＋run]    │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │ (void below window) [Base 600][Base 600]  ▸ clearance ok  │  │
│  └───────────────────────────────────────────────────────────┘  │
│──────────────────────────────────────────────────────────────────│
│  Module palette                │  Validators                     │
│  [Base] [Drawer] [Tall]        │  ✓ junction ok                 │
│  [Wall] [Hood] [Open rack]     │  ✓ top-Z aligned (all walls)   │
│  [Appliance] [Filler] [Glass]  │  ⚠ 15mm filler on Wall A       │
└──────────────────────────────────────────────────────────────────┘
```

**Assign dropdown** logic: pick module → category → set width → run auto-fills →
residual shown as filler (never silently stretch an appliance). "Done" commits run
anchors.

---

## Wireframe 3 — Method panel (Pillar 2, the moat, surfaced to the shop)

The Method is editable, inheritable and **versioned**. This is where a shop saves
its "LKR Standard Aluminum Kitchen" rules.

```
┌──────────────────────────────────────────────┐
│  Construction Method           ┌✓──────────┐ │
│  Cabinex-FULL  v3 (bin: shop) │ Save copy │ │
│──────────────────────────────────────────────│
│  Carcase                        [BoxBar 25.4]│
│   stock length    [6400] mm  auto_split ✓   │
│  Cladding                       [ACP 3mm]    │
│   rear_seat       [on_rear_rail]  notch [U] │
│  Front                           [Sash 45°]  │
│   infill  (◉ ACP ▢ Glass)  lip_reveal [3]   │
│  Handle                          [Gola J]    │
│   section 24 x 32   gap_to_mate [3] mm      │
│  Reveals                        T[3] B[3]   │
│   side_fin[0] side_unfin[0] mid[3]          │
│   pair[3] adj[3] filler[0] applied[3]      │
│  Toe  base_frame 38.1  no_plinth_cover ✓   │
│  Corner  one_sided_blind  top_return +25mm  │
│──────────────────────────────────────────────│
│  Inherit from: [Cabinex-FULL (base) ▾]      │
│  Scope of this edit: (◉ run ▢ wall ▢ part)  │
│  Overrides allowed:  Carcase, Handle        │
│  [Preview changed parts]  [Apply]           │
└──────────────────────────────────────────────┘
```

Change a value → "Preview changed parts" shows the delta (part count, material,
cost, waste, warnings). That's the instant-impact loop from roadmap §20.

---

## Wireframe 4 — 3D view (grow from current Step 5)

```
┌──────────────────────────────────────────────────────────────────┐
│  3D preview   [Front▼][Return][Top][Iso]        [Regenerate]     │
│──────────────────────────────────────────────────────────────────│
│            (3D kitchen, aluminium materials)                      │
│  select cabinet → inline: [edit][resize][change_type][delete]     │
│──────────────────────────────────────────────────────────────────│
│  Impact (this selection)                                        │
│   parts +12 · material LKR 18.4k · waste 2% · 0 warnings        │
│  [ Revert ]   [ Accept as revision ]                            │
└──────────────────────────────────────────────────────────────────┘
```

Accept = a **new revision** (reversible). Deterministic validation runs before preview.

---

## Wireframe 5 — BOM / cost / approval (reports surface)

```
┌──────────────────────────────────────────────────────────────────┐
│  BOM & Cost                Snapshot v7 (immutable)  [⬇ PDF] [⬇ DXF]│
│──────────────────────────────────────────────────────────────────│
│  Tab: [Parts] [Sheet cut] [Bar cut] [Hardware] [Cost] [Approval] │
│──────────────────────────────────────────────────────────────────│
│  Aluminium bar   | count | mm each | stock 6400 | cuts   #chiral │
│   BoxBar 25.4       38        ...
│  ACP sheet       | part | W x D | grain ↑ | nest 96% | #L/R split │
│──────────────────────────────────────────────────────────────────│
│  Cost (LKR)   Base 1,020,000 · waste 4% · labour (per linear ft)  │
│               O/H 12% · margin 18% · tax · Total  1,241,320       │
│──────────────────────────────────────────────────────────────────│
│  [Freeze design + BOM]  [Send approval link ▾]  [Copy/Move job]   │
└──────────────────────────────────────────────────────────────────┘
```

Every number reads the **authored part record** (Pillar 4) — no inference. If
anything is missing, the block is red, not guessed.

---

## Wireframe 6 — Customer approval link (no-login, secure)

```
┌──────────────────────────────────────────────────────────────────┐
│  Home - Galle         Design review           [Approve] [Request change]│
│──────────────────────────────────────────────────────────────────│
│  (orbitable 3D · annotated)                                        │
│  "What changed from your inspiration:"                            │
│   ✓ Aluminium carcass (BoxBar + 3mm ACP) · Gola J handle          │
│   ⚠ Counter depth limited to 600 by plumbing — site constraint    │
│──────────────────────────────────────────────────────────────────│
│  Budget LKR 1,241,320 · est. 6 weeks · [Questions]               │
│  Approval recorded with identity + timestamp (immutable audit)   │
└──────────────────────────────────────────────────────────────────┘
```

---

## Navigation map (Studio Web)

```
Projects → Project →
  ├─ Context (customer / site / room)
  ├─ Design  (wall graph + assign → Method → 3D → validators)
  ├─ Review  (BOM + cost + freeze + approval link)
  ├─ Shop    (shortcut into Workshop PWA / printable pack)
  └─ History (revisions + change orders + events)
```
