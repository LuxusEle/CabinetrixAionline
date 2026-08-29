require 'sketchup.rb'
require 'json'

module CabinexAI
  module Assistant
    # Update this path to wherever the HTML file is stored
    HTML_PATH = File.join(__dir__, 'cbx_ai_chat.html')

    def self.show_dialog
      if @dialog && @dialog.visible?
        @dialog.bring_to_front
        return
      end

      @dialog = UI::HtmlDialog.new(
        {
          :dialog_title => "Cabinex AI Designer",
          :preferences_key => "com.cabinex.ai_designer",
          :scrollable => true,
          :resizable => true,
          :width => 450,
          :height => 700,
          :min_width => 300,
          :min_height => 400,
          :style => UI::HtmlDialog::STYLE_DIALOG
        }
      )
      
      @dialog.set_file(HTML_PATH)

      # Callback to build the cabinet when AI completes the conversation
      @dialog.add_action_callback("buildCabinet") do |action_context, params_json|
        begin
          specs = JSON.parse(params_json) # Parses to a Hash or Array
          # If it's a single hash instead of an array, wrap it in an array to be safe
          specs_array = specs.is_a?(Array) ? specs : [specs]
          
          puts "Received Specs from AI: #{specs_array.inspect}"
          
          # Trigger the generation script
          if defined?(CBXCabinetEngine)
            CBXCabinetEngine.build_from_json(specs_array)
          else
            UI.messagebox("Error: Please load 'cbx_cabinet_engine.rb' and 'CBX_Shotgun V2.rb' first.")
          end
        rescue => e
          puts "Error parsing AI specs: #{e.message}"
          UI.messagebox("Failed to build cabinet. See Ruby Console for details.")
        end
      end

      # Callback to show a simple notification from JS
      @dialog.add_action_callback("notify") do |action_context, msg|
        UI.messagebox(msg)
      end

      @dialog.show
    end
  end
end

unless file_loaded?(__FILE__)
  menu = UI.menu('Plugins')
  menu.add_item('Cabinex AI Designer') {
    CabinexAI::Assistant.show_dialog
  }
  file_loaded(__FILE__)
end
