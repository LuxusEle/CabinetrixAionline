# ==============================================================================
# CABINETRIX AI — MASTER ARCHITECTURAL CONDUCTOR & SPACE PLANNER
# File: gemini/architecture.rb
#
# Role in System Architecture:
#   • THE MASTER CONDUCTOR:
#     - Interfaces with User Inputs (room plans, photo inputs, style choices, auth).
#     - Solves the room by querying the Catalogue for matching parametric templates.
#     - Coordinates Box Engine (to build 3D geometry), Collision Engine (clearance audit),
#       Nesting Engine (2D panel optimization), and Export Engine (CAM DXFs & Cutlists).
# ==============================================================================
require 'sketchup.rb'
require_relative 'catalogue'
require_relative 'cabinetrix_box_engine'
require_relative 'cabinetrix_collision_engine'
require_relative 'cabinetrix_nesting_engine'
require_relative 'cabinetrix_export_engine'
require_relative 'cabinetrix_callout_engine'

module CabinetrixArchitecture
  # ----------------------------------------------------------------------------
  # 1. ROOM DESIGN SOLVER & TEMPLATE QUERY
  # ----------------------------------------------------------------------------
  def self.design_room_layout(layout_type, room_options = {})
    style = room_options[:style] || :handleless_gola
    all_rooms = {
      i_shape: {
        name: "Architectural I-Shape Linear Run (4200mm)",
        wall_length: 4200.0,
        modules: [
          { template_id: "T_SPACE_TOWER", x: 0.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "B_GOLA_COOKTOP", x: 600.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "BLK_FLAP_HK", x: 600.0, y: 0.0, z: 2200.0, rot: 0.0 },
          { template_id: "B_GOLA_2D", x: 1500.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "W_LIFT_HF", x: 1500.0, y: 0.0, z: 1480.0, rot: 0.0 },
          { template_id: "BLK_FLAP_HK", x: 1500.0, y: 0.0, z: 2200.0, rot: 0.0 },
          { template_id: "B_GOLA_SINK", x: 2400.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "W_GLASS_SASH", x: 2400.0, y: 0.0, z: 1480.0, rot: 0.0 },
          { template_id: "BLK_FLAP_HK", x: 2400.0, y: 0.0, z: 2200.0, rot: 0.0 },
          { template_id: "T_OVEN_TOWER", x: 3300.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "B_GOLA_SPICE", x: 3900.0, y: 0.0, z: 100.0, rot: 0.0 }
        ]
      },
      l_shape: {
        name: "Architectural L-Shape Kitchen with 90° Return (3300x2700mm)",
        modules: [
          # Wall 1 Main Run (faces -Y)
          { template_id: "T_SPACE_TOWER", x: 0.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "B_GOLA_COOKTOP", x: 600.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "B_CNR_LEMANS", x: 1500.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "W_LIFT_HF", x: 1500.0, y: 0.0, z: 1480.0, rot: 0.0 },
          # Wall 2 Return (faces -X into kitchen)
          { template_id: "B_GOLA_SINK", x: 2550.0, y: -560.0, z: 100.0, rot: -90.0 },
          { template_id: "W_GLASS_SASH", x: 2550.0, y: -560.0, z: 1480.0, rot: -90.0 },
          { template_id: "B_GOLA_2D", x: 2550.0, y: -1460.0, z: 100.0, rot: -90.0 },
          { template_id: "T_OVEN_TOWER", x: 2550.0, y: -2360.0, z: 100.0, rot: -90.0 }
        ]
      },
      u_shape: {
        name: "Architectural U-Shape Kitchen with Peninsula (3600x2850x2400mm)",
        modules: [
          # Wall 1 Left (faces +X)
          { template_id: "T_SPACE_TOWER", x: 0.0, y: -2400.0, z: 100.0, rot: 90.0 },
          { template_id: "B_GOLA_SPICE", x: 0.0, y: -1800.0, z: 100.0, rot: 90.0 },
          { template_id: "B_GOLA_2D", x: 0.0, y: -1500.0, z: 100.0, rot: 90.0 },
          # Wall 2 Center (faces -Y)
          { template_id: "B_CNR_MAGIC", x: 0.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "B_GOLA_SINK", x: 1050.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "W_LIFT_HF", x: 1050.0, y: 0.0, z: 1480.0, rot: 0.0 },
          { template_id: "B_CNR_LEMANS", x: 1950.0, y: 0.0, z: 100.0, rot: 0.0 },
          # Wall 3 Peninsula (faces -X)
          { template_id: "B_GOLA_COOKTOP", x: 3000.0, y: -560.0, z: 100.0, rot: -90.0 },
          { template_id: "B_GOLA_2D", x: 3000.0, y: -1460.0, z: 100.0, rot: -90.0 }
        ]
      },
      galley_island: {
        name: "Architectural Galley & Central Social Island (3000x2700mm)",
        modules: [
          # Tall Bank Wall
          { template_id: "T_SPACE_TOWER", x: 0.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "T_OVEN_TOWER", x: 600.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "T_OVEN_TOWER", x: 1200.0, y: 0.0, z: 100.0, rot: 0.0 },
          { template_id: "W_GLASS_SASH", x: 1800.0, y: 0.0, z: 1480.0, rot: 0.0 },
          # Central Island (faces +Y towards cook)
          { template_id: "ISL_GOLA_2D", x: 1200.0, y: -2360.0, z: 100.0, rot: 180.0 },
          { template_id: "ISL_GOLA_2D", x: 2100.0, y: -2360.0, z: 100.0, rot: 180.0 }
        ]
      }
    }

    all_rooms[layout_type.to_sym] || all_rooms[:i_shape]
  end

  # ----------------------------------------------------------------------------
  # 2. MASTER CONDUCTOR EXECUTION PIPELINE
  # ----------------------------------------------------------------------------
  def self.build_room(parent_ents, room_design, origin_x = 0.0, origin_y = 0.0, mats = {}, mode = :closed)
    room_grp = parent_ents.add_group
    room_grp.name = room_design[:name]

    room_panels = []
    room_hardware = []

    room_design[:modules].each_with_index do |m, idx|
      tmpl = CabinetrixCatalogue.get(m[:template_id])
      next unless tmpl

      w = tmpl[:dimensions][:w][:default]
      h = tmpl[:dimensions][:h][:default]
      d = tmpl[:dimensions][:d][:default]

      cab_tag = "C#{idx+1}"
      
      # 1. Ask Box Engine (The Maker) to construct 3D geometry using the stencil
      loc = { x: (origin_x + m[:x]).mm, y: (origin_y + m[:y]).mm, z: m[:z].mm, rotation_deg: m[:rot] }
      box_params = { width: w.mm, height: h.mm, depth: d.mm, name: "#{m[:template_id]}_#{cab_tag}", mode: mode }
      
      box_type = case tmpl[:category]
                 when :base_drawer then :base_gola_drawers
                 when :base_sink   then :base_gola_sink
                 when :base_cooking then :base_gola_cooktop
                 when :base_storage then :base_gola_spice
                 when :corner_base then :base_lemans_corner
                 when :tall_tower  then (m[:template_id].include?('OVEN') ? :tall_oven_tower : :tall_space_tower)
                 when :wall_lift   then :wall_lift_aventos
                 when :wall_display then :wall_glass_display
                 when :top_bulkhead then :top_bulkhead_flap
                 when :island_prep then :island_gola_drawers
                 else :base_gola_drawers
                 end

      CabinetrixBoxEngine.create_cabinet(room_grp.entities, box_type, box_params, loc, mats)

      # 2. Extract Parts and Hardware from Catalogue Stencil
      if tmpl[:panels]
        extracted = tmpl[:panels].call(w, h, d).map do |p|
          p.merge(cab_id: cab_tag, part_id: "#{cab_tag}-#{p[:name]}", length: p[:len], width: p[:wid], material: p[:mat].to_s)
        end
        room_panels.concat(extracted)
      end

      if tmpl[:hardware]
        room_hardware.concat(tmpl[:hardware].call(w, h, d))
      end
    end

    { group: room_grp, panels: room_panels, hardware: room_hardware }
  end
end
