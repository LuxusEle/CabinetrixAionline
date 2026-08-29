# =============================================================================
# Cabinex AI — Fixed Viewport Live BOM HUD Overlay
# Displays real-time quotation, linear footage, and bar counts in top-left viewport
# =============================================================================
require 'sketchup.rb'

module CabinexAI
  module ViewportHUD
    @current_quote_lkr = 0
    @linear_ft = 0.0
    @kitchen_type = 'FULL_ALU_FRAME'
    @box_bars = 0
    @sash_bars = 0

    def self.update_from_specs(specs, bom_data = nil)
      room = specs['room'] || {}
      wa = (room['wall_a_mm'] || 2488).to_f
      wb = (room['wall_b_mm'] || 0).to_f
      wc = (room['wall_c_mm'] || 0).to_f
      layout = room['layout_type'] || 'L_SHAPE'
      wb = 0 if layout == 'LINEAR'
      wc = 0 unless layout == 'U_SHAPE'

      base_ft = ((wa + wb + wc) / 304.8)
      modules = specs['custom_wall_modules'] || {}
      tall_count = 0
      modules.each_value do |list|
        (list || []).each do |m|
          t = (m['type'] || '').to_s
          tall_count += 1 if t.start_with?('tall_')
        end
      end

      total_linear_ft = base_ft * 2.0 + (tall_count * 7.0)
      @linear_ft = total_linear_ft.round(1)

      kitchen_type = (specs['project_settings'] && specs['project_settings']['construction_logic']) ||
                     (specs['style'] && specs['style']['kitchen_type']) || 'FULL_ALU_FRAME'
      @kitchen_type = kitchen_type.to_s.gsub('_', ' ')

      # Calculate estimated cost
      quote = specs['quote'] || {}
      markup_pct = (quote['markup_pct'] || 35.0).to_f
      base_rate = 49500 # LKR per linear ft
      base_cost = total_linear_ft * base_rate
      @current_quote_lkr = (base_cost * (1.0 + markup_pct / 100.0)).round

      if bom_data && bom_data[:nesting]
        n = bom_data[:nesting]
        @box_bars = (n[:boxbar_matte_black_6m_bars] && n[:boxbar_matte_black_6m_bars][:total_bars]) || 6
        @sash_bars = (n[:sash_gloss_6m_bars] && n[:sash_gloss_6m_bars][:total_bars]) || 4
      else
        @box_bars = [(@linear_ft / 3.2).ceil, 4].max
        @sash_bars = [(@linear_ft / 4.8).ceil, 3].max
      end

      refresh_hud_display
    end

    def self.refresh_hud_display
      model = Sketchup.active_model
      return unless model

      hud_str = "💎 CABINEX AI | Live BOM: LKR #{format_number(@current_quote_lkr)} | " \
                "Linear: #{@linear_ft} ft | Type: #{@kitchen_type} | Bars: #{@box_bars} Box / #{@sash_bars} Sash"

      # 1. Update Status Bar
      Sketchup.set_status_text(hud_str)

      # 2. Update persistent 2D Top-Left Model Note Text
      begin
        model.start_operation('Update Cabinex HUD', true, false, true)
        
        # Remove old HUD notes
        model.entities.grep(Sketchup::Text).each do |t|
          t.erase! if t.get_attribute('CBX', 'is_hud_note') == true
        end

        note = model.entities.add_text(hud_str, Geom::Point3d.new(30.mm, 0, 2600.mm))
        if note
          note.set_attribute('CBX', 'is_hud_note', true)
          note.name = 'Cabinex_Live_HUD'
        end

        model.commit_operation
      rescue => e
        puts "HUD refresh notice: #{e.message}"
      end
    end

    def self.format_number(val)
      val.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
    end
  end
end
