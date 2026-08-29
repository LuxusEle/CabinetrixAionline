# =============================================================================
# Cabinex AI — Interactive Cabinet Box Editor Tool & Compact Parameter Dialog
# Allows clicking 3D cabinet boxes to live-edit types, dimensions, and infills
# =============================================================================
require 'sketchup.rb'
require 'json'

module CabinexAI
  module BoxEditor
    @current_selection = nil

    # --- 1. Custom SketchUp Selection Tool ---
    class EditBoxTool
      def activate
        Sketchup.set_status_text("Cabinex AI: Click any cabinet box in the 3D model to edit parameters...")
        @cursor_id = UI.create_cursor(File.join(__dir__, 'icons', 'icon_edit_box_small.png'), 0, 0) rescue nil
      end

      def onSetCursor
        UI.set_cursor(@cursor_id) if @cursor_id
      end

      def onMouseMove(flags, x, y, view)
        ph = view.pick_helper
        ph.do_pick(x, y)
        target = CabinexAI::BoxEditor.find_cabinet_box(ph.best_picked)
        if target
          name = target.name.to_s
          w = target.get_attribute('CBX', 'width_mm') || (target.bounds.width.to_mm.round)
          role = target.get_attribute('CBX', 'role') || name
          view.tooltip = "Click to Edit: #{role} (#{w}mm)"
          Sketchup.set_status_text("Hovering: #{role} | Click to edit parameters")
        else
          view.tooltip = ""
        end
      end

      def onLButtonDown(flags, x, y, view)
        ph = view.pick_helper
        ph.do_pick(x, y)
        target = CabinexAI::BoxEditor.find_cabinet_box(ph.best_picked)
        if target
          CabinexAI::BoxEditor.open_editor_for_box(target)
        else
          UI.messagebox("Please click directly on a Cabinex cabinet box group.")
        end
      end
    end

    # Traverse upward to find the primary unit group
    def self.find_cabinet_box(entity)
      return nil unless entity
      curr = entity
      while curr && curr.respond_to?(:parent)
        if curr.is_a?(Sketchup::Group) || curr.is_a?(Sketchup::ComponentInstance)
          name = curr.name.to_s
          is_box = curr.get_attribute('CBX', 'is_cabinet_box') == true ||
                   curr.get_attribute('CBX', 'bay_index') != nil ||
                   name.start_with?('Unit_') || name.include?('Base_Cabinet') ||
                   name.include?('Tall_Oven') || name.include?('Tall_Pantry') ||
                   name.include?('Blind_Corner') || name.include?('Staged_Pod_')
          return curr if is_box
        end
        curr = (curr.respond_to?(:parent) && curr.parent.is_a?(Sketchup::ComponentDefinition)) ? curr.parent.instances.first : nil
      end
      entity.is_a?(Sketchup::Group) ? entity : nil
    end

    # --- 2. Compact Native UI Dialog with Auto-Fill Spacing Algorithm ---
    def self.open_editor_for_box(box_grp)
      @current_selection = box_grp
      name = box_grp.name.to_s
      wall = box_grp.get_attribute('CBX', 'wall_key') || (name.include?('Wall_B') ? 'B' : 'A')
      bay_idx = (box_grp.get_attribute('CBX', 'bay_index') || 0).to_i
      curr_type = box_grp.get_attribute('CBX', 'module_type') || infer_type_from_name(name)
      curr_width = (box_grp.get_attribute('CBX', 'width_mm') || box_grp.bounds.width.to_mm).round
      curr_infill = box_grp.get_attribute('CBX', 'infill') || 'acp'
      curr_overhead = box_grp.get_attribute('CBX', 'overhead') || 'yes'
      curr_handle = box_grp.get_attribute('CBX', 'handle') || 'top'
      curr_drawers = (box_grp.get_attribute('CBX', 'drawer_count') || 3).to_i

      # Native UI Prompts
      prompts = [
        "Module Type:  ",
        "Width (mm):  ",
        "Infill Material:  ",
        "Overhead Unit:  ",
        "Handle Style:  ",
        "Drawer Count (if drawers):  "
      ]

      defaults = [
        curr_type.to_s,
        curr_width.to_i,
        curr_infill.to_s,
        curr_overhead.to_s,
        curr_handle.to_s,
        curr_drawers.to_i
      ]

      choices = [
        "drawers|cooker|sink|door|blind_corner|tall_oven|tall_pantry|open_shelf",
        "",
        "acp|glass|fluted_glass|woodgrain",
        "yes|hood|open_rack|none",
        "top|side|gola",
        "2|3|4"
      ]

      results = UI.inputbox(prompts, defaults, choices, "📦 Edit Cabinet Box [Native UI]")
      return unless results # User canceled

      # Extract results
      new_type = results[0]
      new_width = results[1].to_i
      new_infill = results[2]
      new_overhead = results[3]
      new_handle = results[4]
      new_drawers = results[5].to_i

      specs = CabinexAI::HybridPlanner.last_specs || {}
      return unless specs && specs['custom_wall_modules']

      mods = specs['custom_wall_modules'][wall] || []
      return if mods.empty?

      # Find module at index or fallback
      idx = bay_idx
      if idx >= mods.length
        idx = mods.length - 1
      end

      # Mark user_edited = true
      mods[idx] = {
        'type' => new_type,
        'width' => new_width.to_f,
        'infill' => new_infill,
        'overhead' => new_overhead,
        'handle' => new_handle,
        'drawer_count' => new_drawers,
        'user_edited' => true
      }

      # Gap distribution logic
      wall_length = 0.0
      case wall
      when 'A'
        wall_length = (specs['room']['wall_a_mm'] || 2488).to_f
      when 'B'
        wall_length = (specs['room']['wall_b_mm'] || 2379).to_f
      when 'C'
        wall_length = (specs['room']['wall_c_mm'] || 0).to_f
      when 'Island'
        wall_length = (specs['room']['island_length_mm'] || 0).to_f
      end

      current_sum = mods.sum { |m| m['width'].to_f }
      diff = wall_length - current_sum

      if diff.abs > 5.0
        # Ask to auto-fill
        choice = UI.messagebox("A gap/overflow of #{diff.round}mm has been created. Would you like to auto-fill the remaining space?", MB_YESNO)
        if choice == IDYES # 6
          # Find resizable non-user-edited modules
          non_edited = mods.select { |m| !m['user_edited'] }

          # If all modules are user-edited, optionally distribute among all
          if non_edited.empty?
            choice_all = UI.messagebox("All boxes are manually edited. Would you like to distribute the gap among all boxes instead?", MB_YESNO)
            non_edited = mods if choice_all == IDYES
          end

          unless non_edited.empty?
            # Design Rule: Cooker/Hood unit should remain 600mm.
            # Ask user if they want to accept or skip resizing for Cooker/Hood
            non_edited.each do |m|
              if m['type'] == 'cooker' || m['overhead'] == 'hood'
                # Prompt to skip or resize
                mod_label = "Module #{mods.index(m) + 1} (Cooker/Hood)"
                skip_choice = UI.messagebox("#{mod_label} is standard 600mm. Do you want to KEEP/SKIP it at 600mm? (Select Yes to Skip, No to allow resizing)", MB_YESNO)
                if skip_choice == IDYES
                  m['user_edited_temp'] = true
                end
              end
            end

            # Recalculate candidates
            candidates = non_edited.reject { |m| m['user_edited_temp'] }
            if candidates.empty?
              UI.messagebox("No resizable candidates left. Gap/overflow remains.")
            else
              # Distribute diff equally
              diff_share = diff / candidates.length
              candidates.each do |m|
                m['width'] = [(m['width'] + diff_share).round, 150.0].max # Ensure min size
              end

              # Rounding adjustment
              final_sum = mods.sum { |m| m['width'].to_f }
              rounding_diff = wall_length - final_sum
              if rounding_diff.abs > 0.1
                candidates.last['width'] = [(candidates.last['width'] + rounding_diff).round, 150.0].max
              end
            end

            # Clean temp attributes
            mods.each { |m| m.delete('user_edited_temp') }
          end
        end
      end

      # Update attributes on the actual SketchUp group
      box_grp.set_attribute('CBX', 'module_type', new_type)
      box_grp.set_attribute('CBX', 'width_mm', new_width)
      box_grp.set_attribute('CBX', 'infill', new_infill)
      box_grp.set_attribute('CBX', 'overhead', new_overhead)
      box_grp.set_attribute('CBX', 'handle', new_handle)
      box_grp.set_attribute('CBX', 'drawer_count', new_drawers)

      # Save and live rebuild
      specs['custom_wall_modules'][wall] = mods
      CabinexAI::HybridPlanner.last_specs = specs
      bom = CabinexAI::HybridPlanner.build_from_specs(specs)
      CabinexAI::ViewportHUD.update_from_specs(specs, bom) if defined?(CabinexAI::ViewportHUD)

      # Recalculate nesting and refresh BOM
      model = Sketchup.active_model
      bom = CBXHybridEngine.generate_bom_and_nesting(model.entities) rescue nil
      CabinexAI::ViewportHUD.update_from_specs(specs, bom) if defined?(CabinexAI::ViewportHUD)
      Sketchup.set_status_text("Cabinex AI: Box editing completed. Nesting & BOM updated!")
    end

    def self.infer_type_from_name(name)
      n = name.to_s.downcase
      return 'drawers' if n.include?('drawer')
      return 'cooker' if n.include?('cooker') || n.include?('hob')
      return 'sink' if n.include?('sink')
      return 'tall_oven' if n.include?('tall_oven') || n.include?('oven')
      return 'tall_pantry' if n.include?('tall_pantry') || n.include?('pantry') || n.include?('tall')
      return 'blind_corner' if n.include?('corner') || n.include?('blind')
      return 'open_shelf' if n.include?('shelf') || n.include?('open')
      'door'
    end
  end
end
