# ==============================================================================
# CABINETRIX AI — ACCESSORY ENVELOPE & COLLISION AVOIDANCE ENGINE
# Module: CabinetrixCollisionEngine
#
# Production Standard:
#   • GLOBAL DRAWER HARDWARE FUNCTION:
#     - Pure Hardware Formula: Drawer Box Width = Internal Width - (2 * Side Gap)
#     - Never hardcoded. Dynamically computed for Blum Legrabox, Hettich Actro 5D, Grass Nova Pro.
#   • SCILM Gola System Catalog & Vertical Profiles
#   • IKEA METOD & PAX KOMPLEMENT Planning & Assembly Manuals
#   • Australian / European Cabinetmaking Training Guides
# ==============================================================================

module CabinetrixCollisionEngine
  # ----------------------------------------------------------------------------
  # 1. HARDWARE & ACCESSORY OCCUPANCY ENVELOPES (Keep-Out & Mounting Zones)
  # ----------------------------------------------------------------------------
  ENVELOPES = {
    # Corner mechanisms
    lemans_corner: {
      min_cabinet_w: 900.0,
      min_cabinet_d: 500.0,
      min_door_opening_w: 450.0,
      tray_clearance_radius: 430.0,
      min_tray_vertical_gap: 200.0,
      shelf_thickness: 20.0,
      hinge_clearance_angle: 110.0 # Requires >= 110 deg hinge or zero-protrusion
    },
    magic_corner: {
      min_cabinet_w: 900.0,
      min_cabinet_d: 520.0,
      min_door_opening_w: 450.0,
      front_pull_travel: 450.0,
      side_swing_clearance: 380.0
    },

    # Pullouts & Larders
    dispensa_junior: {
      widths: [150.0, 200.0, 300.0],
      min_depth: 480.0,
      min_height: 600.0,
      runner_bottom_clearance: 25.0,
      side_clearance: 12.0
    },
    space_tower: {
      min_width: 300.0,
      max_width: 1200.0,
      min_depth: 450.0,
      drawer_pitch: 210.0,
      max_drawer_elevation_eye_level: 1400.0, # Space Tower Rule: Shelves above eye level, Drawers below
      hinge_side_spacer_offset: 25.0,        # Required when using 110° hinges
      zero_protrusion_hinge_angle: 155.0     # 155° or 170° hinges remove the need for side spacers
    },

    # Sink & Plumbing Keep-Out Envelopes
    sink_plumbing_envelope: {
      basin_drop_min: 180.0,
      basin_drop_max: 230.0,
      trap_cutout_width: 280.0,
      trap_cutout_depth: 300.0,
      top_false_front_min_h: 220.0,
      waste_bin_min_height_clearance: 320.0
    },

    # Cooktop Heat & Air Envelopes
    cooktop_ventilation: {
      subtop_air_gap: 20.0,
      heat_shield_drop: 60.0, # Drawer sub-front must be >= 60mm below countertop
      rear_vent_chimney_d: 20.0
    },

    # Lift Systems (AVENTOS / FREElift)
    wall_lift_mechanisms: {
      aventos_hf: { min_internal_d: 264.0, mechanism_box: [150.0, 35.0, 150.0], shelf_front_setback: 50.0 },
      aventos_hk_top: { min_internal_d: 220.0, mechanism_box: [120.0, 30.0, 120.0], shelf_front_setback: 40.0 },
      aventos_hki: { min_internal_d: 271.0, integrated_in_gable: true }
    },

    # Wardrobe / KOMPLEMENT Accessories
    wardrobe_organizers: {
      clothes_rail: {
        min_depth: 500.0,
        rod_drop_from_top_shelf: 55.0, # 55mm drop allows hanger hooks to clear top shelf effortlessly
        rod_center_from_rear: 300.0,
        single_hang_clearance: 1600.0, # For coats / long dresses
        double_hang_tier_clearance: 950.0 # For shirts / trousers
      },
      trouser_pullout: {
        min_depth: 550.0,
        vertical_drop_clearance: 650.0, # Prevents hanging trousers from dragging on bottom shelf
        slide_reveal: 12.5
      },
      sloping_shoe_rack: {
        pitch_angle_deg: 25.0,
        min_tier_height: 220.0,
        min_depth: 350.0
      },
      jewellery_tray: {
        tray_height: 60.0,
        glass_shelf_clearance: 25.0,
        min_depth: 450.0
      },
      internal_drawers: {
        slide_thickness: 12.5,
        hinge_spacer_offset: 25.0,
        min_vertical_margin: 20.0,
        sliding_door_zone_margin: 80.0
      }
    }
  }

  # ----------------------------------------------------------------------------
  # 2. GLOBAL DRAWER GEOMETRY FUNCTION (PURE HARDWARE FORMULA)
  # ----------------------------------------------------------------------------
  # Formula: Drawer Box Width = Internal Width - (2 * Drawer Side Gap)
  def self.calculate_drawer_geometry(internal_w, internal_d = 560.0, side_gap: 12.5, box_thk: 15.0, front_h: 248.0, runner_len: 450.0, hinge_spacer: 0.0)
    total_side_reveal = side_gap + hinge_spacer
    box_w = internal_w - (2.0 * total_side_reveal)
    sub_front_w = box_w - (2.0 * box_thk)
    bottom_w = box_w - (2.0 * box_thk)
    bottom_d = runner_len - (2.0 * box_thk)
    max_box_h = [front_h - 40.0, 200.0].min

    {
      internal_w: internal_w,
      internal_d: internal_d,
      side_gap: side_gap,
      hinge_spacer: hinge_spacer,
      total_side_reveal: total_side_reveal,
      box_w: box_w,
      box_d: runner_len,
      box_h: max_box_h,
      sub_front_w: sub_front_w,
      bottom_w: bottom_w,
      bottom_d: bottom_d,
      box_thk: box_thk,
      slide_w: 11.0,
      slide_h: 24.0
    }
  end

  # ----------------------------------------------------------------------------
  # 3. GOLA HANDLELESS CLEARANCE & REVEAL CALCULATOR
  # ----------------------------------------------------------------------------
  def self.calculate_gola_drawer_geometry(carcase_h, bz, gola_d = 26.0, c_gola_z0 = 330.0, c_gola_h = 73.5, l_gola_h = 59.0)
    lower_front_z = bz + 12.0
    lower_front_h = (bz + c_gola_z0 - 3.0) - lower_front_z # 315mm

    upper_front_z = bz + c_gola_z0 + c_gola_h + 6.0 # 409.5mm
    upper_front_top = bz + carcase_h - l_gola_h - 3.5 # 657.5mm
    upper_front_h = upper_front_top - upper_front_z # 248mm

    {
      lower: { front_z: lower_front_z, front_h: lower_front_h, box_h: 200.0, max_slide_len: 450.0 },
      upper: { front_z: upper_front_z, front_h: upper_front_h, box_h: 120.0, max_slide_len: 450.0 },
      c_gola_channel: { z_min: bz + c_gola_z0, z_max: bz + c_gola_z0 + c_gola_h },
      l_gola_channel: { z_min: bz + carcase_h - l_gola_h, z_max: bz + carcase_h },
      reveals: {
        lower_to_c_gola_lip: 3.0,
        c_gola_lip_to_upper_bottom: 6.0,
        upper_to_l_gola_lip: 3.5,
        subtop_finger_channel: 35.0
      }
    }
  end

  # ----------------------------------------------------------------------------
  # 4. WARDROBE INTERNALS & HINGE/SLIDER COLLISION RESOLVER
  # ----------------------------------------------------------------------------
  def self.calculate_wardrobe_internal_layout(width, height, depth, carcase_thk = 18.0, door_type = :hinged, hinge_type = :zero_protrusion)
    inner_w = width - (2 * carcase_thk)
    inner_d = depth - (carcase_thk + 6.0)

    drawer_side_clearance = if door_type == :hinged
      (hinge_type == :zero_protrusion) ? 12.5 : (12.5 + ENVELOPES[:space_tower][:hinge_side_spacer_offset])
    else
      12.5
    end

    drawer_dims = calculate_drawer_geometry(inner_w, inner_d, side_gap: 12.5, hinge_spacer: (drawer_side_clearance - 12.5))

    top_shelf_z = height - 350.0
    clothes_rod_z = top_shelf_z - ENVELOPES[:wardrobe_organizers][:clothes_rail][:rod_drop_from_top_shelf]
    mid_shelf_z = 1050.0

    {
      inner_w: inner_w,
      inner_d: inner_d,
      drawer_w: drawer_dims[:box_w],
      drawer_dims: drawer_dims,
      drawer_side_clearance: drawer_side_clearance,
      top_shelf_z: top_shelf_z,
      clothes_rod_z: clothes_rod_z,
      mid_shelf_z: mid_shelf_z,
      hanging_drop: (clothes_rod_z - mid_shelf_z),
      safe_for_drawers: (door_type == :sliding || hinge_type == :zero_protrusion || drawer_side_clearance >= 37.5)
    }
  end

  # ----------------------------------------------------------------------------
  # 5. 3D BOUNDING BOX CLASH DETECTION & INTERFERENCE ANALYZER
  # ----------------------------------------------------------------------------
  def self.box_intersects?(bb1_min, bb1_max, bb2_min, bb2_max, tolerance = 0.5)
    overlap_x = [0.0, [bb1_max[0], bb2_max[0]].min - [bb1_min[0], bb2_min[0]].max].max
    overlap_y = [0.0, [bb1_max[1], bb2_max[1]].min - [bb1_min[1], bb2_min[1]].max].max
    overlap_z = [0.0, [bb1_max[2], bb2_max[2]].min - [bb1_min[2], bb2_min[2]].max].max

    if overlap_x > tolerance && overlap_y > tolerance && overlap_z > tolerance
      [overlap_x, overlap_y, overlap_z]
    else
      nil
    end
  end

  def self.evaluate_clash(name_a, bb_a_min, bb_a_max, name_b, bb_b_min, bb_b_max)
    overlap = box_intersects?(bb_a_min, bb_a_max, bb_b_min, bb_b_max, 1.0)
    return nil unless overlap

    na = name_a.to_s.downcase
    nb = name_b.to_s.downcase

    # Allowed / Intended Structural Connections
    is_dowel_or_cam = na.include?('minifix') || nb.include?('minifix') || na.include?('dowel') || nb.include?('dowel') || na.include?('catch') || nb.include?('catch')
    is_grooved_back = (na.include?('back') && nb.include?('gable')) || (nb.include?('back') && na.include?('gable'))
    is_slide_to_side = (na.include?('slide') && (nb.include?('gable') || nb.include?('side'))) || (nb.include?('slide') && (na.include?('gable') || na.include?('side')))

    return nil if is_dowel_or_cam || is_grooved_back || is_slide_to_side

    # CRITICAL Functional Clashes
    if (na.include?('gola') && (nb.include?('drawer') || nb.include?('front'))) || (nb.include?('gola') && (na.include?('drawer') || na.include?('front')))
      return {
        severity: :critical,
        category: "Gola_Drawer_Clash",
        part_a: name_a,
        part_b: name_b,
        overlap_mm: overlap.map { |v| v.round(2) },
        recommendation: "Increase Gola reveal gap or adjust drawer front vertical datum."
      }
    end

    if (na.include?('drawer_front') && nb.include?('drawer_front')) || (na.include?('front_face') && nb.include?('front_face'))
      return {
        severity: :critical,
        category: "Inter_Front_Clash",
        part_a: name_a,
        part_b: name_b,
        overlap_mm: overlap.map { |v| v.round(2) },
        recommendation: "Ensure 3mm inter-front reveal gap."
      }
    end

    if (na.include?('oven') && nb.include?('shelf')) || (nb.include?('oven') && na.include?('shelf'))
      return {
        severity: :critical,
        category: "Appliance_Shelf_Clash",
        part_a: name_a,
        part_b: name_b,
        overlap_mm: overlap.map { |v| v.round(2) },
        recommendation: "Reposition structural shelf outside appliance body envelope."
      }
    end

    if (na.include?('rod') && nb.include?('shelf')) || (nb.include?('rod') && na.include?('shelf'))
      return {
        severity: :high,
        category: "Wardrobe_Rod_Shelf_Clash",
        part_a: name_a,
        part_b: name_b,
        overlap_mm: overlap.map { |v| v.round(2) },
        recommendation: "Position clothes rod 55mm below shelf bottom."
      }
    end

    {
      severity: :medium,
      category: "Solid_Body_Interference",
      part_a: name_a,
      part_b: name_b,
      overlap_mm: overlap.map { |v| v.round(2) },
      recommendation: "Verify panel sizing and bounding coordinates."
    }
  end
end
