# =============================================================================
# Cabinex AI — Open Front Interactive Tool (door swing / drawer slide / reveal)
# (c) 2026 Cabinex AI. All Rights Reserved.
#
# Click any unit from RunCabinetGrid (or any tagged front group) and it toggles:
#   door   -> rotation about its hinge axis (left/right) by ~105deg
#   drawer -> slides OUT along the unit's -Y (front) axis
#   shelf  -> revealed once the door is open
# Toggle again to close. Works off CBX tags from build_slab_door/build_handle/...
#
# USAGE (SketchUp):
#   load "C:/Users/asank/Documents/CabinexAi/cbxcabinet_open_front.rb"
#   CabinexAI::OpenFrontTool.activate
# or use the "Open Front" toolbar button registered by loader.rb.
# =============================================================================
require 'sketchup.rb'

module CabinexAI
  module OpenFrontTool
    @open_state = {} # group.object_id => open? (bool)

    # --- SketchUp Tool ---
    class OpenClickTool
      def activate
        Sketchup.set_status_text('Cabinex AI: Click a door or drawer front to open/close it (or click a unit).')
        @cursor_id = UI.create_cursor(File.join(__dir__, 'icons', 'icon_open_small.png'), 0, 0) rescue nil
      end

      def onSetCursor
        UI.set_cursor(@cursor_id) if @cursor_id
      end

      def onMouseMove(flags, x, y, view)
        ph = view.pick_helper
        ph.do_pick(x, y)
        e = ph.best_picked
        front = OpenFrontTool.find_openable(e)
        if front
          role = front.get_attribute('CBX', 'cbx_front') || front.name
          view.tooltip = "Click to #{OpenFrontTool.open?(front) ? 'close' : 'open'}: #{role}"
        else
          view.tooltip = ''
        end
      end

      def onLButtonDown(flags, x, y, view)
        ph = view.pick_helper
        ph.do_pick(x, y)
        target = OpenFrontTool.find_openable(ph.best_picked)
        if target
          OpenFrontTool.toggle_open(target)
        else
          Sketchup.set_status_text('Cabinex AI: No openable front under cursor. Click a CG_ door/drawer/shelf.')
        end
      end
    end

    # Traverse up to the tagged openable group (front / shelf / unit).
    def self.find_openable(entity)
      return nil unless entity
      curr = entity
      while curr && curr.respond_to?(:parent)
        if curr.is_a?(Sketchup::Group) || curr.is_a?(Sketchup::ComponentInstance)
          cbx = curr.get_attribute('CBX', 'cbx_front')
          return curr if cbx # door | drawer | shelf | faceframe
          name = curr.name.to_s
          return curr if name.start_with?('CG_')
        end
        curr = curr.parent.is_a?(Sketchup::ComponentDefinition) ? curr.parent.instances.first : nil
      end
      nil
    end

    def self.open?(group)
      @open_state[group.object_id] == true
    end

    # Toggles the open/closed state of a front group.
    def self.toggle_open(group)
      cbx = group.get_attribute('CBX', 'cbx_front').to_s
      model = Sketchup.active_model
      model.start_operation('OpenFront', true)
      if open?(group)
        close_group(group)
        @open_state[group.object_id] = false
      else
        open_group(group)
        @open_state[group.object_id] = true
      end
      model.commit_operation
    end

    def self.open_group(group)
      cbx = group.get_attribute('CBX', 'cbx_front').to_s
      case cbx
      when 'door'
        swing_door(group, 105)
      else
        slide_drawer(group, 320.mm) # drawer fronts + faceframe slide out
      end
      mark_siblings(group)
    end

    def self.close_group(group)
      cbx = group.get_attribute('CBX', 'cbx_front').to_s
      case cbx
      when 'door'
        swing_door(group, 0)
      else
        slide_drawer(group, 0)
      end
    end

    # Rotate a door about its hinge (vertical) axis. Hinge is at the group's
    # hinge_edge (left or right of its bounding box) at the front face.
    def self.swing_door(group, angle_deg)
      bounds = group.bounds
      hinge_left = group.get_attribute('CBX', 'hinge_left') == true
      # hinge axis sits on the front plane (max y corner), at left/right x edge
      front_y = bounds.max.y
      hinge_x = hinge_left ? bounds.min.x : bounds.max.x
      cx = bounds.min.x + (bounds.max.x - bounds.min.x) / 2.0
      cz = bounds.min.z + (bounds.max.z - bounds.min.z) / 2.0
      # build pivot: translate to hinge, rotate about Z, translate back
      pivot = Geom::Point3d.new(hinge_x, front_y, cz)
      tr = Geom::Transformation.new(pivot) *
           Geom::Transformation.rotation(ORIGIN, Z_AXIS, angle_deg.degrees) *
           Geom::Transformation.new(ORIGIN - pivot)
      group.transform!(tr)
    end

    # Slide a drawer front (and its handle) along the front (-Y) axis.
    def self.slide_drawer(group, dist)

      group.transform!(Geom::Transformation.translation([0, -dist, 0]))
      # move the associated handle with its drawer front (same x/z, next to it)
      handle = find_sibling_handle(group)
      handle.transform!(Geom::Transformation.translation([0, -dist, 0])) if handle
    end

    def self.find_sibling_handle(group)
      parent = group.parent
      return nil unless parent
      cx = group.bounds.center.x
      cz = group.bounds.center.z
      parent.entities.grep(Sketchup::Group).each do |g|
        next if g == group
        next unless g.get_attribute('CBX', 'cbx_handle')
        bc = g.bounds.center
        return g if (bc.x - cx).abs < 300.mm && (bc.z - cz).abs < 300.mm
      end
      nil
    end

    def self.mark_siblings(group)
      # reveal any shelves in the same unit (they were hidden behind the door -
      # here they are always present; the door swing just exposes them visually).
      parent = group.parent
      return unless parent
      parent.entities.grep(Sketchup::Group).each do |g|
        next if g == group
        g.set_attribute('CBX', 'revealed', true) if g.get_attribute('CBX', 'cbx_front') == 'shelves'
      end
    end

    # --- Toolbar activation ---
    def self.activate
      Sketchup.active_model.select_tool(OpenClickTool.new)
    end

    # Public: toggle whatever is selected (used by toolbar command too).
    def self.toggle_selection
      model = Sketchup.active_model
      sel = model.selection
      return UI.messagebox('Select a door/drawer front first.') if sel.empty?
      target = find_openable(sel.first)
      return UI.messagebox('Selection is not an openable front.') unless target
      toggle_open(target)
      activate
    end

    def self.show_toolbar_help
      UI.messagebox('Click a door/drawer front to open or close it. Click again to toggle back.')
    end
  end
end
