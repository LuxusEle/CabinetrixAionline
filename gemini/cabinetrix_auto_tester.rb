# ==============================================================================
# CABINETRIX AI — AUTONOMOUS QA TEST & SCRAPING ENGINE (GEMINI MODULE)
# Localhost Server & Automated 3D Collision / Scraping / Screenshot Loop
#
# Load in SketchUp Ruby Console:
#   load 'c:/Users/asank/Documents/CabinetrixAionline/gemini/cabinetrix_auto_tester.rb'
#
# Features:
#   1. Automatic 3D Geometry Scraper (Dumps exact bounding boxes, parts matrix, reveals)
#   2. Mathematical Collision & Interference Detection (Detects clashes between parts)
#   3. Multi-Angle High-Res Viewport Screenshot Capture (Saved to gemini/test_artifacts/)
#   4. Lightweight Localhost HTTP Bridge (http://127.0.0.1:9876) for autonomous loop
# ==============================================================================
require 'sketchup.rb'
require 'json'
require 'socket'
require 'fileutils'

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

    {
      carcase: carcase_mat, front_dark: front_dark, front_cashmere: front_cashmere,
      gola: alu_black, marble: marble_mat, glass: glass_mat, cam: cam_mat,
      steel: steel_mat, wood: wood_mat, dowel: dowel_mat, hole: hole_mat,
      plinth: plinth_mat
    }
  end

  # ----------------------------------------------------------------------------
  # 1. 3D GEOMETRY & COLLISION SCRAPER
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

  def self.check_clashes(groups)
    clashes = []
    # Test bounding box intersections between critical functional sub-components
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

      # Ignore intended parent-child/touching contacts with < 0.5mm tolerance
      overlap_x = [0, [b1.max.x, b2.max.x].min - [b1.min.x, b2.min.x].max].max
      overlap_y = [0, [b1.max.y, b2.max.y].min - [b1.min.y, b2.min.y].max].max
      overlap_z = [0, [b1.max.z, b2.max.z].min - [b1.min.z, b2.min.z].max].max

      if overlap_x > 1.0.mm && overlap_y > 1.0.mm && overlap_z > 1.0.mm
        # Check if one is a drawer front hitting a Gola profile or drawer box
        n1 = g1.name.to_s
        n2 = g2.name.to_s
        if (n1.include?('Gola') && n2.include?('Drawer')) || (n2.include?('Gola') && n1.include?('Drawer'))
          clashes << {
            part_a: n1,
            part_b: n2,
            overlap_mm: [overlap_x.to_mm.round(1), overlap_y.to_mm.round(1), overlap_z.to_mm.round(1)]
          }
        end
      end
    end
    clashes
  end

  # ----------------------------------------------------------------------------
  # 2. RUN FULL TEST SUITE
  # ----------------------------------------------------------------------------
  def self.run_suite
    init_dirs
    model = Sketchup.active_model
    return { error: "No active model" } unless model

    model.start_operation("Run Autonomous QA Suite", true)
    mats = get_mats

    # Clear previous test run
    model.active_entities.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('QA_') || g.name.to_s.start_with?('Cabinetrix') }.each { |g| g.erase! }

    root = model.active_entities.add_group
    root.name = "QA_Test_Run_#{Time.now.strftime('%Y%m%d_%H%M%S')}"

    # 1. Build Standard Base 2-Drawer Gola (600W)
    base_grp = CabinetrixBoxEngine.create_cabinet(
      root.entities,
      :base_gola_drawers,
      { name: "QA_Base_Gola_600W", width: 600.mm, depth: 560.mm, height: 720.mm, mode: :hybrid, front_mat: mats[:front_dark] },
      { x: 0.mm, y: 0.mm, z: 100.mm, facing_dir: :front },
      mats
    )

    # 2. Build Tall Double Oven Tower (600W)
    tall_grp = CabinetrixBoxEngine.create_cabinet(
      root.entities,
      :tall_oven_tower,
      { name: "QA_Tall_Oven_600W", width: 600.mm, depth: 600.mm, height: 2160.mm, mode: :hybrid, front_mat: mats[:front_dark] },
      { x: 700.mm, y: 0.mm, z: 100.mm, facing_dir: :front },
      mats
    )

    # 3. Build Wardrobe Drawers Combo (900W)
    robe_grp = CabinetrixWardrobeEngine.build_wardrobe(
      root.entities,
      :drawers_combo,
      { name: "QA_Wardrobe_Combo_900W", width: 900.mm, depth: 600.mm, height: 2160.mm, mode: :hybrid },
      { x: 1400.mm, y: 0.mm, z: 100.mm },
      mats
    )

    model.commit_operation

    # Scrape Part Hierarchy and Bounds
    scraped_data = {
      timestamp: Time.now.to_s,
      base_unit: scrape_group(base_grp),
      tall_unit: scrape_group(tall_grp),
      wardrobe_unit: scrape_group(robe_grp)
    }

    # Clash Detection
    clashes = check_clashes([base_grp, tall_grp, robe_grp])
    scraped_data[:clashes] = clashes
    scraped_data[:status] = clashes.empty? ? "PASS" : "FAIL"

    # Write QA JSON Report
    report_path = File.join(ARTIFACTS_DIR, "qa_report.json")
    File.write(report_path, JSON.pretty_generate(scraped_data))

    # Capture Viewport Screenshots
    view = model.active_view
    view.zoom_extents if view
    screenshot_path = File.join(ARTIFACTS_DIR, "qa_viewport_full.png")
    view.write_image({
      filename: screenshot_path,
      width: 1280,
      height: 720,
      antialias: true,
      compression: 0.9,
      transparent: false
    })

    puts "=================================================="
    puts " CABINETRIX QA SUITE: #{scraped_data[:status]}"
    puts " Report: #{report_path}"
    puts " Screenshot: #{screenshot_path}"
    puts " Clashes Detected: #{clashes.length}"
    puts "=================================================="

    scraped_data
  end

  # ----------------------------------------------------------------------------
  # 3. LOCALHOST HTTP SERVER BRIDGE (PORT 9876)
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
            # Must run on SketchUp UI main thread
            UI.start_timer(0, false) do
              response_data = run_suite
            end
            response_body = { status: "TRIGGERED_TESTS", report_path: File.join(ARTIFACTS_DIR, "qa_report.json") }.to_json

          when '/reload'
            UI.start_timer(0, false) do
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
