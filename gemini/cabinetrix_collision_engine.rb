# ==============================================================================
# CABINETRIX AI — ACCESSORY ENVELOPE & COLLISION AVOIDANCE ENGINE
# Module: CabinetrixCollisionEngine
#
# Production Standard:
#   • KINEMATIC DOOR-PENETRATION COLLISION RULE:
#     - "Nothing goes through doors unless door is opened."
#     - Internal drawers, trouser pullouts, and accessories can ONLY extend if front doors are opened (>= 90°).
#     - When doors are closed, all internal components MUST have pull_offset = 0.0 (inside carcase).
#   • GLOBAL DRAWER HARDWARE FUNCTION:
#     - Drawer Box Width = Internal Width - (2 * Side Gap)
#   • SCILM Gola System Catalog & Vertical Profiles
#   • IKEA METOD & PAX KOMPLEMENT Planning & Assembly Manuals
# ==============================================================================

module CabinetrixCollisionEngine
  ENVELOPES = {
    lemans_corner: {
      min_cabinet_w: 900.0,
      min_cabinet_d: 500.0,
      min_door_opening_w: 450.0,
      tray_clearance_radius: 430.0,
      min_tray_vertical_gap: 200.0,
      shelf_thickness: 20.0,
      hinge_clearance_angle: 110.0
    },
    magic_corner: {
      min_cabinet_w: 900.0,
      min_cabinet_d: 520.0,
      min_door_opening_w: 450.0,
      front_pull_travel: 450.0,
      side_swing_clearance: 380.0
    },
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
      max_drawer_elevation_eye_level: 1400.0,
      hinge_side_spacer_offset: 25.0,
      zero_protrusion_hinge_angle: 155.0
    },
    sink_plumbing_envelope: {
      basin_drop_min: 180.0,
      basin_drop_max: 230.0,
      trap_cutout_width: 280.0,
      trap_cutout_depth: 300.0,
      top_false_front_min_h: 220.0,
      waste_bin_min_height_clearance: 320.0
    },
    cooktop_ventilation: {
      subtop_air_gap: 20.0,
      heat_shield_drop: 60.0,
      rear_vent_chimney_d: 20.0
    },
    wall_lift_mechanisms: {
      aventos_hf: { min_internal_d: 264.0, mechanism_box: [150.0, 35.0, 150.0], shelf_front_setback: 50.0 },
      aventos_hk_top: { min_internal_d: 220.0, mechanism_box: [120.0, 30.0, 120.0], shelf_front_setback: 40.0 },
      aventos_hki: { min_internal_d: 271.0, integrated_in_gable: true }
    },
    wardrobe_organizers: {
      clothes_rail: {
        min_depth: 500.0,
        rod_drop_from_top_shelf: 55.0,
        rod_center_from_rear: 300.0,
        single_hang_clearance: 1600.0,
        double_hang_tier_clearance: 950.0
      },
      trouser_pullout: {
        min_depth: 550.0,
        vertical_drop_clearance: 650.0,
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
  # 2. GLOBAL DRAWER GEOMETRY FUNCTION
  # Formula: Drawer Box Width = Internal Width - (2 * Side Gap)
  # ----------------------------------------------------------------------------
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
    lower_front_h = (bz + c_gola_z0 - 3.0) - lower_front_z

    upper_front_z = bz + c_gola_z0 + c_gola_h + 6.0
    upper_front_top = bz + carcase_h - l_gola_h - 3.5
    upper_front_h = upper_front_top - upper_front_z

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
  # 4. KINEMATIC DOOR INTERFERENCE VALIDATOR
  # ----------------------------------------------------------------------------
  def self.validate_internal_pullout_kinematics(has_outer_door, door_open_angle_deg, requested_pull_dist)
    if has_outer_door && door_open_angle_deg < 85.0
      # Door is closed or insufficiently opened: pullout cannot extend
      { safe_pull_dist: 0.0, door_must_open: true, status: :blocked_by_door }
    else
      { safe_pull_dist: requested_pull_dist, door_must_open: false, status: :clear }
    end
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

    # CRITICAL Functional Clashes:
    # 1. Door Penetration (Internal pullout sticking through a door)
    if (na.include?('door') && (nb.include?('drawer') || nb.include?('trouser') || nb.include?('rack') || nb.include?('tray') || nb.include?('pullout'))) ||
       (nb.include?('door') && (na.include?('drawer') || na.include?('trouser') || na.include?('rack') || na.include?('tray') || na.include?('pullout')))
      return {
        severity: :critical,
        category: "Door_Penetration_Clash",
        part_a: name_a,
        part_b: name_b,
        overlap_mm: overlap.map { |v| v.round(2) },
        recommendation: "Open front doors before extending internal drawers / pullouts."
      }
    end

    # 2. Gola Drawer Clash
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

    # 3. Inter Front Clash
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

    # 4. Appliance Shelf Clash
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
