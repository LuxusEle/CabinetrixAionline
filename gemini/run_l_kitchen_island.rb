# =============================================================================
# CABINETRIX — ADVANCED L-KITCHEN + ISLAND (GEMINI MODULE)
# (c) 2026 Cabinex AI.
#
#   • Gola finger-pull OVERLAP fronts (top front into L-Gola, bottom front into C-Gola)
#   • facing_dir-aware Gola profile: wall run channel opens -Y, island +Y.
#   • Authentic 5-piece recessed-bottom undermount drawer box on concealed runners.
#   • Selective CNC drilling — only where hardware connects.
#   • Modular Box_01..N hierarchy, atomic named panels.
#   • 18mm board, Minifix joints, System 32 coordinates.
#
# USAGE (SketchUp Ruby console):
#   load "C:/Users/asank/Documents/CabinetrixAionline/gemini/run_l_kitchen_island.rb"
#   RunLKitchen.build
# =============================================================================
require 'sketchup.rb'

module RunLKitchen
  # ---- parameters (metric standards) ----
  B = 18.0.mm; FRONT = 18.0.mm; BOX = 15.0.mm; BACK = 6.0.mm; WORKTOP = 20.0.mm
  PLINTH = 100.0.mm; PLINTH_SET = 50.0.mm
  BASE_H = 720.0.mm; BASE_D = 560.0.mm; WT_D = 600.0.mm
  WALL_H = 720.0.mm; WALL_D = 350.0.mm; WALL_Z0 = 1440.0.mm
  TALL_H = 2160.0.mm; TALL_D = 600.0.mm
  GOLA_D = 26.0.mm; L_H = 56.5.mm; C_H = 73.0.mm; L_GOLA_H = 59.0.mm; C_GOLA_H = 73.5.mm; C_Z0 = 330.0.mm
  MINIFIX_CAM_D = 15.0.mm; MINIFIX_DEPTH = 12.5.mm; MINIFIX_B = 34.0.mm
  DOWEL_D = 8.0.mm; DOWEL_L = 30.0.mm
  U_FRONT_H = 310.0.mm; L_FRONT_H = 355.0.mm   # Gola overlap fronts
  GAP = 40.0.mm

  # ---- materials (photo-realistic solid palette) ----
  def self.mats(model)
    m = model.materials
    o = ->(name, rgb, alpha = 1.0) { x = m[name] || m.add(name); x.color = Sketchup::Color.new(*rgb); x.alpha = alpha; x }
    {
      carcase: o.call('CBX_Melamine_White', [245, 245, 242]),
      front: o.call('CBX_Front_Anthracite', [42, 45, 50]),
      gola: o.call('CBX_Alu_Black_Anodized', [25, 27, 30]),
      marble: o.call('CBX_Calacatta_Marble', [248, 246, 242]),
      glass: o.call('CBX_Clear_Glass', [210, 235, 245], 0.35),
      cam: o.call('CBX_Minifix_Zinc', [180, 185, 190]),
      steel: o.call('CBX_Stainless_Steel', [140, 145, 155]),
      wood: o.call('CBX_Natural_Birch', [225, 212, 190]),
      hole: o.call('CBX_CNC_Bore_Dark', [20, 20, 20]),
      accent: o.call('CBX_Indicator_Orange', [240, 80, 20]),
      led: o.call('CBX_LED_Warm_Glow', [255, 245, 210]),
      plinth: o.call('CBX_Plinth_Black', [30, 32, 35])
    }
  end

  # ---- geometry helpers ----
  def self.box(parent, origin, size, material = nil, name = nil)
    g = parent.add_group
    g.name = name if name
    x, y, z = size; ox, oy, oz = origin
    pts = [Geom::Point3d.new(ox, oy, oz), Geom::Point3d.new(ox + x, oy, oz),
           Geom::Point3d.new(ox + x, oy + y, oz), Geom::Point3d.new(ox, oy + y, oz)]
    f = g.entities.add_face(pts)
    f.reverse! if f && f.normal.z < 0
    f.pushpull(z) if f
    g.material = material if material
    tag(g, name)
    g
  end

  def self.cyl(parent, center, normal, radius, height, material = nil, seg = 12, name = nil)
    return nil if radius <= 0 || height <= 0
    g = parent.add_group
    c = g.entities.add_circle(center, normal, radius, seg)
    f = g.entities.add_face(c)
    f.reverse! if f && f.normal.dot(normal) < 0
    f.pushpull(height) if f
    g.material = material if material
    tag(g, name)
    g
  end

  def self.tag(g, role)
    g.set_attribute('CBX', 'role', role) if role
    g
  end

  # ---- Minifix 15 joint (direction-vector; selective drilling) ----
  def self.minifix(parent, bc, dir, mats, cam_normal = Geom::Vector3d.new(0, 0, 1), cam_off = B / 2.0)
    inv = dir.reverse
    cyl(parent, bc, inv, 2.5.mm, 11.0.mm, mats[:steel], 12, 'Bolt_Thread')
    cyl(parent, bc, dir, 3.75.mm, 1.5.mm, mats[:steel], 12, 'Bolt_Collar')
    ps = Geom::Point3d.new(bc.x + dir.x * 1.5.mm, bc.y + dir.y * 1.5.mm, bc.z + dir.z * 1.5.mm)
    cyl(parent, ps, dir, 3.25.mm, 32.5.mm, mats[:steel], 12, 'Bolt_Pin')
    cp = Geom::Point3d.new(bc.x + cam_normal.x * cam_off, bc.y + cam_normal.y * cam_off, bc.z + cam_normal.z * cam_off)
    vis = Geom::Point3d.new(cp.x + cam_normal.x * 0.3.mm, cp.y + cam_normal.y * 0.3.mm, cp.z + cam_normal.z * 0.3.mm)
    rim = parent.entities.add_circle(vis, cam_normal, (MINIFIX_CAM_D / 2.0) + 0.3.mm, 18)
    fr = parent.entities.add_face(rim); fr.material = mats[:hole] if fr
    cyl(parent, vis, cam_normal.reverse, MINIFIX_CAM_D / 2.0, MINIFIX_DEPTH, mats[:cam], 18, 'Cam_Body')
    dowel = Geom::Point3d.new(bc.x - dir.x * 10.mm, bc.y - dir.y * 10.mm, bc.z)
    cyl(parent, dowel, dir, DOWEL_D / 2.0, DOWEL_L, mats[:wood], 16, 'Dowel_Align')
  end

  # ---- Gola profile, facing_dir-aware (channel opens -Y wall / +Y island) ----
  def self.gola(parent, type, length, origin, mats, facing: :front)
    g = parent.add_group
    g.name = "Gola_#{type.to_s.upcase}_#{length.to_mm.round}mm"
    ox, oy, oz = origin.x, origin.y, origin.z
    yz = if type == :l
           [[0, 0], [1.5.mm, 0], [1.5.mm, 45.mm], [3.mm, 49.mm], [6.mm, 52.mm], [10.mm, 54.mm],
            [GOLA_D, 54.mm], [GOLA_D, L_H], [8.mm, L_H], [3.mm, 54.mm], [0, 48.mm]]
         else
           [[GOLA_D, 0], [GOLA_D, 3.5.mm], [10.mm, 3.5.mm], [5.mm, 6.mm], [1.5.mm, 12.mm],
            [1.5.mm, 61.mm], [5.mm, 67.mm], [10.mm, 69.5.mm], [GOLA_D, 69.5.mm], [GOLA_D, C_H],
            [8.mm, C_H], [3.mm, 70.mm], [0, 64.mm], [0, 9.mm], [3.mm, 3.mm], [8.mm, 0]]
         end
    if facing == :front
      yz = yz.map { |y, z| [GOLA_D - y, z] }
      yz = yz.map { |y, z| [y, L_H - z] } if type == :l
      pts = yz.map { |y, z| Geom::Point3d.new(ox, oy - y, oz + z) }
    else # :island -> channel opens +Y
      yz = yz.map { |y, z| [y, L_H - z] } if type == :l
      pts = yz.map { |y, z| Geom::Point3d.new(ox, oy + y, oz + z) }
    end
    f = g.entities.add_face(pts)
    f.reverse! if f && f.normal.x < 0
    f.pushpull(length) if f
    g.material = mats[:gola]
    tag(g, g.name)
    g
  end

  # ---- machined Gola side gable (L + C notches, 26mm deep) ----
  def self.gable(parent, x, y, oz, h, c_z0, d, mats)
    g = parent.add_group
    g.name = 'Gable_Gola_Machined'
    l_z0 = h - L_GOLA_H; l_z1 = h; c_z1 = c_z0 + C_GOLA_H
    pts = [
      Geom::Point3d.new(x, y, oz), Geom::Point3d.new(x, y - d, oz),
      Geom::Point3d.new(x, y - d, oz + c_z0), Geom::Point3d.new(x, y - d + GOLA_D, oz + c_z0),
      Geom::Point3d.new(x, y - d + GOLA_D, oz + c_z1), Geom::Point3d.new(x, y - d, oz + c_z1),
      Geom::Point3d.new(x, y - d, oz + l_z0), Geom::Point3d.new(x, y - d + GOLA_D, oz + l_z0),
      Geom::Point3d.new(x, y - d + GOLA_D, oz + l_z1), Geom::Point3d.new(x, y, oz + l_z1)
    ]
    f = g.entities.add_face(pts)
    f.reverse! if f && f.normal.x < 0
    f.pushpull(B) if f
    g.material = mats[:carcase]
    tag(g, 'Gable_Gola_Machined')
    g
  end

  # ---- 5-piece recessed-bottom undermount drawer box (rides in opening) ----
  def self.drawer(box_parent, origin, width, depth, box_height, front_h, front_zoff, pull, mats, front_mat, dir_y: -1, name: 'Drawer')
    unit = box_parent.add_group
    unit.name = name
    ox = origin.x; oy = origin.y + (dir_y * pull); oz = origin.z
    if dir_y == -1
      box(unit.entities, [ox, oy - FRONT, oz + front_zoff], [width, FRONT, front_h], front_mat, 'Drawer_Front')
    else
      box(unit.entities, [ox, oy, oz + front_zoff], [width, FRONT, front_h], front_mat, 'Drawer_Front')
    end
    bw = width - (2 * 12.5.mm); bd = depth - 30.0.mm
    box_ox = ox + 12.5.mm; box_oz = oz + 15.0.mm
    if dir_y == -1
      box_oy = oy
      box(unit.entities, [box_ox, box_oy, box_oz], [BOX, bd, box_height], mats[:wood], 'Drawer_Side_L')
      box(unit.entities, [box_ox + bw - BOX, box_oy, box_oz], [BOX, bd, box_height], mats[:wood], 'Drawer_Side_R')
      iw = bw - 2 * BOX
      box(unit.entities, [box_ox + BOX, box_oy, box_oz], [iw, BOX, box_height], mats[:wood], 'Drawer_SubFront')
      box(unit.entities, [box_ox + BOX, box_oy + bd - BOX, box_oz], [iw, BOX, box_height], mats[:wood], 'Drawer_Back')
      box(unit.entities, [box_ox + BOX, box_oy, box_oz + 12.mm], [iw, bd - BOX, 16.0.mm], mats[:wood], 'Drawer_Bottom')
      box(unit.entities, [ox + 1.0.mm, oy, oz + 2.mm], [11.0.mm, bd, 24.0.mm], mats[:steel], 'Actro5D_Slide_L')
      box(unit.entities, [ox + width - 12.0.mm, oy, oz + 2.mm], [11.0.mm, bd, 24.0.mm], mats[:steel], 'Actro5D_Slide_R')
      cyl(unit.entities, Geom::Point3d.new(ox - 0.2.mm, oy + 37.mm, oz + 12.mm), Geom::Vector3d.new(-1, 0, 0), 2.5.mm, 4.0.mm, mats[:hole], 12, 'Slide_Pilot_L')
    else
      box_oy = oy - bd
      box(unit.entities, [box_ox, box_oy, box_oz], [BOX, bd, box_height], mats[:wood], 'Drawer_Side_L')
      box(unit.entities, [box_ox + bw - BOX, box_oy, box_oz], [BOX, bd, box_height], mats[:wood], 'Drawer_Side_R')
      iw = bw - 2 * BOX
      box(unit.entities, [box_ox + BOX, box_oy, box_oz], [iw, BOX, box_height], mats[:wood], 'Drawer_SubFront')
      box(unit.entities, [box_ox + BOX, oy - BOX, box_oz], [iw, BOX, box_height], mats[:wood], 'Drawer_Back')
      box(unit.entities, [box_ox + BOX, box_oy + BOX, box_oz + 12.mm], [iw, bd - 2 * BOX, 16.0.mm], mats[:wood], 'Drawer_Bottom')
      box(unit.entities, [ox + 1.0.mm, box_oy, oz + 2.mm], [11.0.mm, bd, 24.0.mm], mats[:steel], 'Actro5D_Slide_L')
      box(unit.entities, [ox + width - 12.0.mm, box_oy, oz + 2.mm], [11.0.mm, bd, 24.0.mm], mats[:steel], 'Actro5D_Slide_R')
    end
    unit
  end

  # =========================================================================
  # BOXES (atomic named panels, selective drilling)
  # =========================================================================
  def self.box_tall_oven(g, x, y, oz, mats, m)
    w = 600.mm; d = TALL_D; h = TALL_H; iw = w - 2 * B
    box(g.entities, [x, y - d, oz], [B, d, h], mats[:carcase], 'Gable_L')
    box(g.entities, [x + w - B, y - d, oz], [B, d, h], mats[:carcase], 'Gable_R')
    box(g.entities, [x + B, y - d, oz], [iw, d, B], mats[:carcase], 'Bottom')
    box(g.entities, [x + B, y - d, oz + h - B], [iw, d, B], mats[:carcase], 'Top')
    box(g.entities, [x + B, y - 18.mm, oz + B], [iw, BACK, h - 2 * B], mats[:carcase], 'Back')
    box(g.entities, [x + B, y - d, oz + 400.mm], [iw, d, B], mats[:carcase], 'Oven_Support_Shelf')
    box(g.entities, [x + B + 2.mm, y - d - 8.mm, oz + 430.mm], [iw - 4.mm, 8.mm, 410.mm], mats[:steel], 'Oven_Lower_Face')
    box(g.entities, [x + B + 2.mm, y - d - 8.mm, oz + 940.mm], [iw - 4.mm, 8.mm, 410.mm], mats[:steel], 'Oven_Upper_Face')
    box(g.entities, [x + B + 12.mm, y - d - 14.mm, oz + 445.mm], [iw - 24.mm, 4.mm, 380.mm], mats[:glass], 'Oven_Upper_Glass')
    minifix(g.entities, Geom::Point3d.new(x + B, y - 70.mm, oz + B / 2.0), Geom::Vector3d.new(1, 0, 0), mats)
    minifix(g.entities, Geom::Point3d.new(x + B, y - d + 70.mm, oz + B / 2.0), Geom::Vector3d.new(1, 0, 0), mats)
    minifix(g.entities, Geom::Point3d.new(x + w - B, y - 70.mm, oz + B / 2.0), Geom::Vector3d.new(-1, 0, 0), mats)
    minifix(g.entities, Geom::Point3d.new(x + w - B, y - d + 70.mm, oz + B / 2.0), Geom::Vector3d.new(-1, 0, 0), mats)
    box(g.entities, [x + 10.mm, y - d + PLINTH_SET, oz - PLINTH], [w - 20.mm, B, PLINTH], mats[:plinth], 'Plinth')
  end

  def self.box_base(g, x, y, oz, mats, m, label:, boxes: 2, front_mat: nil)
    w = 600.mm; d = BASE_D; h = BASE_H; iw = w - 2 * B
    front_mat ||= mats[:front]
    gable(g.entities, x, y, oz, h, C_Z0, d, mats)
    gable(g.entities, x + w - B, y, oz, h, C_Z0, d, mats)
    box(g.entities, [x + B, y - d, oz], [iw, d, B], mats[:carcase], 'Bottom')
    box(g.entities, [x + B, y - 100.mm, oz + h - B], [iw, 100.mm, B], mats[:carcase], 'Stretcher_Rear')
    box(g.entities, [x + B, y - d + GOLA_D, oz + h - B], [iw, 80.mm, B], mats[:carcase], 'Stretcher_Gola')
    box(g.entities, [x + B, y - d + GOLA_D, oz + C_Z0 + C_GOLA_H - B], [iw, 60.mm, B], mats[:carcase], 'Stretcher_CGola')
    box(g.entities, [x + B, y - 18.mm, oz + B], [iw, BACK, h - B - 10.mm], mats[:carcase], 'Back')
    gola(g.entities, :l, w - B, Geom::Point3d.new(x + B, y - d + GOLA_D, oz + h - L_GOLA_H), mats, facing: :front)
    gola(g.entities, :c, w - B, Geom::Point3d.new(x + B, y - d + GOLA_D, oz + C_Z0), mats, facing: :front)
    fw = w - 3.0.mm
    drawer(g.entities, Geom::Point3d.new(x + 1.5.mm, y - d, oz + 12.mm), fw, d, 200.mm, L_FRONT_H, -9.mm, 0, mats, front_mat, dir_y: -1, name: 'Drawer_Lower')
    drawer(g.entities, Geom::Point3d.new(x + 1.5.mm, y - d, oz + 390.mm), fw, d, 140.mm, U_FRONT_H, -15.mm, 0, mats, front_mat, dir_y: -1, name: 'Drawer_Upper')
    box(g.entities, [x + 10.mm, y - d + PLINTH_SET, oz - PLINTH], [w - 20.mm, B, PLINTH], mats[:plinth], 'Plinth')
  end

  def self.box_glass_wall(g, x, y, oz, mats, m, w: 600.mm, doors: 1)
    d = WALL_D; h = WALL_H; iw = w - 2 * B
    box(g.entities, [x, y - d, oz], [B, d, h], mats[:carcase], 'Gable_L')
    box(g.entities, [x + w - B, y - d, oz], [B, d, h], mats[:carcase], 'Gable_R')
    box(g.entities, [x + B, y - d, oz + h - B], [iw, d, B], mats[:carcase], 'Top')
    box(g.entities, [x + B, y - d, oz], [iw, d, B], mats[:carcase], 'Bottom')
    box(g.entities, [x + B, y - 18.mm, oz + B], [iw, BACK, h - 2 * B], mats[:carcase], 'Back')
    box(g.entities, [x + B + 5.mm, y - d + 15.mm, oz + 240.mm], [iw - 10.mm, d - 30.mm, 8.mm], mats[:glass], 'Glass_Shelf')
    box(g.entities, [x + B + 10.mm, y - d + 40.mm, oz + h - B - 10.mm], [iw - 20.mm, 15.mm, 6.mm], mats[:led], 'LED_Strip')
    dw = (w - 3.0.mm) / doors
    doors.times do |i|
      sash(g.entities, x + 1.5.mm + (i * dw), y - d, oz, dw, h, mats)
    end
  end

  def self.sash(parent, ox, oy, oz, width, height, mats)
    g = parent.add_group
    g.name = "Alu_Sash_Glass_Door_#{width.to_mm.round}x#{height.to_mm.round}"
    fw = 45.0.mm; fd = 21.2.mm; gt = 4.0.mm
    box(g.entities, [ox, oy - fd, oz + height - fw], [width, fd, fw], mats[:gola], 'Sash_Top')
    box(g.entities, [ox, oy - fd, oz], [width, fd, fw], mats[:gola], 'Sash_Bottom')
    box(g.entities, [ox, oy - fd, oz + fw], [fw, fd, height - 2 * fw], mats[:gola], 'Sash_Stile_L')
    box(g.entities, [ox + width - fw, oy - fd, oz + fw], [fw, fd, height - 2 * fw], mats[:gola], 'Sash_Stile_R')
    box(g.entities, [ox + fw - 5.mm, oy - (fd / 2.0) - (gt / 2.0), oz + fw - 5.mm], [width - 2 * fw + 10.mm, gt, height - 2 * fw + 10.mm], mats[:glass], 'Glass_Pane')
    [oz + 90.mm, oz + height - 90.mm].each do |hz|
      cyl(g.entities, Geom::Point3d.new(ox + 22.5.mm, oy - (fd / 2.0), hz), Geom::Vector3d.new(0, 1, 0), 17.5.mm, 12.8.mm, mats[:cam], 18, 'Hinge_Cup_35mm')
    end
    g
  end

  def self.box_island_drawers(g, x, y, oz, mats, m, w: 600.mm, label: 'Island_Drawers')
    d = BASE_D; h = BASE_H; iw = w - 2 * B
    gable(g.entities, x, y + d, oz, h, C_Z0, d, mats, island: true)
    gable(g.entities, x + w - B, y + d, oz, h, C_Z0, d, mats, island: true)
    box(g.entities, [x + B, y, oz], [iw, d, B], mats[:carcase], 'Bottom')
    box(g.entities, [x + B, y + 100.mm - 100.mm, oz + h - B], [iw, 100.mm, B], mats[:carcase], 'Stretcher_Rear')
    box(g.entities, [x + B, y - 18.mm, oz + B], [iw, BACK, h - B - 10.mm], mats[:carcase], 'Back')
    gola(g.entities, :l, w - B, Geom::Point3d.new(x + B, y + GOLA_D, oz + h - L_GOLA_H), mats, facing: :island)
    gola(g.entities, :c, w - B, Geom::Point3d.new(x + B, y + GOLA_D, oz + C_Z0), mats, facing: :island)
    fw = w - 3.0.mm
    drawer(g.entities, Geom::Point3d.new(x + 1.5.mm, y, oz + 12.mm), fw, d, 200.mm, L_FRONT_H, -9.mm, 0, mats, mats[:front], dir_y: +1, name: 'Island_Drawer_Lower')
    drawer(g.entities, Geom::Point3d.new(x + 1.5.mm, y, oz + 390.mm), fw, d, 140.mm, U_FRONT_H, -15.mm, 0, mats, mats[:front], dir_y: +1, name: 'Island_Drawer_Upper')
    box(g.entities, [x + 10.mm, y, oz - PLINTH], [w - 20.mm, B, PLINTH], mats[:plinth], 'Plinth')
  end

  def self.gable(parent, x, y, oz, h, c_z0, d, mats, island: false)
    g = parent.add_group
    g.name = 'Gable_Gola_Machined'
    l_z0 = h - L_GOLA_H; l_z1 = h; c_z1 = c_z0 + C_GOLA_H
    front_y = island ? (y + d) : (y - d)
    gdir = island ? 1 : -1
    pts = [
      Geom::Point3d.new(x, y, oz), Geom::Point3d.new(x, front_y, oz),
      Geom::Point3d.new(x, front_y, oz + c_z0), Geom::Point3d.new(x, front_y - gdir * GOLA_D, oz + c_z0),
      Geom::Point3d.new(x, front_y - gdir * GOLA_D, oz + c_z1), Geom::Point3d.new(x, front_y, oz + c_z1),
      Geom::Point3d.new(x, front_y, oz + l_z0), Geom::Point3d.new(x, front_y - gdir * GOLA_D, oz + l_z0),
      Geom::Point3d.new(x, front_y - gdir * GOLA_D, oz + l_z1), Geom::Point3d.new(x, y, oz + l_z1)
    ]
    f = g.entities.add_face(pts)
    f.reverse! if f && f.normal.x < 0
    f.pushpull(B) if f
    g.material = mats[:carcase]
    tag(g, 'Gable_Gola_Machined')
    g
  end

  # =========================================================================
  # BUILD the L-kitchen + island (Box_01..N hierarchy)
  # =========================================================================
  def self.build
    model = Sketchup.active_model
    raise 'No active model.' unless model
    model.start_operation('LKitchenIsland', true)
    ents = model.active_entities
    ents.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('Kitchen') }.each { |g| g.erase! }

    m = mats(model)
    kitchen = ents.add_group
    kitchen.name = 'Kitchen_L_Island'

    oz = PLINTH
    x0 = 0.0.mm
    bx = x0

    # Box 01: tall double-oven (600mm) at left end
    g1 = kitchen.entities.add_group; g1.name = 'Kitchen_Box_01_Tall_Oven'
    box_tall_oven(g1, bx, 0, oz, m, m)
    bx += 600.0.mm + GAP

    # Box 02: glass-wall top row (2 x 600mm, over main base)
    g2 = kitchen.entities.add_group; g2.name = 'Kitchen_Box_02_Wall_Glass'
    box_glass_wall(g2, x0 + 640.0.mm, 0, WALL_Z0, m, m, w: 600.mm, doors: 1)
    box_glass_wall(g2, x0 + 1280.0.mm, 0, WALL_Z0, m, m, w: 600.mm, doors: 1)

    # Box 03 + 04: two base drawer banks along the main run
    g3 = kitchen.entities.add_group; g3.name = 'Kitchen_Box_03_Base_1'
    box_base(g3, x0 + 640.0.mm, 0, oz, m, m, label: 'Base_1')
    g4 = kitchen.entities.add_group; g4.name = 'Kitchen_Box_04_Base_2'
    box_base(g4, x0 + 1280.0.mm, 0, oz, m, m, label: 'Base_2')

    # Box 05: island (2 bays, aisle-facing +Y)
    g5 = kitchen.entities.add_group; g5.name = 'Kitchen_Box_05_Island'
    isl_y = -1400.0.mm
    box_island_drawers(g5, 0.0.mm, isl_y, oz, m, m, w: 600.mm)
    box_island_drawers(g5, 640.0.mm, isl_y, oz, m, m, w: 600.mm, label: 'Island_Drawers_2')

    model.commit_operation
    model.active_view.zoom_extents rescue nil
    puts '>> Advanced L-Kitchen + Island built (own implementation):'
    puts '    Box_01 Tall double-oven | Box_02 Wall glass (2x600)'
    puts '    Box_03,04 Base drawer banks | Box_05 Island (2 bays, aisle-facing)'
    puts '>> Gola overlap fronts, 5-piece undermount drawers, facing_dir Gola, selective drilling'
    puts '>> OK (no menus, no reports, engine-only)'
  end
end

RunLKitchen.build if defined?(Sketchup) && Sketchup.active_model
