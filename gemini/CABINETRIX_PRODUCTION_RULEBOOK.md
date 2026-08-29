# Cabinetrix AI — Production CAD/CAM Engineering Rulebook
**Standard Specification & Mathematical Transformation Matrix for Cabinet Joinery, Gola Extrusions & Hardware Placements**
*Version: 2.1 (Production Master) | System 32 Metric Standard*

---

## 1. Global Coordinate System & Direction Conventions

```
              +Z (Up / Height)
               ▲
               │
               │   +Y (Wall Run Rear / Room North)
               │  ▲
               │ ╱
               │╱
 ──────────────┼──────────────► +X (Right / Width)
              ╱│
             ╱ │
            ▼  │
  -Y (Chef Aisle / Front)
```

| Axis | Orientation for Main Wall Run | Orientation for Island Unit |
| :--- | :--- | :--- |
| **+X** | Extends to the Right ($0\text{mm} \to 3600\text{mm}$) | Extends to the Right ($1000\text{mm} \to 3000\text{mm}$) |
| **-Y** | **Front Face / Chef Side** ($0\text{mm} \to -560\text{mm}$) | **Seating Overhang / Stool Side** ($-1960\text{mm} \to -2300\text{mm}$) |
| **+Y** | **Rear Wall** ($Y = 0\text{mm}$) | **Front Prep Face / Chef Aisle** ($Y = -1400\text{mm}$) |
| **+Z** | **Vertical Height** ($0\text{mm} \to 2160\text{mm}$) | **Vertical Height** ($0\text{mm} \to 860\text{mm}$) |

---

## 2. Gola Aluminum Profile Geometry & Concavity Matrix

In handleless European cabinetry (SCILM / Häfele / Hettich), Gola profiles provide continuous finger grab channels. The aluminum extrusions are **always recessed 26mm behind the decorative drawer front plane**.

```
A. TOP L-GOLA (Under Countertop)        B. MID C-GOLA (Between Drawers)
   Countertop (Z=720)                      Upper Front Bottom (Z=375)
   ══════════════════════                  ══════════════════════════
   │ ┌───────────────┐                     ┌────────┐ (Lip Z=403.5)
   │ │  L-Channel    │                     │        │
   │ │  (Concave -Y) │                     │ C-Cavity (Concave -Y)
   │ └────┐   ┌──────┘                     │ (Depth=26mm)
   │      │   │                            │        │
   │      └───┘ (Lip Z=663.5)              └────────┘ (Lip Z=330)
   ▼                                       ══════════════════════════
   Top Front Top (Z=685)                   Lower Front Top (Z=358)
```

### 2.1 L-Gola Profile (SCILM Type 610)
- **Cutout Dimensions**: $26.0\text{mm}$ Depth $\times$ $59.0\text{mm}$ Height ($Z: 661\text{mm} \to 720\text{mm}$).
- **Profile Extrusion**: $26.0\text{mm}$ Depth $\times$ $56.5\text{mm}$ Height ($Z: 663.5\text{mm} \to 720.0\text{mm}$).
- **Concavity**:
  - Wall Run: Opens toward **$-Y$** (front) and down.
  - Island: Opens toward **$+Y$** (aisle) and down.
- **Drawer Front Overlap**: Top drawer front top sits at $Z = 685\text{mm}$, overlapping the L-profile by $21.5\text{mm}$ and leaving a **$35\text{mm}$ finger-pull cavity** ($Z: 685 \to 720\text{mm}$) under the worktop.

### 2.2 C-Gola Profile (SCILM Type 620)
- **Cutout Dimensions**: $26.0\text{mm}$ Depth $\times$ $73.5\text{mm}$ Height ($Z: 330.0\text{mm} \to 403.5\text{mm}$).
- **Profile Extrusion**: $26.0\text{mm}$ Depth $\times$ $73.0\text{mm}$ Height ($Z: 330.25\text{mm} \to 403.25\text{mm}$).
- **Concavity**: Symmetric horizontal U-channel opening toward **$-Y$** (wall run) or **$+Y$** (island).
- **Drawer Front Overlaps**:
  - Upper drawer bottom edge sits at $Z = 375\text{mm}$ (overlaps top lip by $28.5\text{mm}$).
  - Lower drawer top edge sits at $Z = 358\text{mm}$ (overlaps bottom lip by $28.0\text{mm}$).
  - **Center Finger Slot**: $375\text{mm} - 358\text{mm} = 17.0\text{mm} \to 22.0\text{mm}$ continuous opening directly in front of the C-channel cavity.

---

## 3. KD Fasteners & Dowels (Penetration & Placement Matrix)

### 3.1 Hardware Standard Dimensions

| Fastener | Diameter | Length / Depth | Function |
| :--- | :--- | :--- | :--- |
| **Minifix 15 Cam** | $\varnothing 15.0\text{mm}$ | $12.5\text{mm}$ Deep | Zinc cam lock inserted in panel face ($B = 34.0\text{mm}$ from joint edge). |
| **Minifix Connecting Bolt** | $\varnothing 7.5\text{mm}$ collar / $\varnothing 5.0\text{mm}$ thread | $11.0\text{mm}$ thread / $34.0\text{mm}$ pin | Steel bolt inserted into gable edge pilot hole. |
| **European Beech Dowel** | $\varnothing 8.0\text{mm}$ | $30.0\text{mm}$ ($10\text{mm}$ in gable, $20\text{mm}$ in panel) | Fluted shear & alignment pin ($32\text{mm}$ System 32 pitch). |

### 3.2 Strict Panel Bounds & Dowel In-Bounds Rules

To prevent dowels or cams from protruding outside panel boundaries:
1. **Rule B1 (Full Bottom / Fixed Shelves, Depth $\ge 300\text{mm}$)**:
   - Front Minifix at $Y = Y_{\text{front}} + 70\text{mm}$; Dowel at $+32\text{mm}$ ($Y = Y_{\text{front}} + 102\text{mm}$).
   - Rear Minifix at $Y = Y_{\text{rear}} - 70\text{mm}$; Dowel at $-32\text{mm}$ ($Y = Y_{\text{rear}} - 102\text{mm}$).
   - **Condition**: $\text{Clamp}(Y_{\text{dowel}}, Y_{\text{min}} + 15\text{mm}, Y_{\text{max}} - 15\text{mm})$.
2. **Rule B2 (Narrow Stretchers, Width $< 120\text{mm}$)**:
   - **Top Rear Stretcher ($100\text{mm}$)**: Minifix at centerline ($Y = Y_{\text{rear}} - 50\text{mm}$). Dowel at $+32\text{mm}$ ($Y = Y_{\text{rear}} - 18\text{mm}$, strictly inside the $100\text{mm}$ span).
   - **Top Front Gola Sub-Stretcher ($80\text{mm}$)**: Minifix at centerline ($Y = Y_{\text{front}} + 40\text{mm}$). Dowel at $+25\text{mm}$ ($Y = Y_{\text{front}} + 65\text{mm}$, strictly inside the $80\text{mm}$ span).
   - **Mid C-Gola Stretcher ($60\text{mm}$)**: Minifix at centerline ($Y = Y_{\text{front}} + 30\text{mm}$). **NO DOWEL** because $30\text{mm} \pm 32\text{mm}$ would penetrate the wood edge!
3. **Rule B3 (Cam Face Normal Vector $\vec{N}_{\text{cam}}$)**:
   - Bottom Panel: $\vec{N}_{\text{cam}} = (0, 0, +1)$ (Cam visible from inside cabinet).
   - Top Stretchers: $\vec{N}_{\text{cam}} = (0, 0, -1)$ (Cam on underside, hidden by countertop).
   - Mid C-Stretcher: $\vec{N}_{\text{cam}} = (0, 0, -1)$ (Cam on underside).

---

## 4. 45° Miter Aluminum Sash & Glass Cabinet Rules

1. **True 45° Miter Frames**:
   - Aluminum sash profiles must be miter-cut at $45^\circ$ on both top/bottom rails and left/right stiles.
   - Glass panes are captured internally in the $4.0\text{mm}$ gasket rebate.
2. **Clean Display Interiors**:
   - In glass display wall cabinets, **NO exposed melamine hanging rails** are placed across the top interior.
   - Mounting uses concealed top-corner suspension brackets (Camar / Häfele standard).
3. **Pantry Space Tower Clearances**:
   - In tall pantry towers with internal drawers (e.g. Blum Space Tower / Hettich InnoTech Larder), the 5 pullout drawer boxes mount directly onto side gables on soft-close runners at $210\text{mm}$ vertical pitch with **NO intermediate fixed shelves** colliding with the drawer movement.
