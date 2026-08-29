# =============================================================================
# ONLINE CABINET AI - SECURE CLOUD LOADER PLUGIN FOR SKETCHUP
# (c) 2026 Cabinex AI. All Rights Reserved.
# =============================================================================
# This lightweight file is the ONLY script on the user's PC.
# It authenticates with Supabase / License Tokens and streams the full engine into RAM.
# =============================================================================

require 'sketchup.rb'
require 'net/http'
require 'uri'
require 'json'

module CabinexAI
  module CloudLoader
    DEFAULT_PROD_URL  = 'https://cabinex-cloud.vercel.app'
    DEFAULT_LOCAL_URL = 'http://localhost:3050'
    
    @active_user = 'Anonymous'
    @active_server = DEFAULT_PROD_URL

    def self.show_login_dialog
      dialog = UI::HtmlDialog.new({
        :dialog_title => "Online Cabinet AI — Cloud Authentication & License",
        :preferences_key => "com.cabinex.cloud_loader_login",
        :width => 450,
        :height => 660,
        :resizable => false,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })

      login_html = <<-HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <title>Online Cabinet AI Login</title>
          <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@600&display=swap" rel="stylesheet">
          <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              font-family: 'Inter', sans-serif;
              background: #0f172a;
              color: #f8fafc;
              padding: 28px 24px;
              font-size: 13px;
            }
            .header {
              text-align: center;
              margin-bottom: 20px;
            }
            .brand-logo { font-size: 28px; margin-bottom: 4px; }
            .brand-title {
              font-size: 19px;
              font-weight: 800;
              color: #38bdf8;
              letter-spacing: -0.5px;
            }
            .brand-subtitle { font-size: 11px; color: #94a3b8; margin-top: 2px; }
            
            .auth-tabs {
              display: flex;
              gap: 6px;
              background: rgba(255,255,255,0.05);
              padding: 4px;
              border-radius: 8px;
              margin-bottom: 16px;
            }
            .auth-tab-btn {
              flex: 1;
              background: none;
              border: none;
              color: #94a3b8;
              font-weight: 700;
              font-size: 11px;
              padding: 8px;
              border-radius: 6px;
              cursor: pointer;
              transition: all 0.2s;
            }
            .auth-tab-btn.active {
              background: #2563eb;
              color: white;
            }

            .form-group { margin-bottom: 12px; }
            label {
              display: block;
              font-size: 11px;
              font-weight: 600;
              color: #cbd5e1;
              margin-bottom: 4px;
            }
            input, select {
              width: 100%;
              padding: 10px 12px;
              background: #1e293b;
              border: 1px solid #334155;
              border-radius: 6px;
              color: white;
              font-size: 12px;
              outline: none;
              transition: border-color 0.2s;
            }
            input:focus, select:focus { border-color: #38bdf8; }
            
            .server-toggle {
              background: rgba(255,255,255,0.03);
              border: 1px dashed #334155;
              padding: 8px 10px;
              border-radius: 6px;
              margin-bottom: 14px;
            }
            .btn-login {
              width: 100%;
              padding: 12px;
              background: linear-gradient(135deg, #0284c7, #2563eb);
              border: none;
              border-radius: 6px;
              color: white;
              font-weight: 700;
              font-size: 13px;
              cursor: pointer;
              box-shadow: 0 4px 12px rgba(37,99,235,0.35);
              margin-top: 6px;
            }
            .btn-login:hover { background: linear-gradient(135deg, #0369a1, #1d4ed8); }
            
            .status-box {
              margin-top: 14px;
              padding: 10px;
              border-radius: 6px;
              font-size: 11px;
              text-align: center;
              display: none;
            }
            .status-info { background: rgba(56, 189, 248, 0.1); color: #38bdf8; border: 1px solid rgba(56, 189, 248, 0.3); display: block; }
            .status-error { background: rgba(239, 68, 68, 0.1); color: #ef4444; border: 1px solid rgba(239, 68, 68, 0.3); display: block; }
            .status-success { background: rgba(34, 197, 94, 0.1); color: #22c55e; border: 1px solid rgba(34, 197, 94, 0.3); display: block; }
            
            .features-list {
              margin-top: 16px;
              padding-top: 12px;
              border-top: 1px solid #1e293b;
              font-size: 10px;
              color: #64748b;
              line-height: 1.5;
            }
          </style>
        </head>
        <body>
          <div class="header">
            <div class="brand-logo">💎</div>
            <div class="brand-title">ONLINE CABINET AI</div>
            <div class="brand-subtitle">Cloud License & Engine Streaming System</div>
          </div>

          <div class="server-toggle">
            <label for="serverEnv">Cloud Gateway Endpoint</label>
            <select id="serverEnv" onchange="toggleCustomServer()">
              <option value="#{DEFAULT_PROD_URL}" selected>Production Vercel Cloud (#{DEFAULT_PROD_URL})</option>
              <option value="direct_local">Direct Local Workspace Engine (Fast Local Load)</option>
              <option value="#{DEFAULT_LOCAL_URL}">Local Node Server (#{DEFAULT_LOCAL_URL})</option>
              <option value="custom">Custom Server URL...</option>
            </select>
            <div id="customServerWrap" style="display: none; margin-top: 6px;">
              <input type="text" id="customServerUrl" placeholder="https://your-custom-app.vercel.app" />
            </div>
          </div>

          <div class="auth-tabs">
            <button class="auth-tab-btn active" id="tabKeyBtn" onclick="switchAuthMode('key')">🔑 License Token Key</button>
            <button class="auth-tab-btn" id="tabEmailBtn" onclick="switchAuthMode('email')">👤 Email & Password</button>
          </div>

          <!-- Mode 1: License Token Key -->
          <div id="paneKey">
            <div class="form-group">
              <label for="txtLicenseKey">Purchased License Token</label>
              <input type="text" id="txtLicenseKey" value="CBX-PRO-9842-1104" placeholder="e.g. CBX-PRO-XXXX-XXXX" style="font-family: 'JetBrains Mono', monospace; font-weight: 700; color: #38bdf8;" />
            </div>
          </div>

          <!-- Mode 2: Email & Password -->
          <div id="paneEmail" style="display: none;">
            <div class="form-group">
              <label for="txtEmail">Registered User Email</label>
              <input type="email" id="txtEmail" value="admin@cabinex.ai" placeholder="e.g. user@yourcompany.com" />
            </div>
            <div class="form-group">
              <label for="txtPassword">Password</label>
              <input type="password" id="txtPassword" value="password123" placeholder="••••••••" />
            </div>
          </div>

          <button class="btn-login" id="btnLogin" onclick="handleLogin()">
            🔐 Activate & Stream Engine
          </button>

          <div id="statusBox" class="status-box"></div>

          <div class="features-list">
            <div>🔒 <strong>Zero Disk Footprint:</strong> Engine runs 100% in RAM.</div>
            <div>⚡ <strong>Real-time Telemetry:</strong> Automatic sync to Admin Console.</div>
            <div>🛡️ <strong>Supabase Protected:</strong> Commercial license management.</div>
          </div>

          <script>
            let authMode = 'key';

            function switchAuthMode(mode) {
              authMode = mode;
              document.getElementById('tabKeyBtn').className = 'auth-tab-btn' + (mode === 'key' ? ' active' : '');
              document.getElementById('tabEmailBtn').className = 'auth-tab-btn' + (mode === 'email' ? ' active' : '');
              document.getElementById('paneKey').style.display = (mode === 'key') ? 'block' : 'none';
              document.getElementById('paneEmail').style.display = (mode === 'email') ? 'block' : 'none';
            }

            function toggleCustomServer() {
              const val = document.getElementById('serverEnv').value;
              document.getElementById('customServerWrap').style.display = (val === 'custom') ? 'block' : 'none';
            }

            function setStatus(msg, type) {
              const box = document.getElementById('statusBox');
              box.className = 'status-box status-' + type;
              box.innerText = msg;
              box.style.display = 'block';
            }

            function handleLogin() {
              const envChoice = document.getElementById('serverEnv').value;
              const serverUrl = (envChoice === 'custom') ? 
                document.getElementById('customServerUrl').value.trim() : envChoice;
              
              let payload = { server_url: serverUrl };

              if (authMode === 'key') {
                const key = document.getElementById('txtLicenseKey').value.trim();
                if (!key) {
                  setStatus('Please enter your license token key.', 'error');
                  return;
                }
                payload.license_key = key;
              } else {
                const email = document.getElementById('txtEmail').value.trim();
                const password = document.getElementById('txtPassword').value;
                if (!email || !password) {
                  setStatus('Please enter your email and password.', 'error');
                  return;
                }
                payload.email = email;
                payload.password = password;
              }

              setStatus('Verifying license with cloud server...', 'info');
              document.getElementById('btnLogin').disabled = true;

              if (window.sketchup && typeof window.sketchup.doCloudAuth === 'function') {
                window.sketchup.doCloudAuth(JSON.stringify(payload));
              } else {
                alert('SketchUp Bridge ready. Payload: ' + JSON.stringify(payload));
              }
            }

            window.onAuthResponse = function(status, message) {
              document.getElementById('btnLogin').disabled = false;
              if (status === 'success') {
                setStatus(message || 'License Verified! Launching Kitchen Studio...', 'success');
              } else {
                setStatus(message || 'Login Failed. Check credentials or server.', 'error');
              }
            };
          </script>
        </body>
        </html>
      HTML

      dialog.set_html(login_html)

      dialog.add_action_callback("doCloudAuth") do |_context, json_payload|
        begin
          data = JSON.parse(json_payload)
          server_url = data['server_url'].to_s.chomp('/')
          @active_server = server_url

          # Direct Local Workspace Engine bypass (zero-network option)
          if server_url == 'direct_local'
            dialog.execute_script("onAuthResponse('success', 'Loading local workspace engine directly...');")
            UI.start_timer(0.1, false) do
              begin
                planner_dir = defined?(BoardSashAI) ? 'boardsash_ai' : 'sketchup_ai_integration'
                engine_path = File.expand_path(File.join(__dir__, '..', '..', planner_dir, 'cbx_hybrid_engine.rb'))
                planner_path = File.expand_path(File.join(__dir__, '..', '..', planner_dir, 'cbx_hybrid_planner.rb'))
                unless File.exist?(engine_path)
                  engine_path = File.expand_path(File.join(__dir__, '..', '..', 'cbx_hybrid_engine.rb'))
                end
                load engine_path if File.exist?(engine_path)
                load planner_path if File.exist?(planner_path)
                @active_user = (data['license_key'] || data['email'] || 'Local Pro Studio')
                @token_balance = 999
                CabinexAI::HybridPlanner.show_dialog
                puts ">> Online Cabinet AI: Direct Local Workspace Engine loaded successfully!"
                dialog.close
              rescue => err
                puts ">> Direct Local Load Error: #{err.message}"
                dialog.execute_script("onAuthResponse('error', #{('Error loading local engine: ' + err.message).to_json});")
              end
            end
            next
          end

          # 1. Authenticate with Server
          require 'openssl'
          auth_uri = URI.parse("#{server_url}/api/auth/login")
          auth_req = Net::HTTP::Post.new(auth_uri.path, {'Content-Type' => 'application/json'})
          auth_req.body = data.to_json

          http = Net::HTTP.new(auth_uri.host, auth_uri.port)
          if auth_uri.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          http.open_timeout = 8
          http.read_timeout = 15

          auth_res = http.request(auth_req)
          auth_json = JSON.parse(auth_res.body)

          if auth_res.code != '200' || !auth_json['success']
            err_msg = auth_json['error'] || "Authentication failed (HTTP #{auth_res.code})"
            dialog.execute_script("onAuthResponse('error', #{err_msg.to_json});")
            next
          end

          token = auth_json['token']
          @active_user = (auth_json['user'] && (auth_json['user']['email'] || auth_json['user']['id'])) || data['license_key'] || 'Valued Studio'
          @token_balance = (auth_json['user'] && auth_json['user']['tokens_balance']) || 100

          # Log login telemetry event
          send_telemetry('LOGIN', 'User Session Activated', 0, 0, 0, 0)

          # 2. Fetch Protected In-Memory Engine Payload
          engine_uri = URI.parse("#{server_url}/api/engine/load")
          engine_req = Net::HTTP::Post.new(engine_uri.path, {'Content-Type' => 'application/json'})
          app_type = defined?(BoardSashAI) ? 'board' : 'aluminum'
          engine_req.body = { token: token, app_type: app_type }.to_json

          http_eng = Net::HTTP.new(engine_uri.host, engine_uri.port)
          if engine_uri.scheme == 'https'
            http_eng.use_ssl = true
            http_eng.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          http_eng.open_timeout = 8
          http_eng.read_timeout = 15

          engine_res = http_eng.request(engine_req)
          engine_json = JSON.parse(engine_res.body)

          if engine_res.code != '200' || !engine_json['engine']
            err_msg = engine_json['error'] || "Failed to download cloud engine."
            dialog.execute_script("onAuthResponse('error', #{err_msg.to_json});")
            next
          end

          # 3. Stream Engine Directly into SketchUp Memory (RAM)
          engine_code = engine_json['engine']
          dialog.execute_script("onAuthResponse('success', 'License active! Streaming in-memory engine...');")

          UI.start_timer(0.2, false) do
            begin
              # Execute in-memory engine
              eval(engine_code, TOPLEVEL_BINDING)
              
              # Launch the Kitchen Studio
              CabinexAI::HybridPlanner.show_dialog
              puts ">> Online Cabinet AI: Cloud Engine loaded successfully into RAM for #{@active_user} (Tokens: #{@token_balance})!"

              # Close login window only after studio is opened
              dialog.close
            rescue => eval_err
              puts ">> Cloud Engine Execution Error: #{eval_err.message}\n#{eval_err.backtrace.first(10).join("\n")}"
              dialog.execute_script("onAuthResponse('error', #{('Error executing engine: ' + eval_err.message).to_json});")
              UI.messagebox("Error executing cloud engine: #{eval_err.message}\nCheck Ruby console.")
            end
          end

        rescue => e
          puts "Cloud Loader Error: #{e.message}"
          dialog.execute_script("onAuthResponse('error', #{e.message.to_json});")
        end
      end

      dialog.show
    end

    def self.active_user
      @active_user || 'asanke1@gmail.com'
    end

    def self.token_balance
      @token_balance || 100
    end

    def self.active_server
      @active_server || DEFAULT_PROD_URL
    end

    def self.consume_tokens(specs)
      begin
        require 'openssl'
        srv = active_server
        return { 'success' => true, 'tokens_remaining' => @token_balance } if srv == 'direct_local'

        uri = URI.parse("#{srv}/api/kitchen/consume-tokens")
        req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
        req.body = {
          user_identifier: @active_user || 'Valued Studio',
          specs: specs
        }.to_json

        http = Net::HTTP.new(uri.host, uri.port)
        if uri.scheme == 'https'
          http.use_ssl = true
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        end
        http.open_timeout = 6
        http.read_timeout = 10
        res = http.request(req)
        json = JSON.parse(res.body)
        if json && json['tokens_remaining']
          @token_balance = json['tokens_remaining'].to_i
        end
        return json
      rescue => e
        puts ">> Token verification error: #{e.message}"
        return { 'success' => true, 'tokens_remaining' => @token_balance }
      end
    end

    def self.send_telemetry(action_type, project_name, wall_a, wall_b, linear_ft, quote_lkr)
      Thread.new do
        begin
          require 'openssl'
          srv = active_server
          return if srv == 'direct_local'

          uri = URI.parse("#{srv}/api/telemetry/log")
          req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
          req.body = {
            user_identifier: @active_user || 'Valued Studio',
            action_type: action_type,
            project_name: project_name,
            wall_a_mm: wall_a,
            wall_b_mm: wall_b,
            total_linear_ft: linear_ft,
            quoted_amount_lkr: quote_lkr
          }.to_json

          http = Net::HTTP.new(uri.host, uri.port)
          if uri.scheme == 'https'
            http.use_ssl = true
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          http.open_timeout = 5
          http.read_timeout = 8
          res = http.request(req)
          puts ">> Telemetry Dispatched: #{action_type} (Quoted: LKR #{quote_lkr.to_i}) -> Cloud Response: #{res.code}"
        rescue => e
          puts ">> Telemetry Error: #{e.message}"
        end
      end
    end
  end
end

unless file_loaded?(__FILE__)
  menu = UI.menu('Plugins')
  sub = menu.add_submenu('💎 Online Cabinet AI')
  sub.add_item('Cloud Login & Activate') {
    CabinexAI::CloudLoader.show_login_dialog
  }

  # --- TOOLBAR SETUP WITH CUSTOM ICONS ---
  tb = UI::Toolbar.new('Cabinex AI')
  icons_dir = File.join(__dir__, 'icons')

  # 1. Studio Planner / Edit Room
  cmd_edit = UI::Command.new('Studio Planner') {
    if defined?(CabinexAI::HybridPlanner)
      CabinexAI::HybridPlanner.show_dialog
    else
      UI.messagebox("Please click 'Cloud Login & Activate' from the Plugins menu first.")
      CabinexAI::CloudLoader.show_login_dialog
    end
  }
  cmd_edit.tooltip = 'Edit Wall / Room (Studio Planner)'
  cmd_edit.status_bar_text = 'Open the Cabinex AI Studio Planner'
  cmd_edit.small_icon = File.join(icons_dir, 'icon_studio_small.png')
  cmd_edit.large_icon = File.join(icons_dir, 'icon_studio.png')
  tb.add_item(cmd_edit)

  # 2. Add Box
  cmd_add = UI::Command.new('Add Box') {
    if defined?(CabinexAI::HybridPlanner)
      CabinexAI::HybridPlanner.show_dialog
    else
      UI.messagebox("Please click 'Cloud Login & Activate' first.")
      CabinexAI::CloudLoader.show_login_dialog
    end
  }
  cmd_add.tooltip = 'Add Cabinet Box'
  cmd_add.status_bar_text = 'Add a new modular cabinet box'
  cmd_add.small_icon = File.join(icons_dir, 'icon_add_box_small.png')
  cmd_add.large_icon = File.join(icons_dir, 'icon_add_box.png')
  tb.add_item(cmd_add)

  # 3. Interactive Edit / Replace Box
  cmd_replace = UI::Command.new('Edit Box') {
    if defined?(CabinexAI::BoxEditor::EditBoxTool)
      Sketchup.active_model.select_tool(CabinexAI::BoxEditor::EditBoxTool.new)
    elsif defined?(CabinexAI::HybridPlanner)
      CabinexAI::HybridPlanner.show_dialog
    else
      UI.messagebox("Please click 'Cloud Login & Activate' first.")
      CabinexAI::CloudLoader.show_login_dialog
    end
  }
  cmd_replace.tooltip = 'Edit / Replace Box (Click 3D Model)'
  cmd_replace.status_bar_text = 'Click any cabinet in 3D to edit type and parameters'
  cmd_replace.small_icon = File.join(icons_dir, 'icon_edit_box_small.png')
  cmd_replace.large_icon = File.join(icons_dir, 'icon_edit_box.png')
  tb.add_item(cmd_replace)

  # 4. Measurements & HUD
  cmd_measure = UI::Command.new('Measurements') {
    CabinexAI::ViewportHUD.refresh_hud_display if defined?(CabinexAI::ViewportHUD)
    UI.messagebox("Cabinex 3D Architectural Dimensions active.")
  }
  cmd_measure.tooltip = 'Add Measurements & Viewport HUD'
  cmd_measure.status_bar_text = 'Refresh 3D Dimensions and Live BOM HUD'
  cmd_measure.small_icon = File.join(icons_dir, 'icon_measure_small.png')
  cmd_measure.large_icon = File.join(icons_dir, 'icon_measure.png')
  tb.add_item(cmd_measure)

  tb.add_separator

  # 5. Export Workshop PDF Report
  cmd_pdf = UI::Command.new('Export PDF') {
    if defined?(CabinexAI::Exports)
      CabinexAI::Exports.export_pdf_report
    elsif defined?(CabinexAI::HybridPlanner)
      CabinexAI::HybridPlanner.show_dialog
    else
      UI.messagebox("Please click 'Cloud Login & Activate' first to enable Workshop Report generation.")
    end
  }
  cmd_pdf.tooltip = 'Export Workshop Report (PDF)'
  cmd_pdf.status_bar_text = 'Generate the Workshop Production Pack Presentation'
  cmd_pdf.small_icon = File.join(icons_dir, 'icon_pdf_small.png')
  cmd_pdf.large_icon = File.join(icons_dir, 'icon_pdf.png')
  tb.add_item(cmd_pdf)

  # 6. Export 2D DXF Cutting Plans
  cmd_dxf = UI::Command.new('Export DXF/Sheets') {
    if defined?(CabinexAI::Exports)
      CabinexAI::Exports.export_dxf_cutting_sheets
    else
      UI.messagebox("Please activate the cloud engine first to export DXF cutting sheets.")
    end
  }
  cmd_dxf.tooltip = 'Export Cutting Plans / Sheets (DXF)'
  cmd_dxf.status_bar_text = 'Generate 2D CNC/Saw bar-cut sheet layouts'
  cmd_dxf.small_icon = File.join(icons_dir, 'icon_dxf_small.png')
  cmd_dxf.large_icon = File.join(icons_dir, 'icon_dxf.png')
  tb.add_item(cmd_dxf)

  # 7. Download BOM Excel
  cmd_bom = UI::Command.new('Download BOM Excel') {
    if defined?(CabinexAI::Exports)
      CabinexAI::Exports.export_excel_bom
    else
      UI.messagebox("Please activate the cloud engine first to export BOM Excel.")
    end
  }
  cmd_bom.tooltip = 'Download BOM Excel / CSV'
  cmd_bom.status_bar_text = 'Export the full Bill of Materials to Excel/CSV spreadsheet'
  cmd_bom.small_icon = File.join(icons_dir, 'icon_excel_small.png')
  cmd_bom.large_icon = File.join(icons_dir, 'icon_excel.png')
  tb.add_item(cmd_bom)

  tb.show

  file_loaded(__FILE__)
end
