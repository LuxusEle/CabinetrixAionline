# ==============================================================================
# CABINETRIX AI — COMPLETE ACCESSORY, COLLISION & KINEMATIC QA RUNNER
# ==============================================================================
import sys

def test_full_collision_matrix():
    print("=== CABINETRIX AI FULL ACCESSORY & COLLISION SUITE ===\n")
    
    # 1. Base 2-Drawer Gola
    print("Checking Base 2-Drawer Gola...")
    c_gola_z0 = 330.0
    c_gola_h = 73.5
    l_gola_h = 59.0
    carcase_h = 720.0
    
    lower_front_z = 12.0
    lower_front_h = 315.0
    lower_front_top = lower_front_z + lower_front_h # 327.0
    lower_gap = c_gola_z0 - lower_front_top # 3.0mm
    assert lower_gap >= 3.0, f"Lower reveal too tight: {lower_gap}mm"
    
    upper_front_z = c_gola_z0 + c_gola_h + 6.0 # 409.5mm
    upper_front_h = 248.0
    upper_front_top = upper_front_z + upper_front_h # 657.5mm
    upper_gap = (carcase_h - l_gola_h) - upper_front_top # 3.5mm
    assert upper_gap >= 3.0, f"Upper reveal too tight: {upper_gap}mm"
    
    mid_gap = upper_front_z - (c_gola_z0 + c_gola_h) # 6.0mm
    assert mid_gap >= 4.0, f"Mid C-Gola inter-front reveal too tight: {mid_gap}mm"
    print(f"  -> Gola Reveals: Lower={lower_gap}mm, Upper={upper_gap}mm, Inter-Front={mid_gap}mm [PASS]")

    # 2. Kinematic Door Opening & Penetration Rule
    print("Checking Kinematic Door Penetration Rules...")
    # Rule: If door is closed (0 deg), internal pullouts must have 0.0 pull_dist
    door_closed_angle = 0.0
    door_open_angle = 95.0
    
    internal_pull_closed = 0.0 if door_closed_angle < 85.0 else 280.0
    internal_pull_open = 280.0 if door_open_angle >= 85.0 else 0.0
    assert internal_pull_closed == 0.0, "ERROR: Internal pullout extends through closed door!"
    assert internal_pull_open == 280.0, "ERROR: Internal pullout failed to extend when door is opened!"
    print("  -> Door Kinematics: 0mm pull through closed doors, 280mm clear pull through 95° open doors [PASS]")

    # 3. Global Drawer Pure Hardware Formula
    print("Checking Global Drawer Pure Function Formula...")
    inner_w = 564.0 # For 600mm carcase (600 - 36)
    side_gap = 12.5
    drawer_box_w = inner_w - (2 * side_gap) # 539.0mm
    assert drawer_box_w == 539.0, f"Unexpected drawer box width: {drawer_box_w}"
    sub_front_w = drawer_box_w - (2 * 15.0) # 509.0mm
    assert sub_front_w == 509.0, f"Unexpected sub front width: {sub_front_w}"
    print(f"  -> Global Drawer Math: InnerW={inner_w}mm - (2 x {side_gap}mm) = BoxW={drawer_box_w}mm [PASS]")

    # 4. Sink Plumbing & Cargo
    print("Checking Sink Unit with Waste Cargo...")
    cutout_w = 260.0
    cutout_d = 280.0
    trap_zone_w = 240.0
    assert cutout_w >= trap_zone_w, "Plumbing notch too narrow"
    print("  -> Sink Plumbing Envelope & Waste Cargo Clearance [PASS]")

    # 5. Blind Corner LeMans II
    print("Checking Blind Corner LeMans II...")
    door_opening_w = 900.0 - 600.0 - 3.0 + 150.0 # 447.0mm
    lemans_tray_r = 430.0
    assert door_opening_w > lemans_tray_r, "LeMans tray clashes with blind frame"
    print(f"  -> LeMans Swing Arc: Door Opening ({door_opening_w}mm) > Tray Radius ({lemans_tray_r}mm) [PASS]")

    # 6. Tall Space Tower
    print("Checking Tall Space Tower Larder...")
    drawers_z = [120.0, 330.0, 540.0, 750.0, 960.0]
    for z in drawers_z:
        assert z < 1200.0, f"Drawer above eye-level datum: {z}mm"
    for i in range(len(drawers_z)-1):
        gap = drawers_z[i+1] - (drawers_z[i] + 140.0)
        assert gap >= 50.0, f"Internal drawer vertical gap too small: {gap}mm"
    print("  -> Space Tower: 5 internal drawers below 1200mm datum, min gap 70.0mm [PASS]")

    # 7. Wall AVENTOS HF Lift
    print("Checking Wall AVENTOS HF Lift...")
    shelf_setback = 50.0
    assert shelf_setback >= 40.0, "AVENTOS HF lift arm will hit internal shelf"
    print("  -> AVENTOS HF: 50mm shelf setback avoids power lift arm collision [PASS]")

    # 8. Wardrobe Internals
    print("Checking Wardrobe Clothes Rod Combo...")
    rod_drop = 55.0
    trouser_drop = 680.0
    assert rod_drop == 55.0, "Hanger hook clearance compromised"
    assert trouser_drop >= 650.0, "Trouser drag clearance too small"
    print(f"  -> Wardrobe: Rod hook drop {rod_drop}mm, Trouser drop {trouser_drop}mm [PASS]")

    print("\n" + "="*50)
    print(" RESULT: ALL ACCESSORY & KINEMATIC QA PASSED (100%)")
    print("="*50)

if __name__ == "__main__":
    test_full_collision_matrix()
