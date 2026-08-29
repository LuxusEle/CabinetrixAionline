# 05 — Site Capture PWA (phone/tablet)

**Job to be done.** Measure, photograph, annotate, verify and hand off a room
without re-keying. This is the app that replaces "measure + upload images + text
measurements" with a **guided, point-to-point, verified** capture.

> Key design principle: **photos are evidence, never the source of dimensions.**
> Every value must be an entered dimension, a known reference, or a connected laser.
> The interface makes that obvious, and refuses to hand off an unverified room.

---

## Wireframe 1 — Project list (home)

```
┌──────────────────────────────────────────────┐
│  ● Cabinex  Site            [+ New Capture] │
│──────────────────────────────────────────────│
│  Projects (sorted: Recently synced)          │
│  ┌────────────────────────────────────────┐  │
│  │ Home - Galle  #2214    ● 68% synced    │  │  ● = capture in-progress
│  │ 4 walls · 2 openings · 6 doses · 0 obs  │  │
│  └────────────────────────────────────────┘  │
│  ┌────────────────────────────────────────┐  │
│  │ Cafe - Colombo  #2241   ✓ Ready        │  │  ✓ = verified + synced
│  │ 5 walls · 3 openings · verified 100%   │  │
│  └────────────────────────────────────────┘  │
│                                            │
│  [Offline mode]  [Sync all]  [Settings]    │
└──────────────────────────────────────────────┘
```

---

## Wireframe 2 — Capture wizard: Start (Phase 0)

```
┌──────────────────────────────────────────────┐
│  ‹ New Capture                        Cancel │
│──────────────────────────────────────────────│
│  Room name     [ Kitchen                ]    │
│  Unit          [ mm ▾ ]  Orientation [North▾]│
│  Floor datum   [ Finished floor ▾ ]          │
│  Ceiling datum [ Ceiling slab ▾ ]            │
│──────────────────────────────────────────────│
│  ( ) Walk walls clockwise                    │
│  ( ) Start with corner A (choose nearest)    │
│                                            │
│                    [  Next: Measure Walls  ] │
└──────────────────────────────────────────────┘
```

---

## Wireframe 3 — Measure wall, point-to-point (core screen)

The main capture surface. Sketch is auto-drawn as you mark point-to-point. A live
running dimension follows your finger. Each endpoint snaps so the polygon stays closed.

```
┌──────────────────────────────────────────────┐
│  ‹ Room Kitchen        Wall A      ▶ 3 of 4  │
│──────────────────────────────────────────────│
│ ┌──────────────────────────────────────────┐ │
│ │   (pointer)                              │ │
│ │   A────────────●────────────B            │ │
│ │   |                             |  ● C   │ │
│ │   |   (live sketch, snapping)   |        │ │
│ │   └─────────────────────────────┘        │ │
│ │   600     ▸ tap=add  drag=adjust mid      │ │
│ └──────────────────────────────────────────┘ │
│──────────────────────────────────────────────│
│  Wall A length   [  4200  ] mm  ✔            │
│  Reading method  (◉ Laser □ Tape □ Estimate) │
│──────────────────────────────────────────────│
│  Add on this wall:                            │
│  [ + Window ] [ + Door ] [ + Obstacle ]       │
│  [ + Service ] [ + Photo ]                    │
│──────────────────────────────────────────────│
│  [ Done wall ]   [ ‹ Back ]   [ Next wall › ] │
└──────────────────────────────────────────────┘
```

- Tap the live sketch to drop **points**; drag a midpoint to correct.
- Entering a distance snaps that edge; the sketch auto-closes the polygon.
- **Confidence pill** per mark: `Laser/tape = high`, `estimate = amber + asked to verify`.

---

## Wireframe 4 — Photo annotation (evidence, not measurement)

```
┌──────────────────────────────────────────────┐
│  ‹ Wall A                Attach Photo        │
│──────────────────────────────────────────────│
│ ┌──────────────────────────────────────────┐ │
│ │  [photo: hob / services on Wall A]       │ │
│ │        ─●  marker: water  0.0m x 0.9m    │ │
│ │        ─●  marker: power  1.2m x 0.9m    │ │
│ └──────────────────────────────────────────┘ │
│──────────────────────────────────────────────│
│  Markers (draw over photo)                   │
│  [ ● point ] [ ─ line ] [ ▭ region ] [ ✎ note]│
│  Each marker must link to a wall/opening.     │
│──────────────────────────────────────────────│
│  "A photo has no scale — dimensions are from  │
│   tape/laser, not this image."                │
│  [ Attach ]   [ ‹ Back ]                     │
└──────────────────────────────────────────────┘
```

---

## Wireframe 5 — Sketch after capture (auto 2D wall sketch, Phase 1)

The "big value" screen: the hand-drawn mark becomes a **measurable 2D wall sketch**
you can correct. Out-of-square + height variation are surfaced, not hidden.

```
┌──────────────────────────────────────────────┐
│  ‹ Room Kitchen              [ Re-measure ]  │
│──────────────────────────────────────────────│
│            TOP PLAN (editable)               │
│ ┌──────────────────────────────────────────┐ │
│ │          ┌───Wall B──┐                  │ │
│ │  Wall A  │   [W] [D] │  Window W 1.0m   │ │
│ │  [W][D]  └───────────┘  Door D 0.9m     │ │
│ │          ┌───Wall C──┐                  │ │
│ │          └───────────┘                  │ │
│ └──────────────────────────────────────────┘ │
│──────────────────────────────────────────────│
│  ✓ 4 walls measured          (val-ish blue)  │
│  ⚠ Diagonal check:  3.8m vs 3.81m (0.3%)     │  tolerance warning
│  ⚠ Ceiling varies 2.9 → 2.84 (needs clip)    │
│──────────────────────────────────────────────│
│  Edit: [drag wall] [add obstacle] [add svc]  │
│  [ + Capture height ]  [ ✓ Verify: Ready ]   │
└──────────────────────────────────────────────┘
```

**Verify = Phase 1 gate.** Coverage % + per-wall confidence; missing critical items
(window not measured, no heights) are listed; only then can the design surface take
ownership.

---

## Wireframe 6 — Sync / offline status

```
┌──────────────────────────────────────────────┐
│  Capture status      Project #2214            │
│──────────────────────────────────────────────│
│  ● Synced                      (current)      │
│  ▸ Syncing 2/4 ...                            │
│  ⚠ Conflict — Wall A edited on desktop       │
│      [ Take desktop ] [ Keep mine ]           │
│──────────────────────────────────────────────│
│  Workflows: outbox stays local until a server │
│  accepts against the base revision.           │
│  [ Retry ]  [ Settings ]                      │
└──────────────────────────────────────────────┘
```

---

## Interaction notes (design rules)

1. **Finger-first:** tap to add, drag midpoints, one-primary-action per screen.
2. **Everything is a constraint, not a note:** opening/service/obstacle are typed
   entities with numbers, not a photo caption.
3. **Show confidence** on every value; amber = needs verify.
4. **Diagonals + heights** are asked for, not optional (out-of-square detection).
5. **Offline-first:** capture in a garage with no signal; local outbox; sync later.
6. **Fail-closed handoff:** the app won't let a designer start on a room that is
   `unverified` or missing critical dimensions.
