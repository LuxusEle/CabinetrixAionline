# =============================================================================
# CABINETRIX / CABINEX AI â€” SECURE CLOUD LOADER & AUTHENTICATION CLIENT
# (c) 2026 Cabinetrix / Cabinex AI. All Rights Reserved.
# =============================================================================

require 'sketchup.rb'
require 'net/http'
require 'uri'
require 'json'
require 'openssl'

module CabinexAI
  module CloudLoader
    current_dir = __dir__.to_s.downcase
    is_board_app = current_dir.include?('cabinetrix') || current_dir.include?('boardsash')
    
    DEFAULT_PROD_URL  = 'https://cabinex-cloud.vercel.app'
    DEFAULT_LOCAL_URL = is_board_app ? 'http://localhost:3060' : 'http://localhost:3050'
    APP_TYPE          = is_board_app ? 'board' : 'aluminum'
    
    @active_user = 'Anonymous'
    @active_server = DEFAULT_PROD_URL
    @token_balance = 100

    def self.show_login_dialog
      # Determine branding details dynamically based on folder context
      current_dir = __dir__.to_s.downcase
      is_board = current_dir.include?('cabinetrix') || current_dir.include?('boardsash')
      
      app_title = is_board ? "Cabinetrix AI" : "Cabinex AI"
      app_subtitle = is_board ? "Board & Sash Modular Kitchen Cloud Engine" : "Aluminum & Metal Frame Modular Kitchen Cloud Engine"
      app_logo = is_board ? "ðŸªµ" : "ðŸ—„ï¸"
      default_key = is_board ? "CBX-PRO-9842-1104" : "CBX-ENT-DEVOLY-8841"
      
      feature_1 = is_board ? "âœ“ 100% Melamine Board Carcasses" : "âœ“ 100% Matte Black Aluminum Carcase Frame"
      feature_2 = is_board ? "âœ“ Optional Glass Sash / Slab Doors" : "âœ“ Gloss Door Sash Profiles & ACP/Glass Infills"
      feature_3 = is_board ? "âœ“ In-Memory RAM Engine Stream" : "âœ“ Dynamic Space Distribution & Gap Auto-Fill"

      dialog = UI::HtmlDialog.new({
        :dialog_title => "#{app_title} â€” Cloud Authentication & License",
        :preferences_key => is_board ? "com.cabinetrix.cloud_loader_login" : "com.cabinex.cloud_loader_login",
        :width => 460,
        :height => 680,
        :resizable => false,
        :style => UI::HtmlDialog::STYLE_DIALOG
      })

      login_html = <<-HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <title>#{app_title} Login</title>
          <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@600&display=swap" rel="stylesheet">
          <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            body {
              font-family: 'Inter', sans-serif;
              background: #0f172a;
              color: #f8fafc;
              padding: 26px 22px;
              font-size: 13px;
            }
            .header {
              text-align: center;
              margin-bottom: 18px;
            }
            .brand-logo { font-size: 32px; margin-bottom: 4px; }
            .brand-title {
              font-size: 20px;
              font-weight: 800;
              color: #10b981;
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
              background: #059669;
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
              transition: border 0.2s;
            }
            input:focus, select:focus {
              border-color: #10b981;
              box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.2);
            }
            
            .server-toggle {
              background: rgba(16, 185, 129, 0.05);
              border: 1px dashed rgba(16, 185, 129, 0.3);
              padding: 10px;
              border-radius: 6px;
              margin-bottom: 16px;
            }
            
            .btn-login {
              width: 100%;
              padding: 12px;
              background: linear-gradient(135deg, #059669, #10b981);
              border: none;
              border-radius: 6px;
              color: white;
              font-weight: 700;
              font-size: 13px;
              cursor: pointer;
              box-shadow: 0 4px 12px rgba(16, 185, 129, 0.35);
              margin-top: 6px;
            }
            .btn-login:hover { background: linear-gradient(135deg, #047857, #059669); }
            
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
            <div class="brand-logo">#{app_logo}</div>
            <div class="brand-title">#{app_title}</div>
            <div class="brand-subtitle">#{app_subtitle}</div>
          </div>

          <div style="display: none;">
            <select id="serverEnv"><option value="https://cabinex-cloud.vercel.app" selected>Production Vercel Cloud</option></select>
          </div>

          <div class="auth-tabs">
            <button class="auth-tab-btn active" id="tabKeyBtn" onclick="switchAuthMode('key')">ðŸ”‘ License Token Key</button>
            <button class="auth-tab-btn" id="tabEmailBtn" onclick="switchAuthMode('email')">ðŸ‘¤ Email & Password</button>
          </div>

          <!-- Mode 1: License Token Key -->
          <div id="paneKey">
            <div class="form-group">
              <label for="txtLicenseKey">Purchased License Token</label>
              <input type="text" id="txtLicenseKey" value="#{default_key}" placeholder="e.g. CBX-PRO-XXXX-XXXX" style="font-family: 'JetBrains Mono', monospace; font-weight: 700; color: #10b981;" />
            </div>
          </div>

          <!-- Mode 2: Email & Password -->
          <div id="paneEmail" style="display: none;">
            <div class="form-group">
              <label for="txtEmail">Registered Studio Email</label>
              <input type="email" id="txtEmail" placeholder="studio@example.com" />
            </div>
            <div class="form-group">
              <label for="txtPassword">Account Password</label>
              <input type="password" id="txtPassword" placeholder="â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢" />
            </div>
          </div>

          <button class="btn-login" onclick="triggerLogin()">ðŸš€ Authenticate & Stream Engine</button>
          
          <div id="statusBox" class="status-box"></div>

          <div class="features-list">
            <p><strong>#{feature_1}</strong></p>
            <p><strong>#{feature_2}</strong></p>
            <p><strong>#{feature_3}</strong></p>
          </div>

          <script>
            let currentMode = 'key';

            function switchAuthMode(mode) {
              currentMode = mode;
              document.getElementById('tabKeyBtn').className = (mode === 'key') ? 'auth-tab-btn active' : 'auth-tab-btn';
              document.getElementById('tabEmailBtn').className = (mode === 'email') ? 'auth-tab-btn active' : 'auth-tab-btn';
              document.getElementById('paneKey').style.display = (mode === 'key') ? 'block' : 'none';
              document.getElementById('paneEmail').style.display = (mode === 'email') ? 'block' : 'none';
            }

            function toggleCustomServer() {
              const sel = document.getElementById('serverEnv').value;
              document.getElementById('customServerWrap').style.display = (sel === 'custom') ? 'block' : 'none';
            }

            function setStatus(msg, type) {
              const el = document.getElementById('statusBox');
              el.innerText = msg;
              el.className = 'status-box status-' + type;
            }

            function triggerLogin() {
              let serverUrl = 'https://cabinex-cloud.vercel.app';

              const payload = {
                server_url: serverUrl,
                app_type: '#{APP_TYPE}',
                mode: currentMode
              };

              if (currentMode === 'key') {
                const key = document.getElementById('txtLicenseKey').value.trim();
                if (!key) { setStatus('Please enter your license token.', 'error'); return; }
                payload.license_key = key;
              } else {
                const email = document.getElementById('txtEmail').value.trim();
                const pass = document.getElementById('txtPassword').value;
                if (!email || !pass) { setStatus('Email and password are required.', 'error'); return; }
                payload.email = email;
                payload.password = pass;
              }

              setStatus('Authenticating with #{app_title} Cloud...', 'info');
              
              if (window.sketchup && window.sketchup.doCloudAuth) {
                window.sketchup.doCloudAuth(JSON.stringify(payload));
              } else {
                setStatus('Bridge Error: window.sketchup not ready.', 'error');
              }
            }

            window.onAuthResponse = function(status, message) {
              if (status === 'success') {
                setStatus(message || 'Success! Launching #{app_title} Studio...', 'success');
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
          server_url = 'https://cabinex-cloud.vercel.app'
          @active_server = server_url

          # 1. Authenticate with Server
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

          # Save the key for continuous use
          if data['license_key'] && !data['license_key'].empty?
            Sketchup.write_default('CabinexAI', 'license_key', data['license_key'].to_s)
          elsif data['email'] && !data['email'].empty?
            Sketchup.write_default('CabinexAI', 'license_key', data['email'].to_s)
          end

          # 2. Fetch Protected In-Memory Engine Payload
          engine_uri = URI.parse("#{server_url}/api/engine/load")
          engine_req = Net::HTTP::Post.new(engine_uri.path, {'Content-Type' => 'application/json'})
          engine_req.body = { token: token, app_type: APP_TYPE }.to_json

          http_eng = Net::HTTP.new(engine_uri.host, engine_uri.port)
          if engine_uri.scheme == 'https'
            http_eng.use_ssl = true
            http_eng.verify_mode = OpenSSL::SSL::VERIFY_NONE
          end
          http_eng.open_timeout = 10
          http_eng.read_timeout = 25

          engine_res = http_eng.request(engine_req)
          engine_json = JSON.parse(engine_res.body)

          if engine_res.code != '200' || !engine_json['success']
            err_msg = engine_json['error'] || "Failed to load cloud engine."
            dialog.execute_script("onAuthResponse('error', #{err_msg.to_json});")
            next
          end

          # 3. Stream Engine Directly into SketchUp Memory (RAM)
          engine_code = engine_json['engine']
          if engine_code.nil? || engine_code.empty?
            dialog.execute_script("onAuthResponse('error', 'Cloud engine payload was empty. Please retry.');")
            next
          end
          dialog.execute_script("onAuthResponse('success', 'License active! Streaming in-memory engine...');")

          UI.start_timer(0.2, false) do
            begin
              eval(engine_code, TOPLEVEL_BINDING)
              
              # PATCH: Reload local engine to restore methods missing in cloud engine
              # Cloud engine is a subset; local cbx_hybrid_engine.rb has full implementation
              engine_file = File.join(File.dirname(__FILE__), 'cbx_hybrid_engine.rb')
              load engine_file if File.exist?(engine_file)
              
              # Verify critical methods exist
              critical_methods = [:build_aluminum_continuous_base_run, :build_aluminum_continuous_wall_run,
                                  :build_aluminum_top_cabinet, :build_aluminum_l_corner_tunnel,
                                  :build_sash_assembly, :create_notched_horizontal_panel, :generate_bom_and_nesting]
              missing = critical_methods.reject { |m| CBXHybridEngine.respond_to?(m) }
              unless missing.empty?
                puts ">> WARNING: CBXHybridEngine missing methods after reload: #{missing.join(', ')}"
              else
                puts ">> CBXHybridEngine: All critical methods restored"
              end
              
              # Ensure attr_accessors exist (in case local engine doesn't define them)
              unless CBXHybridEngine.respond_to?(:top_door_style=)
                class << CBXHybridEngine
                  attr_accessor :top_door_style, :base_door_style, :tall_unit_style
                end
              end
              CBXHybridEngine.top_door_style  ||= 'glass_sash'
              CBXHybridEngine.base_door_style ||= 'solid_acp'
              CBXHybridEngine.tall_unit_style ||= 'double_oven'
              
              # Also reload planner and submodules to ensure they reference the restored engine methods
              %w[cbx_hybrid_planner.rb cbx_viewport_hud.rb cbx_box_editor.rb cbx_exports.rb].each do |f|
                path = File.join(File.dirname(__FILE__), f)
                load path if File.exist?(path)
              end
              
              # Final verification
              if CBXHybridEngine.respond_to?(:build_aluminum_continuous_base_run)
                puts ">> VERIFIED: aluminum engine methods available"
              else
                puts ">> ERROR: aluminum engine methods STILL MISSING!"
              end
              
              if defined?(CabinexAI::HybridPlanner)
                CabinexAI::HybridPlanner.show_dialog
              end

              puts ">> #{app_title}: Cloud Engine v5.0 loaded for #{@active_user} (Tokens: #{@token_balance})!"
              dialog.close
            rescue => eval_err
              first_bt = eval_err.backtrace.first(3).join(' | ') rescue '(no backtrace)'
              puts ">> Cloud Engine Eval Error: #{eval_err.message}\n#{eval_err.backtrace.first(10).join("\n")}"
              dialog.execute_script("onAuthResponse('error', #{('Engine error: ' + eval_err.message).to_json});")
              UI.messagebox("Cloud Engine Error:\n#{eval_err.message}\n\nAt: #{first_bt}\n\nCheck Ruby Console (Window > Ruby Console).")
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
      @active_user || 'studio@cabinetrix.ai'
    end

    def self.token_balance
      @token_balance || 100
    end

    def self.active_server
      @active_server || DEFAULT_PROD_URL
    end

    # Deduct tokens on 3D generation
    def self.consume_tokens(specs)

      begin
        uri = URI.parse("#{@active_server}/api/kitchen/consume-tokens")
        req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
        req.body = {
          user_identifier: @active_user,
          specs: specs
        }.to_json

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http.open_timeout = 6
        http.read_timeout = 10

        res = http.request(req)
        json = JSON.parse(res.body)
        
        if json['success']
          @token_balance = json['tokens_remaining'] if json['tokens_remaining']
        end
        json
      rescue => e
        puts "Token consumption network error: #{e.message}"
        { 'success' => true, 'tokens_remaining' => @token_balance }
      end
    end

    # Send telemetry event to cloud (non-blocking, fire-and-forget)
    def self.send_telemetry(event_type, project_name, wall_a, wall_b, linear_ft, quote_lkr)
      UI.start_timer(0.1, false) do
        begin
          uri = URI.parse("#{@active_server}/api/telemetry/event")
          req = Net::HTTP::Post.new(uri.path, {'Content-Type' => 'application/json'})
          req.body = {
            event: event_type,
            user_identifier: @active_user,
            project_name: project_name,
            wall_a_mm: wall_a.to_mm.round,
            wall_b_mm: wall_b.to_mm.round,
            linear_ft: linear_ft.round(1),
            quote_lkr: quote_lkr.round(2),
            timestamp: Time.now.iso8601
          }.to_json

          http = Net::HTTP.new(uri.host, uri.port)
          http.use_ssl = true if uri.scheme == 'https'
          http.open_timeout = 3
          http.read_timeout = 5
          http.request(req)
        rescue => e
          puts "Telemetry send notice: #{e.message}"
        end
      end
      { 'success' => true }
    end
  end
end

# CloudUI module for preloaded HTML content from cloud (Base64 or raw HTML)
module CabinexAI
  module CloudUI
    PLANNER_B64   = ''
    PLANNER_HTML  = ''
    REPORT_B64    = ''
    REPORT_HTML   = ''
  end
end
