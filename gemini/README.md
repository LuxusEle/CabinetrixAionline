# Cabinetrix AI — Gemini Development Workspace

All development scripts, builders, runners, and CNC reports are centralized inside this directory (`c:/Users/asank/Documents/CabinetrixAionline/gemini/`).

---

## Workspace Directory Contents

| Script / Artifact | Description |
| :--- | :--- |
| **`build_luxury_gola_kitchen_master.rb`** | **Full Luxury Production Kitchen**: 3600mm Wall Run (Double Oven Tower, Pantry with 5x internal drawers, Cooktop Gola Bank, Spice Pullout, Wine Unit, Cooker Hood, 2x Glass Sash Cabinets with LEDs) + 2000x900mm Calacatta Marble Waterfall Island with Aisle-Facing Drawers (+Y), Undermount Sink, Gooseneck Faucet, Breakfast Stools, 100% Minifix 15 joinery, true Gola overlap finger grab geometry, and Hettich Actro 5D undermount drawers. |
| **`gola_drawer_bank_master.rb`** | Standalone 2x 600mm Base Gola Drawer Bank with 20x Minifix 15 sets, 3x machined gables, L & C continuous profiles, 5-piece birch drawer boxes, and Hettich Actro 5D runners. |
| **`run_l_kitchen_island.rb`** | Modular L-Kitchen + Island layout with atomic Box hierarchy (`Box_01` to `Box_05`) and selective CNC line-boring. |
| **`run_cabinet_grid.rb`** | Comparative test grid with L-Joint fasteners and production Gola carcases. |
| **`demo_ljoint_connections.rb`** | 18mm board L-joint KD connector comparisons (Minifix vs Dowel vs Confirmat vs Combined). |
| **`run_gemini_master.rb`** | Master suite runner with interactive menu. |
| **`Cabinetrix_Full_Kitchen_Production_Report.html`** | Interactive Workshop Production & CNC Boring schedule. |

---

## SketchUp Execution Commands

### 1. Master Luxury Kitchen (Full 3.6m + Island Layout)
```ruby
load 'c:/Users/asank/Documents/CabinetrixAionline/gemini/build_luxury_gola_kitchen_master.rb'
```

### 2. Standalone 2x Gola Drawer Bank
```ruby
load 'c:/Users/asank/Documents/CabinetrixAionline/gemini/gola_drawer_bank_master.rb'
```

### 3. Modular L-Kitchen + Island Runner
```ruby
load 'c:/Users/asank/Documents/CabinetrixAionline/gemini/run_l_kitchen_island.rb'
```

### 4. Comparison Grid Runner
```ruby
load 'c:/Users/asank/Documents/CabinetrixAionline/gemini/run_cabinet_grid.rb'
```
