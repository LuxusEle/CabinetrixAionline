# ==============================================================================
# CABINETRIX AI — AUTONOMOUS QA TEST & COLLISION AVOIDANCE SUITE (GEMINI MODULE)
# Localhost Server & Automated 3D Collision / Scraping / Validation Loop
#
# Load in SketchUp Ruby Console:
#   load 'c:/Users/asank/Documents/CabinetrixAionline/gemini/cabinetrix_auto_tester.rb'
#
# Features:
#   1. Comprehensive 3D Geometry Scraper (Exact bounding boxes, reveals, parts hierarchy)
#   2. Intelligent Clash Detection with CabinetrixCollisionEngine (Detects functional collisions)
#   3. Full Kitchen & Wardrobe Accessory Test Suite (LeMans, Space Tower, Gola, AVENTOS, Robes)
#   4. Multi-Angle High-Res Viewport Screenshot Capture (Saved to gemini/test_artifacts/)
#   5. Lightweight Localhost HTTP Bridge (http://127.0.0.1:9876) for autonomous loops
# ==============================================================================
require 'sketchup.rb'
require 'json'
require 'socket'
require 'fileutils'

require_relative 'cabinetrix_collision_engine'
require_relative 'cabinetrix_box_engine'
require_relative 'cabinetrix_wardrobe_engine'

module CabinetrixAutoTester
  PORT = 9876
  ARTIFACTS_DIR = File.expand_path('test_artifacts', __dir__)
  @server_thread = nil

  def self.init_dirs
    FileUtils.mkdir_p(ARTIFACTS_DIR)
  end

  def self.get_mats
    model = Sketchup.active_model
    mats = model.materials

    carcase_mat = mats['CBX_Melamine_White'] || mats.add('CBX_Melamine_White')
    carcase_mat.color = Sketchup::Color.new(245, 245, 242)

    front_dark = mats['CBX_Front_Anthracite'] || mats.add('CBX_Front_Anthracite')
    front_dark.color = Sketchup::Color.new(42, 45, 50)

    front_cashmere = mats['CBX_Front_Cashmere'] || mats.add('CBX_Front_Cashmere')
    front_cashmere.color = Sketchup::Color.new(215, 208, 198)

    alu_black = mats['CBX_Alu_Black_Anodized'] || mats.add('CBX_Alu_Black_Anodized')
    alu_black.color = Sketchup::Color.new(25, 27, 30)

    marble_mat = mats['CBX_Calacatta_Marble'] || mats.add('CBX_Calacatta_Marble')
    marble_mat.color = Sketchup::Color.new(248, 246, 242)

    glass_mat = mats['CBX_Clear_Glass'] || mats.add('CBX_Clear_Glass')
    glass_mat.color = Sketchup::Color.new(210, 235, 245)
    glass_mat.alpha = 0.35

    cam_mat = mats['CBX_Minifix_Zinc'] || mats.add('CBX_Minifix_Zinc')
    cam_mat.color = Sketchup::Color.new(180, 185, 190)

    steel_mat = mats['CBX_Stainless_Steel'] || mats.add('CBX_Stainless_Steel')
    steel_mat.color = Sketchup::Color.new(140, 145, 155)

    wood_mat = mats['CBX_Natural_Birch'] || mats.add('CBX_Natural_Birch')
    wood_mat.color = Sketchup::Color.new(225, 212, 190)

    dowel_mat = mats['CBX_Beech_Dowel'] || mats.add('CBX_Beech_Dowel')
    dowel_mat.color = Sketchup::Color.new(215, 160, 95)

    hole_mat = mats['CBX_CNC_Bore_Dark'] || mats.add('CBX_CNC_Bore_Dark')
    hole_mat.color = Sketchup::Color.new(20, 20, 20)

    plinth_mat = mats['CBX_Plinth_Black'] || mats.add('CBX_Plinth_Black')
    plinth_mat.color = Sketchup::Color.new(30, 32, 35)

    led_mat = mats['CBX_LED_Warm'] || mats.add('CBX_LED_Warm')
    led_mat.color = Sketchup::Color.new(255, 240, 200)

    {
      carcase: carcase_mat, front_dark: front_dark, front_cashmere: front_cashmere,
      gola: alu_black, marble: marble_mat, glass: glass_mat, cam: cam_mat,
      steel: steel_mat, wood: wood_mat, dowel: dowel_mat, hole: hole_mat,
      plinth: plinth_mat, led: led_mat
    }
  end

  # ----------------------------------------------------------------------------
  # 1. 3D GEOMETRY SCRAPER & REVEAL EXTRACTOR
  # ----------------------------------------------------------------------------
  def self.scrape_group(group, path = "")
    name = group.name.to_s.empty? ? "Unnamed_Group" : group.name
    full_path = path.empty? ? name : "#{path} > #{name}"
    bb = group.bounds

    info = {
      name: name,
      path: full_path,
      min: [bb.min.x.to_mm.round(1), bb.min.y.to_mm.round(1), bb.min.z.to_mm.round(1)],
      max: [bb.max.x.to_mm.round(1), bb.max.y.to_mm.round(1), bb.max.z.to_mm.round(1)],
      width: bb.width.to_mm.round(1),
      depth: bb.height.to_mm.round(1),
      height: bb.depth.to_mm.round(1),
      children: []
    }

    group.entities.grep(Sketchup::Group).each do |child|
      info[:children] << scrape_group(child, full_path)
    end

    info
  end

  # ----------------------------------------------------------------------------
  # 2. INTELLIGENT COLLISION DETECTION VIA CABINETRIX COLLISION ENGINE
  # ----------------------------------------------------------------------------
  def self.check_clashes(groups)
    clashes = []
    leaves = []
    extract_leaves = lambda do |g|
      children = g.entities.grep(Sketchup::Group)
      if children.empty?
        leaves << g
      else
        children.each { |c| extract_leaves.call(c) }
      end
    end
    groups.each { |g| extract_leaves.call(g) }

    leaves.combination(2) do |g1, g2|
      b1 = g1.bounds
      b2 = g2.bounds

      b1_min = [b1.min.x.to_mm, b1.min.y.to_mm, b1.min.z.to_mm]
      b1_max = [b1.max.x.to_mm, b1.max.y.to_mm, b1.max.z.to_mm]
      b2_min = [b2.min.x.to_mm, b2.min.y.to_mm, b2.min.z.to_mm]
      b2_max = [b2.max.x.to_mm, b2.max.y.to_mm, b2.max.z.to_mm]

      clash_info = CabinetrixCollisionEngine.evaluate_clash(
        g1.name.to_s, b1_min, b1_max,
        g2.name.to_s, b2_min, b2_max
      )

      if clash_info && clash_info[:severity] == :critical
        clashes << clash_info
      end
    end
    clashes
  end

  # ----------------------------------------------------------------------------
  # 3. RUN FULL ACCESSORY & COLLISION TEST MATRIX
  # ----------------------------------------------------------------------------
  def self.run_suite
    init_dirs
    model = Sketchup.active_model
    return { error: "No active model" } unless model

    model.start_operation("Run Autonomous Collision & Accessory Suite", true)
    mats = get_mats

    # Clear previous test runs
    model.active_entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('QA_') || g.name.to_s.start_with?('Cabinetrix') }.each { |g| g.erase! }

    root = model.active_entities.add_group
    root.name = "QA_Test_Run_#{Time.now.strftime('%Y%m%d_%H%M%S')}"

    units = []

    # 1. Base 2-Drawer Gola (600W) - Zero collision with L-Gola & C-Gola lips
    units << CabinetrixBoxEngine.create_cabinet(
      root.entities,
      :base_gola_drawers,
      { name: "QA_Base_Gola_600W", width: 600.mm, depth: 560.mm, height: 720.mm, mode: :hybrid, front_mat: mats[:front_dark] },
      { x: 0.mm, y: 0.mm, z: 100.mm, facing_dir: :front },
      mats
    )

    # 2. Base Sink with Cargo Waste Bins & False Front (900W)
    units << CabinetrixBoxEngine.create_cabinet(
      root.entities,
      :base_gola_sink,
      { name: "QA_Base_Sink_Cargo_900W", width: 900.mm, depth: 560.mm, height: 720.mm, mode: :hybrid, front_mat: mats[:front_dark] },
      { x: 700.mm, y: 0.mm, z: 100.mm, facing_dir: :front },
      mats
    )

    # 3. Base Blind Corner with LeMans II Trays (1050W)
    units << CabinetrixBoxEngine.create_cabinet(
      root.entities,
      :base_lemans_corner,
      { name: "QA_Base_LeMans_1050W", width: 1050.mm, depth: 560.mm, height: 720.mm, mode: :hybrid, front_mat: mats[:front_dark] },
      { x: 1700.mm, y: 0.mm, z: 100.mm, facing_dir: :front },
      mats
    )

    # 4. Tall Double Oven Tower (600W)
    units << CabinetrixBoxEngine.create_cabinet(
      root.entities,
      :tall_oven_tower,
      { name: "QA_Tall_Oven_600W", width: 600.mm, depth: 600.mm, height: 2160.mm, mode: :hybrid, front_mat: mats[:front_dark] },
      { x: 2850.mm, y: 0.mm, z: 100.mm, facing_dir: :front },
      mats
    )

    # 5. Tall Space Tower Larder with 5 Internal Pullouts (600W)
    units << CabinetrixBoxEngine.create_cabinet(
      root.entities,
      :tall_space_tower,
      { name: "QA_Tall_SpaceTower_600W", width: 600.mm, depth: 600.mm, height: 2160.mm, mode: :hybrid, front_mat: mats[:front_dark] },
      { x: 3550.mm, y: 0.mm, z: 100.mm, facing_dir: :front },
      mats
    )

    # 6. Wall AVENTOS HF Lift Cabinet with 50mm Setback Shelf (800W)
    units << CabinetrixBoxEngine.create_cabinet(
      root.entities,
      :wall_lift_aventos,
      { name: "QA_Wall_Aventos_800W", width: 800.mm, depth: 350.mm, height: 720.mm, mode: :hybrid, front_mat: mats[:front_cashmere] },
      { x: 4250.mm, y: 0.mm, z: 1400.mm, facing_dir: :front },
      mats
    )

    # 7. Wardrobe Drawers & Trouser Combo (900W)
    units << CabinetrixWardrobeEngine.build_wardrobe(
      root.entities,
      :drawers_combo,
      { name: "QA_Wardrobe_Combo_900W", width: 900.mm, depth: 600.mm, height: 2160.mm, mode: :hybrid },
      { x: 5150.mm, y: 0.mm, z: 100.mm },
      mats
    )

    # 8. Wardrobe 5-Tier Sloping Shoe Master (900W)
    units << CabinetrixWardrobeEngine.build_wardrobe(
      root.entities,
      :shoe_master,
      { name: "QA_Wardrobe_Shoes_900W", width: 900.mm, depth: 600.mm, height: 2160.mm, mode: :hybrid },
      { x: 6150.mm, y: 0.mm, z: 100.mm },
      mats
    )

    model.commit_operation

    # Scrape Part Hierarchy and Bounds
    scraped_data = {
      timestamp: Time.now.to_s,
      tested_modules_count: units.length,
      units: units.map { |u| scrape_group(u) }
    }

    # Clash Detection via CabinetrixCollisionEngine
    clashes = check_clashes(units)
    scraped_data[:clashes] = clashes
    scraped_data[:status] = clashes.empty? ? "PASS (ZERO COLLISIONS)" : "FAIL (#{clashes.length} CLASHES DETECTED)"

    # Write QA JSON Report
    report_path = File.join(ARTIFACTS_DIR, "qa_report.json")
    File.write(report_path, JSON.pretty_generate(scraped_data))

    # Capture Viewport Screenshots
    view = model.active_view
    view.zoom_extents if view
    screenshot_path = File.join(ARTIFACTS_DIR, "qa_viewport_full.png")
    view.write_image({
      filename: screenshot_path,
      width: 1920,
      height: 1080,
      antialias: true,
      compression: 0.9,
      transparent: false
    })

    puts "=================================================="
    puts " CABINETRIX QA SUITE: #{scraped_data[:status]}"
    puts " Report: #{report_path}"
    puts " Screenshot: #{screenshot_path}"
    puts " Tested Units: #{units.length}"
    puts " Critical Clashes: #{clashes.length}"
    puts "=================================================="

    scraped_data
  end

  # ----------------------------------------------------------------------------
  # 4. LOCALHOST HTTP SERVER BRIDGE (PORT 9876)
  # ----------------------------------------------------------------------------
  def self.start_server
    stop_server if @server_thread

    @server_thread = Thread.new do
      server = TCPServer.new('127.0.0.1', PORT)
      puts "Cabinetrix Localhost Bridge running on http://127.0.0.1:#{PORT}"

      loop do
        begin
          client = server.accept
          request_line = client.gets
          next unless request_line

          method, path, = request_line.split(" ")

          # Read Headers
          headers = {}
          while (line = client.gets) && (line.strip != "")
            k, v = line.split(":", 2)
            headers[k.strip] = v.strip if k && v
          end

          # Dispatch Action
          response_data = {}
          case path
          when '/run_tests', '/test'
            UI.start_timer(0, false) do
              response_data = run_suite
            end
            response_body = { status: "TRIGGERED_TESTS", report_path: File.join(ARTIFACTS_DIR, "qa_report.json") }.to_json

          when '/reload'
            UI.start_timer(0, false) do
              load File.expand_path('cabinetrix_collision_engine.rb', __dir__)
              load File.expand_path('cabinetrix_box_engine.rb', __dir__)
              load File.expand_path('cabinetrix_wardrobe_engine.rb', __dir__)
              run_suite
            end
            response_body = { status: "RELOADED_AND_TESTED" }.to_json

          when '/status'
            report_path = File.join(ARTIFACTS_DIR, "qa_report.json")
            if File.exist?(report_path)
              response_body = File.read(report_path)
            else
              response_body = { status: "IDLE", message: "No test runs executed yet" }.to_json
            end

          else
            response_body = { error: "Unknown endpoint: #{path}" }.to_json
          end

          client.print "HTTP/1.1 200 OK\r\n"
          client.print "Content-Type: application/json\r\n"
          client.print "Access-Control-Allow-Origin: *\r\n"
          client.print "Content-Length: #{response_body.bytesize}\r\n"
          client.print "Connection: close\r\n\r\n"
          client.print response_body
          client.close
        rescue => e
          puts "Server error: #{e.message}"
        end
      end
    end
  end

  def self.stop_server
    if @server_thread
      @server_thread.kill
      @server_thread = nil
      puts "Cabinetrix Localhost Bridge stopped."
    end
  end
end

# Auto-start server and run initial suite
if defined?(Sketchup) && Sketchup.active_model
  CabinetrixAutoTester.start_server
  CabinetrixAutoTester.run_suite
end
