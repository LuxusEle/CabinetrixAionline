# ==============================================================================
# CABINETRIX AI — MASTER KITCHEN LAYOUT MATRIX & 20-MODULE CATALOG
# File: gemini/cabinetrix_layout_matrix.rb
#
# Production Standard:
#   • REAL 3D ARCHITECTURAL ROOM FORMULATIONS:
#     - Layout A: True I-Shape (Straight Single Wall 4200mm) with Full 2700mm Bulkheads
#     - Layout B: True L-Shape (90° Perpendicular Return Wall with LeMans II Corner)
#     - Layout C: True U-Shape (3-Sided Room with Dual Corners & Peninsula Return)
#     - Layout D: Luxury Galley with Freestanding Central Island (Double-Sided Gola & Overhead Gantry)
# ==============================================================================
require 'sketchup.rb'
require_relative 'cabinetrix_box_engine'
require_relative 'cabinetrix_collision_engine'

module CabinetrixLayoutMatrix
  # ----------------------------------------------------------------------------
  # 1. 20 PARAMETRIC CABINET BOX DEFINITIONS
  # ----------------------------------------------------------------------------
  MODULE_CATALOG = {
    # Base Cabinets (860mm datum with 100mm plinth + 720mm carcase)
    "B_GOLA_2D_900" => {
      id: "B_GOLA_2D_900",
      type: :base_gola_drawers,
      category: "Base Drawer Bank",
      name: "Base 2-Drawer Pot Bank 900mm",
      w: 900.0, h: 720.0, d: 560.0,
      desc: "SCILM Top L-Gola & Mid C-Gola, Hettich Actro 5D undermount slides (450mm runner, 70kg load)"
    },
    "B_GOLA_3D_600" => {
      id: "B_GOLA_3D_600",
      type: :base_gola_drawers,
      category: "Base Drawer Bank",
      name: "Base Cutlery & Pot Drawer Bank 600mm",
      w: 600.0, h: 720.0, d: 560.0,
      desc: "SCILM Gola profiles, top cutlery drawer + lower deep pot drawer"
    },
    "B_GOLA_SINK_900" => {
      id: "B_GOLA_SINK_900",
      type: :base_gola_sink,
      category: "Base Sink & Waste",
      name: "Base Sink Unit with Cargo Waste 900mm",
      w: 900.0, h: 720.0, d: 560.0,
      desc: "U-cutout sub-front drawer for plumbing clearance + lower 2-bin recycling pullout"
    },
    "B_GOLA_COOKTOP_900" => {
      id: "B_GOLA_COOKTOP_900",
      type: :base_gola_cooktop,
      category: "Base Cooking",
      name: "Base Induction Cooktop Unit 900mm",
      w: 900.0, h: 720.0, d: 560.0,
      desc: "20mm subtop ventilation gap, 120mm low-profile heat shield upper drawer box"
    },
    "B_GOLA_SPICE_300" => {
      id: "B_GOLA_SPICE_300",
      type: :base_gola_spice,
      category: "Base Storage",
      name: "Base 2-Tier Spice Pullout 300mm",
      w: 300.0, h: 720.0, d: 560.0,
      desc: "Kesseböhmer Dispensa Junior chrome 2-tier wire baskets with soft-close base runner"
    },
    "B_GOLA_WINE_600" => {
      id: "B_GOLA_WINE_600",
      type: :base_gola_wine,
      category: "Base Storage",
      name: "Base Wine Storage Unit 600mm",
      w: 600.0, h: 720.0, d: 560.0,
      desc: "Underbench dual-zone climate / bottle storage unit with plinth ventilation"
    },
    "B_LEMANS_CORNER_1050" => {
      id: "B_LEMANS_CORNER_1050",
      type: :base_lemans_corner,
      category: "Corner Storage",
      name: "Base Blind Corner LeMans II 1050mm",
      w: 1050.0, h: 720.0, d: 560.0,
      desc: "Kesseböhmer LeMans II twin swivel peanut trays (430mm radius) with 450mm clear door"
    },
    "B_MAGIC_CORNER_1050" => {
      id: "B_MAGIC_CORNER_1050",
      type: :base_magic_corner,
      category: "Corner Storage",
      name: "Base Magic Corner Pullout 1050mm",
      w: 1050.0, h: 720.0, d: 560.0,
      desc: "Articulated front frame brings rear storage baskets forward on door opening"
    },
    "B_L_CORNER_EASYREACH_900" => {
      id: "B_L_CORNER_EASYREACH_900",
      type: :base_l_corner_easy_reach,
      category: "Corner Storage",
      name: "Base 900x900 L-Corner 2-Tier Carousel",
      w: 900.0, h: 720.0, d: 900.0,
      desc: "Bi-fold 170° corner doors with 380mm radius revolving 2-tier turntable carousel"
    },

    # Tall Towers (2160mm carcase height + 100mm plinth)
    "T_SPACE_TOWER_600" => {
      id: "T_SPACE_TOWER_600",
      type: :tall_space_tower,
      category: "Tall Pantry",
      name: "Tall Space Tower Larder 600mm",
      w: 600.0, h: 2160.0, d: 600.0,
      desc: "Blum Space Tower with 5 internal pullout drawers below 1200mm datum & 155° zero-protrusion hinges"
    },
    "T_OVEN_TOWER_600" => {
      id: "T_OVEN_TOWER_600",
      type: :tall_oven_tower,
      category: "Tall Appliance",
      name: "Tall Built-in Double Oven Tower 600mm",
      w: 600.0, h: 2160.0, d: 600.0,
      desc: "Structural base datum shelf at Z=820mm, 50mm rear chimney ventilation, bottom pot drawer"
    },
    "T_PANTRY_LARDER_600" => {
      id: "T_PANTRY_LARDER_600",
      type: :tall_pantry_larder,
      category: "Tall Pantry",
      name: "Tall Storage Pantry 600mm",
      w: 600.0, h: 2160.0, d: 600.0,
      desc: "Full-height adjustable shelving with System 32 metric line-boring and 45° Senior sash door"
    },

    # Wall Cabinets (720mm height, 350mm depth)
    "W_LIFT_AVENTOS_HF_900" => {
      id: "W_LIFT_AVENTOS_HF_900",
      type: :wall_lift_aventos,
      category: "Wall Lift",
      name: "Wall AVENTOS HF Bi-Fold Lift 900mm",
      w: 900.0, h: 720.0, d: 350.0,
      desc: "Blum AVENTOS HF power lift bi-fold mechanism with 50mm internal shelf setback"
    },
    "W_GLASS_DISPLAY_900" => {
      id: "W_GLASS_DISPLAY_900",
      type: :wall_glass_display,
      category: "Wall Display",
      name: "Wall Senior Sash Glass Display 900mm",
      w: 900.0, h: 720.0, d: 350.0,
      desc: "45° mitered anodized aluminum frame with 4mm smoked glass infill and tempered glass shelves"
    },
    "W_HOOD_INTEGRATED_900" => {
      id: "W_HOOD_INTEGRATED_900",
      type: :wall_cooker_hood,
      category: "Wall Extractor",
      name: "Wall Concealed Extractor Hood 900mm",
      w: 900.0, h: 720.0, d: 350.0,
      desc: "Integrated grease baffles, upper spice chamber, and dual 3000K LED task downlights"
    },

    # Top Bulkhead Units (360mm height, 350mm depth for 2700mm ceiling runs)
    "BLK_FLAP_HK_900" => {
      id: "BLK_FLAP_HK_900",
      type: :top_bulkhead_flap,
      category: "Top Bulkhead",
      name: "Top Bulkhead Stay Lift Flap 900mm",
      w: 900.0, h: 360.0, d: 350.0,
      desc: "Blum AVENTOS HK-top stay lift with TIP-ON push-to-open latch for ceiling-height storage"
    },

    # Open Architectural Racks
    "OPN_METAL_RACK_600" => {
      id: "OPN_METAL_RACK_600",
      type: :open_rack_metal,
      category: "Open Architectural",
      name: "Matte Black Aluminum Open Display Rack 600mm",
      w: 600.0, h: 720.0, d: 350.0,
      desc: "20x20mm welded aluminum black frame with solid European Oak floating display shelves"
    },
    "OPN_WINE_GRID_400" => {
      id: "OPN_WINE_GRID_400",
      type: :open_wine_grid,
      category: "Open Architectural",
      name: "Solid Oak 12-Bottle Wine Grid 400mm",
      w: 400.0, h: 720.0, d: 350.0,
      desc: "18mm solid timber interlocking cross divider holding 12 standard 750ml wine bottles"
    },

    # Island Modules
    "ISL_GOLA_2D_900" => {
      id: "ISL_GOLA_2D_900",
      type: :island_gola_drawers,
      category: "Island Prep",
      name: "Island Double-Sided Gola Pot Bank 900mm",
      w: 900.0, h: 720.0, d: 560.0,
      desc: "Freestanding island pot drawer bank with SCILM profile and solid birch organizers"
    },
    "ISL_PREP_SINK_900" => {
      id: "ISL_PREP_SINK_900",
      type: :island_gola_sink,
      category: "Island Prep",
      name: "Island Prep Sink & Waste Center 900mm",
      w: 900.0, h: 720.0, d: 560.0,
      desc: "Island prep sink with dual 35L recycling waste bins and automatic kick-sensor"
    }
  }

  # ----------------------------------------------------------------------------
  # 2. REAL 3D MULTI-ZONE KITCHEN LAYOUT FORMULATIONS
  # ----------------------------------------------------------------------------
  LAYOUTS = {
    # --------------------------------------------------------------------------
    # Layout A: True I-Shape (Straight Single Wall 4200mm)
    # --------------------------------------------------------------------------
    i_shaped_linear: {
      name: "Layout A — True I-Shape Linear Kitchen (4200mm)",
      description: "Single wall run featuring Space Tower, Cooktop, Pot Drawers, Sink Cargo, Oven Tower, AVENTOS HF & 2700mm Bulkheads.",
      cabinets: [
        { mod_id: "T_SPACE_TOWER_600", x: 0.0, y: 0.0, z: 100.0 },
        { mod_id: "B_GOLA_COOKTOP_900", x: 600.0, y: 0.0, z: 100.0 },
        { mod_id: "W_HOOD_INTEGRATED_900", x: 600.0, y: 0.0, z: 1480.0 },
        { mod_id: "BLK_FLAP_HK_900", x: 600.0, y: 0.0, z: 2200.0 },

        { mod_id: "B_GOLA_2D_900", x: 1500.0, y: 0.0, z: 100.0 },
        { mod_id: "W_LIFT_AVENTOS_HF_900", x: 1500.0, y: 0.0, z: 1480.0 },
        { mod_id: "BLK_FLAP_HK_900", x: 1500.0, y: 0.0, z: 2200.0 },

        { mod_id: "B_GOLA_SINK_900", x: 2400.0, y: 0.0, z: 100.0 },
        { mod_id: "W_GLASS_DISPLAY_900", x: 2400.0, y: 0.0, z: 1480.0 },
        { mod_id: "BLK_FLAP_HK_900", x: 2400.0, y: 0.0, z: 2200.0 },

        { mod_id: "T_OVEN_TOWER_600", x: 3300.0, y: 0.0, z: 100.0 },
        { mod_id: "B_GOLA_SPICE_300", x: 3900.0, y: 0.0, z: 100.0 }
      ]
    },

    # --------------------------------------------------------------------------
    # Layout B: True L-Shape (90° Perpendicular Return Wall)
    # --------------------------------------------------------------------------
    l_shaped_kitchen: {
      name: "Layout B — True L-Shaped Kitchen (3300mm x 2700mm)",
      description: "L-Shape with LeMans II corner unit, cooking zone on Wall 1, and 90° perpendicular sink run on Wall 2.",
      cabinets: [
        # Wall 1 Main Run (Along X-axis, facing -Y)
        { mod_id: "T_SPACE_TOWER_600", x: 0.0, y: 0.0, z: 100.0 },
        { mod_id: "B_GOLA_COOKTOP_900", x: 600.0, y: 0.0, z: 100.0 },
        { mod_id: "W_HOOD_INTEGRATED_900", x: 600.0, y: 0.0, z: 1480.0 },
        { mod_id: "B_LEMANS_CORNER_1050", x: 1500.0, y: 0.0, z: 100.0 },
        { mod_id: "W_LIFT_AVENTOS_HF_900", x: 1500.0, y: 0.0, z: 1480.0 },

        # Wall 2 Return Run (Perpendicular 90° along Y-axis, facing +X)
        { mod_id: "B_GOLA_SINK_900", x: 2550.0, y: -560.0, z: 100.0, rotation_deg: 90.0 },
        { mod_id: "W_GLASS_DISPLAY_900", x: 2550.0, y: -560.0, z: 1480.0, rotation_deg: 90.0 },
        { mod_id: "B_GOLA_2D_900", x: 2550.0, y: -1460.0, z: 100.0, rotation_deg: 90.0 },
        { mod_id: "T_OVEN_TOWER_600", x: 2550.0, y: -2360.0, z: 100.0, rotation_deg: 90.0 }
      ]
    },

    # --------------------------------------------------------------------------
    # Layout C: True U-Shape (3-Sided Room with Dual Corners & Peninsula)
    # --------------------------------------------------------------------------
    u_shaped_kitchen: {
      name: "Layout C — True U-Shaped Kitchen (3600mm x 2850mm x 2400mm)",
      description: "3-Sided U-Shape with Magic Corner on left, sink base in center, LeMans II on right, and peninsula return.",
      cabinets: [
        # Left Run (Wall 1 along Y-axis, facing +X)
        { mod_id: "T_SPACE_TOWER_600", x: 0.0, y: -1800.0, z: 100.0, rotation_deg: 90.0 },
        { mod_id: "B_GOLA_SPICE_300", x: 0.0, y: -1200.0, z: 100.0, rotation_deg: 90.0 },

        # Left Corner & Center Main Run (Wall 2 along X-axis, facing -Y)
        { mod_id: "B_MAGIC_CORNER_1050", x: 0.0, y: 0.0, z: 100.0 },
        { mod_id: "B_GOLA_SINK_900", x: 1050.0, y: 0.0, z: 100.0 },
        { mod_id: "W_LIFT_AVENTOS_HF_900", x: 1050.0, y: 0.0, z: 1480.0 },
        { mod_id: "B_LEMANS_CORNER_1050", x: 1950.0, y: 0.0, z: 100.0 },

        # Right Run / Peninsula (Wall 3 along Y-axis, facing -X into room)
        { mod_id: "B_GOLA_COOKTOP_900", x: 3000.0, y: -560.0, z: 100.0, rotation_deg: -90.0 },
        { mod_id: "W_HOOD_INTEGRATED_900", x: 3000.0, y: -560.0, z: 1480.0, rotation_deg: -90.0 },
        { mod_id: "B_GOLA_2D_900", x: 3000.0, y: -1460.0, z: 100.0, rotation_deg: -90.0 }
      ]
    },

    # --------------------------------------------------------------------------
    # Layout D: Luxury Galley with Freestanding Central Island
    # --------------------------------------------------------------------------
    galley_with_island: {
      name: "Layout D — Luxury Galley Kitchen with Freestanding Central Island",
      description: "4-Tower tall appliance wall bank with 2700mm freestanding double-sided social island across a 1200mm aisle.",
      cabinets: [
        # Back Wall Tall Bank (Facing -Y)
        { mod_id: "T_SPACE_TOWER_600", x: 0.0, y: 0.0, z: 100.0 },
        { mod_id: "T_OVEN_TOWER_600", x: 600.0, y: 0.0, z: 100.0 },
        { mod_id: "T_OVEN_TOWER_600", x: 1200.0, y: 0.0, z: 100.0 },
        { mod_id: "T_PANTRY_LARDER_600", x: 1800.0, y: 0.0, z: 100.0 },
        { mod_id: "W_GLASS_DISPLAY_900", x: 2400.0, y: 0.0, z: 1480.0 },
        { mod_id: "BLK_FLAP_HK_900", x: 2400.0, y: 0.0, z: 2200.0 },

        # Freestanding Central Island (Parallel across 1200mm walkway, Y = -1800mm, facing +Y)
        { mod_id: "ISL_PREP_SINK_900", x: 300.0, y: -1800.0, z: 100.0, rotation_deg: 180.0 },
        { mod_id: "ISL_GOLA_2D_900", x: 1200.0, y: -1800.0, z: 100.0, rotation_deg: 180.0 },
        { mod_id: "B_GOLA_WINE_600", x: 2100.0, y: -1800.0, z: 100.0, rotation_deg: 180.0 },

        # Overhead Suspended Gantry Racks (Z = 1600mm)
        { mod_id: "OPN_METAL_RACK_600", x: 600.0, y: -1800.0, z: 1600.0 },
        { mod_id: "OPN_WINE_GRID_400", x: 1400.0, y: -1800.0, z: 1600.0 }
      ]
    }
  }

  # ----------------------------------------------------------------------------
  # 3. BUILDER HELPER METHOD
  # ----------------------------------------------------------------------------
  def self.build_layout(parent_ents, layout_key, origin_x = 0.0, origin_y = 0.0, mats = {}, mode = :hybrid)
    layout = LAYOUTS[layout_key]
    return nil unless layout

    grp = parent_ents.add_group
    grp.name = layout[:name]

    layout[:cabinets].each do |item|
      mod_def = MODULE_CATALOG[item[:mod_id]]
      next unless mod_def

      loc = {
        x: (origin_x + item[:x]).mm,
        y: (origin_y + item[:y]).mm,
        z: item[:z].mm,
        facing_dir: item[:facing_dir] || :front,
        rotation_deg: item[:rotation_deg] || 0.0
      }
      params = {
        width: mod_def[:w].mm,
        height: mod_def[:h].mm,
        depth: mod_def[:d].mm,
        name: "#{item[:mod_id]}_#{mod_def[:w].to_i}",
        mode: mode
      }

      CabinetrixBoxEngine.create_cabinet(grp.entities, mod_def[:type], params, loc, mats)
    end

    grp
  end
end
