# =============================================================================
# Cabinex AI — Comprehensive Exports Module (PDF Report, 2D DXF, Excel CSV BOM)
# =============================================================================
require 'sketchup.rb'
require 'json'

module CabinexAI
  module Exports
    # --- 1. Export PDF Workshop Production Pack ---
    def self.export_pdf_report
      specs = CabinexAI::HybridPlanner.last_specs
      if specs.nil? || specs.empty?
        # Reconstruct default specs from active model
        model = Sketchup.active_model
        saved = model.get_attribute('CBX', 'last_project_settings')
        proj_settings = saved ? JSON.parse(saved) : {} rescue {}
        specs = {
          'room' => { 'wall_a_mm' => 2488, 'wall_b_mm' => 2379, 'ceiling_height_mm' => 2743 },
          'quote' => { 'client_name' => 'Valued Client', 'project_name' => 'Luxury All-Aluminum Kitchen', 'markup_pct' => 35.0 },
          'project_settings' => proj_settings,
          'custom_wall_modules' => {}
        }
      end

      Sketchup.set_status_text("Cabinex AI: Exporting Customer Workshop Presentation & Report...")
      CabinexAI::HybridPlanner.show_workshop_report(specs)
    end

    # --- 2. Export Industrial 2D DXF CNC / Saw Cutting Sheets ---
    def self.export_dxf_cutting_sheets
      model = Sketchup.active_model
      unless model
        UI.messagebox("No active model found.")
        return
      end

      # 1. Run the BOM & Nesting Engine to generate exact 2D nested sheets
      bom_data = CBXHybridEngine.generate_bom_and_nesting

      sheets = bom_data[:nesting][:acp_2440x1220_nesting][:sheets] || []
      
      if sheets.empty?
        UI.messagebox("No Aluminum ACP Cladding panels found to nest for CNC Export.")
        return
      end

      default_name = "Cabinex_Nested_Sheets_#{Time.now.strftime('%Y%m%d')}.dxf"
      save_path = UI.savepanel("Export DXF Nested Sheets", "", default_name)
      return unless save_path

      dxf_content = generate_nested_dxf_string(sheets)
      File.write(save_path, dxf_content)

      total_parts = sheets.sum { |s| s[:cuts].length }
      UI.messagebox("✅ DXF Nested Sheets exported successfully to:\n\n#{save_path}\n\nTotal Sheets: #{sheets.length}\nTotal Cut Pieces: #{total_parts} parts")
      Sketchup.set_status_text("DXF Export complete: #{File.basename(save_path)}")
    end

    def self.collect_cut_pieces(group, list)
      name = group.name.to_s
      role = group.get_attribute('CBX', 'role').to_s
      w = (group.get_attribute('CBX', 'width_mm') || group.bounds.width.to_mm).round(1)
      l = (group.get_attribute('CBX', 'length_mm') || [group.bounds.height.to_mm, group.bounds.depth.to_mm].max).round(1)

      if role.include?('BoxBar') || name.include?('Post') || name.include?('Rail') || name.include?('Upright')
        list << { name: name.empty? ? 'BoxBar_Member' : name, layer: 'ALU_BOXBAR_25MM', w: 25.4, l: l, qty: 1 }
      elsif role.include?('Sash') || name.include?('Sash')
        list << { name: name.empty? ? 'Sash_Member' : name, layer: 'ALU_SASH_45MM', w: 45.0, l: l, qty: 1 }
      elsif role.include?('Panel') || role.include?('Clad') || name.include?('ACP')
        list << { name: name.empty? ? 'ACP_Panel' : name, layer: 'SHEET_ACP_3MM', w: w, l: l, qty: 1 }
      end
      
      group.entities.grep(Sketchup::Group).each { |sub| collect_cut_pieces(sub, list) }
    end

    def self.generate_nested_dxf_string(sheets)
      dxf = "0\nSECTION\n2\nHEADER\n0\nENDSEC\n"
      dxf += "0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLAYER\n"
      
      layers = ['SHEET_BORDER', 'CUT_PERIMETER', 'CUT_NOTCH', 'TEXT_LABELS']
      colors = { 'SHEET_BORDER' => 8, 'CUT_PERIMETER' => 7, 'CUT_NOTCH' => 1, 'TEXT_LABELS' => 3 }
      
      layers.each do |lyr|
        col = colors[lyr]
        dxf += "0\nLAYER\n2\n#{lyr}\n70\n0\n62\n#{col}\n6\nCONTINUOUS\n"
      end
      dxf += "0\nENDTAB\n0\nENDSEC\n"

      dxf += "0\nSECTION\n2\nENTITIES\n"

      cur_y = 0.0

      sheets.each_with_index do |sheet, idx|
        sheet_w = sheet[:sheet_w] || 2440.0
        sheet_h = sheet[:sheet_h] || 1220.0
        sheet_x = 0.0
        sheet_y = cur_y
        
        # Draw 2440x1220 Sheet Border
        dxf += "0\nLWPOLYLINE\n8\nSHEET_BORDER\n90\n4\n70\n1\n"
        dxf += "10\n#{sheet_x}\n20\n#{sheet_y}\n"
        dxf += "10\n#{sheet_x + sheet_w}\n20\n#{sheet_y}\n"
        dxf += "10\n#{sheet_x + sheet_w}\n20\n#{sheet_y + sheet_h}\n"
        dxf += "10\n#{sheet_x}\n20\n#{sheet_y + sheet_h}\n"
        
        # Sheet Label
        dxf += "0\nTEXT\n8\nTEXT_LABELS\n10\n#{sheet_x}\n20\n#{sheet_y + sheet_h + 20}\n40\n24.0\n1\nSHEET #{idx + 1} (3mm ACP)\n"

        # Draw Nested Cuts
        (sheet[:cuts] || []).each do |c|
          cx = sheet_x + c[:x]
          cy = sheet_y + c[:y]
          cw = c[:w]
          ch = c[:h]

          # Cut Perimeter
          dxf += "0\nLWPOLYLINE\n8\nCUT_PERIMETER\n90\n4\n70\n1\n"
          dxf += "10\n#{cx}\n20\n#{cy}\n"
          dxf += "10\n#{cx + cw}\n20\n#{cy}\n"
          dxf += "10\n#{cx + cw}\n20\n#{cy + ch}\n"
          dxf += "10\n#{cx}\n20\n#{cy + ch}\n"

          # Cutouts / Notches
          (c[:cutouts] || []).each do |cut|
            nx, ny, nw, nh = 0, 0, 0, 0
            if c[:rotated]
              nx = cx + cut[:z_start_mm]
              ny = cy
              nw = cut[:z_end_mm] - cut[:z_start_mm]
              nh = cut[:depth_mm]
            else
              nx = cx
              ny = cy + cut[:z_start_mm]
              nw = cut[:depth_mm]
              nh = cut[:z_end_mm] - cut[:z_start_mm]
            end
            
            # Notch Perimeter
            dxf += "0\nLWPOLYLINE\n8\nCUT_NOTCH\n90\n4\n70\n1\n"
            dxf += "10\n#{nx}\n20\n#{ny}\n"
            dxf += "10\n#{nx + nw}\n20\n#{ny}\n"
            dxf += "10\n#{nx + nw}\n20\n#{ny + nh}\n"
            dxf += "10\n#{nx}\n20\n#{ny + nh}\n"
          end

          # Part Label
          dxf += "0\nTEXT\n8\nTEXT_LABELS\n10\n#{cx + 10}\n20\n#{cy + ch / 2}\n40\n12.0\n1\n#{c[:id]} #{c[:name]}\n"
        end

        cur_y += sheet_h + 100.0 # 100mm gap between sheets
      end

      dxf += "0\nENDSEC\n0\nEOF\n"
      dxf
    end

    # --- 3. Export Comprehensive BOM to Excel / CSV ---
    def self.export_excel_bom
      model = Sketchup.active_model
      unless model
        UI.messagebox("No active model found.")
        return
      end

      bom_data = CBXHybridEngine.generate_bom_and_nesting(model.entities) rescue nil
      specs = CabinexAI::HybridPlanner.last_specs || {}
      quote = specs['quote'] || {}
      markup = (quote['markup_pct'] || 35.0).to_f

      default_name = "Cabinex_BOM_Quotation_#{Time.now.strftime('%Y%m%d')}.csv"
      save_path = UI.savepanel("Export Bill of Materials to Excel/CSV", "", default_name)
      return unless save_path

      csv = []
      csv << "CABINEX AI — COMPREHENSIVE BILL OF MATERIALS & QUOTATION"
      csv << "Project Name,#{quote['project_name'] || 'Luxury Aluminum Modular Kitchen'}"
      csv << "Client Name,#{quote['client_name'] || 'Valued Customer'}"
      csv << "Date,#{Time.now.strftime('%d %B %Y')}"
      csv << "Generated By,Cabinex AI v2.0 Professional Studio"
      csv << ""
      csv << "Category,Item Code / Description,Profile / Material,Length (mm),Width (mm),Thickness (mm),Qty,Unit Rate (LKR),Total Amount (LKR)"

      # 1. Profiles (Box Bars)
      n = (bom_data && bom_data[:nesting]) || {}
      box_bars = (n[:boxbar_matte_black_6m_bars] && n[:boxbar_matte_black_6m_bars][:total_bars]) || 6
      sash_bars = (n[:sash_gloss_6m_bars] && n[:sash_gloss_6m_bars][:total_bars]) || 4
      acp_sheets = n[:acp_2440x1220_sheets_est] || 3

      csv << "Aluminum Profiles,25.4mm Matte Black Structural Box-Bar (6m Stock Bar),Alloy 6063-T6,6000,25.4,1.2,#{box_bars},7200,#{box_bars * 7200}"
      csv << "Aluminum Profiles,45mm Champagne Glass/Sash Door Profile (6m Stock Bar),Alloy 6063-T6,6000,45.0,19.0,#{sash_bars},9800,#{sash_bars * 9800}"
      csv << "Panel Cladding,3mm Matte Aluminum Composite Panel (2440x1220mm),PVDF ACP Sheet,2440,1220,3.0,#{acp_sheets},13500,#{acp_sheets * 13500}"
      csv << "Countertops,Solid Black Polished Granite Slab (3/4\"),Natural Granite,2488,620,20.0,1,38500,38500"
      csv << "Hardware & Fittings,Soft-Close 3D Clip-On Concealed Hinges,Nickel Plated Steel,-,-,-,16,950,15200"
      csv << "Hardware & Fittings,Tandembox Soft-Close Drawer Runner Systems,Steel Triple Extension,-,500,-,3,4200,12600"
      csv << "Hardware & Fittings,Recessed Aluminum Gola Finger-Pull Extrusion,Anodized Aluminum,2488,27.2,56.5,2,4800,9600"
      csv << "Fasteners & Connectors,Corner Internal Cleats / Self-Tapping Fasteners,SS 304,-,-,-,64,45,2880"
      csv << "Labor & Fabrication,Full CNC Cutting Miter Milling & Assembly Labor,Skilled Labor,-,-,-,1,58000,58000"

      total_materials = (box_bars * 7200) + (sash_bars * 9800) + (acp_sheets * 13500) + 38500 + 15200 + 12600 + 9600 + 2880 + 58000
      markup_val = (total_materials * (markup / 100.0)).round
      grand_total = total_materials + markup_val

      csv << ""
      csv << "SUMMARY & COMMERCIAL PRICING"
      csv << "Total Base Production Cost (Materials + Hardware + Labor),,,,,,,,LKR #{total_materials}"
      csv << "Contractor Profit Margin (#{markup}%),,,,,,,,LKR +#{markup_val}"
      csv << "FINAL CLIENT QUOTATION AMOUNT (LKR),,,,,,,,LKR #{grand_total}"

      File.write(save_path, csv.join("\n"))

      UI.messagebox("✅ Excel/CSV Bill of Materials exported successfully to:\n\n#{save_path}\n\nTotal Quotation: LKR #{grand_total.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}")
      UI.openURL("file:///#{save_path.tr('\\', '/')}") rescue nil
      Sketchup.set_status_text("BOM Export complete: #{File.basename(save_path)}")
    end
  end
end
