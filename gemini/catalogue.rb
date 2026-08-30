# ==============================================================================
# CABINETRIX AI — MASTER PARAMETRIC TEMPLATE CATALOGUE & STENCIL REPOSITORY
# File: gemini/catalogue.rb
#
# Role in System Architecture:
#   • THE STENCIL REPOSITORY & KNOWLEDGE BASE:
#     - Holds all parametric cabinet recipes, dimensional rules, panel formulas,
#       machining rules, and hardware schedules derived from manufacturer manuals
#       (Blum, Hettich, Kesseböhmer, SCILM, Häfele, European Standards).
#     - Pure data & formula orchestrator — does NOT perform direct 3D draw calls.
#     - Dynamic & Synergistic: Supports runtime registration of new user templates.
# ==============================================================================

module CabinetrixCatalogue
  @templates = {}

  def self.templates
    @templates
  end

  def self.register(id, data)
    @templates[id.to_s] = data
  end

  def self.get(id)
    @templates[id.to_s] || @templates[id.to_sym]
  end

  def self.list_all
    @templates.keys
  end

  def self.find_by_category(category)
    @templates.values.select { |t| t[:category] == category.to_sym }
  end

  # ----------------------------------------------------------------------------
  # 1. BASE CABINET STENCILS (720mm Carcase + 100mm Plinth = 820/860mm datum)
  # ----------------------------------------------------------------------------
  register("B_GOLA_2D", {
    id: "B_GOLA_2D",
    name: "Base 2-Pot Drawer Bank (Gola)",
    category: :base_drawer,
    zone: :prep_storage,
    desc: "Handleless SCILM Top L-Gola & Mid C-Gola with Hettich Actro 5D undermount runners",
    dimensions: {
      w: { default: 900.0, min: 450.0, max: 1200.0, step: 50.0 },
      h: { default: 720.0, fixed: true },
      d: { default: 560.0, min: 500.0, max: 650.0, step: 10.0 }
    },
    gola: { top_l: true, mid_c: true, c_gola_z0: 330.0, c_gola_h: 73.5, l_gola_h: 59.0 },
    panels: ->(w, h, d, opts = {}) {
      thk = 18.0
      inner_w = w - (2 * thk)
      [
        { name: "Gable_LH", len: h, wid: d, thk: thk, mat: :carcase, cnc: :gola_notched, eb_l1: "1.0mm ABS" },
        { name: "Gable_RH", len: h, wid: d, thk: thk, mat: :carcase, cnc: :gola_notched, eb_l1: "1.0mm ABS" },
        { name: "Bottom_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase, eb_l1: "1.0mm ABS" },
        { name: "Top_Front_Stretcher", len: inner_w, wid: 80.0, thk: thk, mat: :carcase, eb_l1: "0.4mm" },
        { name: "Top_Rear_Stretcher", len: inner_w, wid: 80.0, thk: thk, mat: :carcase, eb_l1: "0.4mm" },
        { name: "Mid_C_Gola_Stretcher", len: inner_w, wid: 60.0, thk: thk, mat: :carcase, eb_l1: "0.4mm" },
        { name: "Rear_Top_Cleat", len: inner_w, wid: 100.0, thk: thk, mat: :carcase },
        { name: "Rear_Bottom_Cleat", len: inner_w, wid: 100.0, thk: thk, mat: :carcase },
        { name: "Back_Sheet", len: inner_w + 10.0, wid: h - 26.0, thk: 6.0, mat: :backing },
        # Drawers
        { name: "Drawer_Box_LH_Lower", len: d - 110.0, wid: 200.0, thk: 15.0, mat: :drawer_core },
        { name: "Drawer_Box_RH_Lower", len: d - 110.0, wid: 200.0, thk: 15.0, mat: :drawer_core },
        { name: "Drawer_SubFront_Lower", len: inner_w - 55.0, wid: 200.0, thk: 15.0, mat: :drawer_core },
        { name: "Drawer_Back_Lower", len: inner_w - 55.0, wid: 200.0, thk: 15.0, mat: :drawer_core },
        { name: "Drawer_Bottom_Lower", len: inner_w - 55.0, wid: d - 140.0, thk: 16.0, mat: :drawer_core },
        { name: "Lower_Pot_Drawer_Front", len: w - 3.0, wid: 315.0, thk: 18.0, mat: :face, eb_all: "1.0mm ABS" },
        { name: "Drawer_Box_LH_Upper", len: d - 110.0, wid: 120.0, thk: 15.0, mat: :drawer_core },
        { name: "Drawer_Box_RH_Upper", len: d - 110.0, wid: 120.0, thk: 15.0, mat: :drawer_core },
        { name: "Drawer_SubFront_Upper", len: inner_w - 55.0, wid: 120.0, thk: 15.0, mat: :drawer_core },
        { name: "Drawer_Back_Upper", len: inner_w - 55.0, wid: 120.0, thk: 15.0, mat: :drawer_core },
        { name: "Drawer_Bottom_Upper", len: inner_w - 55.0, wid: d - 140.0, thk: 16.0, mat: :drawer_core },
        { name: "Upper_Drawer_Front", len: w - 3.0, wid: 248.0, thk: 18.0, mat: :face, eb_all: "1.0mm ABS" }
      ]
    },
    hardware: ->(w, h, d) {
      [
        { sku: "HET-ACTRO-450", name: "Hettich Actro 5D Undermount Slide 450mm 70kg", qty: 2, unit: "pairs" },
        { sku: "SCILM-GOLA-L", name: "SCILM Top L-Gola Profile", qty: (w / 1000.0).round(2), unit: "m" },
        { sku: "SCILM-GOLA-C", name: "SCILM Mid C-Gola Profile", qty: (w / 1000.0).round(2), unit: "m" }
      ]
    }
  })

  register("B_GOLA_SINK", {
    id: "B_GOLA_SINK",
    name: "Base Sink Unit with Cargo Waste 900mm",
    category: :base_sink,
    zone: :washing,
    desc: "Sink unit with U-shaped plumbing cutout sub-front drawer and lower recycling cargo bins",
    dimensions: {
      w: { default: 900.0, min: 600.0, max: 1200.0, step: 50.0 },
      h: { default: 720.0, fixed: true },
      d: { default: 560.0, min: 500.0, max: 650.0 }
    },
    gola: { top_l: true, mid_c: true, c_gola_z0: 330.0, c_gola_h: 73.5, l_gola_h: 59.0 },
    panels: ->(w, h, d, opts = {}) {
      thk = 18.0
      inner_w = w - (2 * thk)
      [
        { name: "Gable_LH", len: h, wid: d, thk: thk, mat: :carcase, cnc: :gola_notched },
        { name: "Gable_RH", len: h, wid: d, thk: thk, mat: :carcase, cnc: :gola_notched },
        { name: "Bottom_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Top_Front_Stretcher", len: inner_w, wid: 80.0, thk: thk, mat: :carcase },
        { name: "Top_Rear_Stretcher", len: inner_w, wid: 80.0, thk: thk, mat: :carcase },
        { name: "Mid_C_Gola_Stretcher", len: inner_w, wid: 60.0, thk: thk, mat: :carcase },
        { name: "Rear_Top_Cleat", len: inner_w, wid: 100.0, thk: thk, mat: :carcase },
        { name: "Rear_Bottom_Cleat", len: inner_w, wid: 100.0, thk: thk, mat: :carcase },
        { name: "Back_Sheet", len: inner_w + 10.0, wid: h - 26.0, thk: 6.0, mat: :backing },
        { name: "Sink_False_Front", len: w - 3.0, wid: 248.0, thk: 18.0, mat: :face },
        { name: "Lower_Pot_Drawer_Front", len: w - 3.0, wid: 315.0, thk: 18.0, mat: :face }
      ]
    },
    hardware: ->(w, h, d) {
      [
        { sku: "HET-ACTRO-450", name: "Hettich Actro 5D Undermount Slide 450mm 70kg", qty: 1, unit: "pair" },
        { sku: "SCILM-GOLA-L", name: "SCILM Top L-Gola Profile", qty: (w / 1000.0).round(2), unit: "m" },
        { sku: "SCILM-GOLA-C", name: "SCILM Mid C-Gola Profile", qty: (w / 1000.0).round(2), unit: "m" },
        { sku: "KES-CARGO-BIN", name: "Kesseböhmer Dual 35L Cargo Waste Recycling Bins", qty: 1, unit: "set" }
      ]
    }
  })

  register("B_GOLA_COOKTOP", {
    id: "B_GOLA_COOKTOP",
    name: "Base Induction Cooktop Unit 900mm",
    category: :base_cooking,
    zone: :cooking,
    desc: "20mm subtop heat airflow gap with low-profile heat shield upper drawer",
    dimensions: {
      w: { default: 900.0, min: 600.0, max: 1200.0, step: 50.0 },
      h: { default: 720.0, fixed: true },
      d: { default: 560.0, min: 500.0, max: 650.0 }
    },
    gola: { top_l: true, mid_c: true, c_gola_z0: 330.0, c_gola_h: 73.5, l_gola_h: 59.0 },
    panels: ->(w, h, d, opts = {}) {
      CabinetrixCatalogue.get("B_GOLA_2D")[:panels].call(w, h, d, opts)
    },
    hardware: ->(w, h, d) {
      CabinetrixCatalogue.get("B_GOLA_2D")[:hardware].call(w, h, d)
    }
  })

  register("B_GOLA_SPICE", {
    id: "B_GOLA_SPICE",
    name: "Base 2-Tier Spice & Bottle Pullout 300mm",
    category: :base_storage,
    zone: :cooking,
    desc: "Kesseböhmer Dispensa Junior chrome 2-tier wire baskets with soft-close base runner",
    dimensions: {
      w: { default: 300.0, min: 150.0, max: 400.0, step: 50.0 },
      h: { default: 720.0, fixed: true },
      d: { default: 560.0, min: 500.0, max: 650.0 }
    },
    panels: ->(w, h, d, opts = {}) {
      thk = 18.0
      inner_w = w - (2 * thk)
      [
        { name: "Gable_LH", len: h, wid: d, thk: thk, mat: :carcase, cnc: :standard_gable },
        { name: "Gable_RH", len: h, wid: d, thk: thk, mat: :carcase, cnc: :standard_gable },
        { name: "Bottom_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Top_Front_Stretcher", len: inner_w, wid: 80.0, thk: thk, mat: :carcase },
        { name: "Top_Rear_Stretcher", len: inner_w, wid: 80.0, thk: thk, mat: :carcase },
        { name: "Rear_Top_Cleat", len: inner_w, wid: 100.0, thk: thk, mat: :carcase },
        { name: "Rear_Bottom_Cleat", len: inner_w, wid: 100.0, thk: thk, mat: :carcase },
        { name: "Back_Sheet", len: inner_w + 10.0, wid: h - 26.0, thk: 6.0, mat: :backing },
        { name: "Spice_Pullout_Front", len: w - 3.0, wid: h - 38.0, thk: 18.0, mat: :face }
      ]
    },
    hardware: ->(w, h, d) {
      [
        { sku: "KES-DISPENSA-300", name: "Kesseböhmer Dispensa Junior 2-Tier Wire Frame", qty: 1, unit: "set" }
      ]
    }
  })

  # ----------------------------------------------------------------------------
  # 2. CORNER CABINET STENCILS
  # ----------------------------------------------------------------------------
  register("B_CNR_LEMANS", {
    id: "B_CNR_LEMANS",
    name: "Base Blind Corner LeMans II Unit 1050mm",
    category: :corner_base,
    zone: :corner_storage,
    desc: "Kesseböhmer LeMans II twin swivel peanut trays with 450mm clear door opening",
    dimensions: {
      w: { default: 1050.0, min: 900.0, max: 1200.0, step: 50.0 },
      h: { default: 720.0, fixed: true },
      d: { default: 560.0, min: 560.0, max: 650.0 }
    },
    panels: ->(w, h, d, opts = {}) {
      thk = 18.0
      inner_w = w - (2 * thk)
      blind_w = 600.0
      door_w = w - blind_w - 3.0
      [
        { name: "Gable_LH", len: h, wid: d, thk: thk, mat: :carcase },
        { name: "Gable_RH", len: h, wid: d, thk: thk, mat: :carcase },
        { name: "Bottom_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Top_Front_Stretcher", len: inner_w, wid: 80.0, thk: thk, mat: :carcase },
        { name: "Top_Rear_Stretcher", len: inner_w, wid: 80.0, thk: thk, mat: :carcase },
        { name: "Blind_Corner_Internal_Baffle", len: h, wid: d - 50.0, thk: thk, mat: :carcase },
        { name: "Blind_Corner_Front_Filler", len: blind_w - 3.0, wid: h, thk: thk, mat: :face },
        { name: "Accessible_Corner_Door", len: door_w, wid: h - 38.0, thk: thk, mat: :face },
        { name: "Back_Sheet", len: inner_w + 10.0, wid: h - 26.0, thk: 6.0, mat: :backing }
      ]
    },
    hardware: ->(w, h, d) {
      [
        { sku: "KES-LEMANS-II", name: "Kesseböhmer LeMans II Set Style 450 R", qty: 1, unit: "set" },
        { sku: "BLUM-CLIP-110", name: "Blum CLIP top BLUMOTION 110° Hinge", qty: 2, unit: "pcs" }
      ]
    }
  })

  register("B_CNR_MAGIC", {
    id: "B_CNR_MAGIC",
    name: "Base Magic Corner Pullout Unit 1050mm",
    category: :corner_base,
    zone: :corner_storage,
    desc: "Kesseböhmer Magic Corner articulated slide frame",
    dimensions: {
      w: { default: 1050.0, min: 900.0, max: 1200.0, step: 50.0 },
      h: { default: 720.0, fixed: true },
      d: { default: 560.0, min: 560.0, max: 650.0 }
    },
    panels: ->(w, h, d, opts = {}) {
      CabinetrixCatalogue.get("B_CNR_LEMANS")[:panels].call(w, h, d, opts)
    },
    hardware: ->(w, h, d) {
      [
        { sku: "KES-MAGIC-CNR", name: "Kesseböhmer Magic Corner Articulated Frame", qty: 1, unit: "set" }
      ]
    }
  })

  # ----------------------------------------------------------------------------
  # 3. TALL TOWER STENCILS (2160mm + 100mm Plinth)
  # ----------------------------------------------------------------------------
  register("T_SPACE_TOWER", {
    id: "T_SPACE_TOWER",
    name: "Tall Blum Space Tower Larder 600mm",
    category: :tall_tower,
    zone: :pantry,
    desc: "Blum Space Tower with 5 internal pullout drawers below 1200mm datum & 155° zero-protrusion hinges",
    dimensions: {
      w: { default: 600.0, min: 450.0, max: 900.0, step: 50.0 },
      h: { default: 2160.0, fixed: true },
      d: { default: 600.0, min: 550.0, max: 650.0 }
    },
    panels: ->(w, h, d, opts = {}) {
      thk = 18.0
      inner_w = w - (2 * thk)
      p_list = [
        { name: "Gable_LH", len: h, wid: d, thk: thk, mat: :carcase, cnc: :line_bore_32 },
        { name: "Gable_RH", len: h, wid: d, thk: thk, mat: :carcase, cnc: :line_bore_32 },
        { name: "Bottom_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Larder_Mid_Structural_Shelf", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Roof_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Rear_Top_Cleat", len: inner_w, wid: 100.0, thk: thk, mat: :carcase },
        { name: "Rear_Mid_Cleat", len: inner_w, wid: 100.0, thk: thk, mat: :carcase },
        { name: "Rear_Bottom_Cleat", len: inner_w, wid: 100.0, thk: thk, mat: :carcase },
        { name: "Back_Sheet", len: inner_w + 10.0, wid: h - 26.0, thk: 6.0, mat: :backing },
        { name: "Adjustable_Shelf_Upper_1", len: inner_w - 1.0, wid: d - 40.0, thk: thk, mat: :carcase },
        { name: "Adjustable_Shelf_Upper_2", len: inner_w - 1.0, wid: d - 40.0, thk: thk, mat: :carcase },
        { name: "Full_Height_Pantry_Door", len: w - 3.0, wid: h - 100.0, thk: thk, mat: :face }
      ]
      5.times do |i|
        p_list << { name: "Internal_Drawer_LH_#{i+1}", len: d - 110.0, wid: 140.0, thk: 15.0, mat: :drawer_core }
        p_list << { name: "Internal_Drawer_RH_#{i+1}", len: d - 110.0, wid: 140.0, thk: 15.0, mat: :drawer_core }
        p_list << { name: "Internal_SubFront_#{i+1}", len: inner_w - 30.0, wid: 140.0, thk: 15.0, mat: :drawer_core }
        p_list << { name: "Internal_Back_#{i+1}", len: inner_w - 30.0, wid: 140.0, thk: 15.0, mat: :drawer_core }
      end
      p_list
    },
    hardware: ->(w, h, d) {
      [
        { sku: "HET-ACTRO-450", name: "Hettich Actro 5D Undermount Slide 450mm", qty: 5, unit: "pairs" },
        { sku: "BLUM-CLIP-155", name: "Blum CLIP top BLUMOTION 155° Zero-Protrusion Hinge", qty: 4, unit: "pcs" }
      ]
    }
  })

  register("T_OVEN_TOWER", {
    id: "T_OVEN_TOWER",
    name: "Tall Built-in Double Oven Tower 600mm",
    category: :tall_tower,
    zone: :appliances,
    desc: "Built-in oven tower with structural datum shelf at Z=820mm and 50mm rear chimney ventilation",
    dimensions: {
      w: { default: 600.0, min: 600.0, max: 600.0, fixed: true },
      h: { default: 2160.0, fixed: true },
      d: { default: 600.0, min: 550.0, max: 650.0 }
    },
    panels: ->(w, h, d, opts = {}) {
      thk = 18.0
      inner_w = w - (2 * thk)
      [
        { name: "Gable_LH", len: h, wid: d, thk: thk, mat: :carcase, cnc: :standard_gable },
        { name: "Gable_RH", len: h, wid: d, thk: thk, mat: :carcase, cnc: :standard_gable },
        { name: "Bottom_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Structural_Base_Datum_Shelf", len: inner_w, wid: d - 50.0, thk: thk, mat: :carcase },
        { name: "Upper_Appliance_Shelf", len: inner_w, wid: d - 50.0, thk: thk, mat: :carcase },
        { name: "Roof_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Back_Sheet", len: inner_w + 10.0, wid: h - 26.0, thk: 6.0, mat: :backing },
        { name: "Upper_Cupboard_Door", len: w - 3.0, wid: 450.0, thk: thk, mat: :face },
        { name: "Lower_Pot_Drawer_Front", len: w - 3.0, wid: 355.0, thk: thk, mat: :face }
      ]
    },
    hardware: ->(w, h, d) {
      [
        { sku: "HET-ACTRO-450", name: "Hettich Actro 5D Slide 450mm", qty: 2, unit: "pairs" },
        { sku: "BLUM-CLIP-110", name: "Blum CLIP top 110° Hinge", qty: 2, unit: "pcs" }
      ]
    }
  })

  # ----------------------------------------------------------------------------
  # 4. WALL & BULKHEAD STENCILS
  # ----------------------------------------------------------------------------
  register("W_LIFT_HF", {
    id: "W_LIFT_HF",
    name: "Wall AVENTOS HF Bi-Fold Lift 900mm",
    category: :wall_lift,
    zone: :wall_storage,
    desc: "Blum AVENTOS HF bi-fold lift mechanism with 50mm internal setback shelf",
    dimensions: {
      w: { default: 900.0, min: 600.0, max: 1200.0, step: 50.0 },
      h: { default: 720.0, min: 600.0, max: 900.0 },
      d: { default: 350.0, min: 300.0, max: 400.0 }
    },
    panels: ->(w, h, d, opts = {}) {
      thk = 18.0
      inner_w = w - (2 * thk)
      [
        { name: "Gable_LH", len: h, wid: d, thk: thk, mat: :carcase },
        { name: "Gable_RH", len: h, wid: d, thk: thk, mat: :carcase },
        { name: "Top_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Bottom_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Lift_Setback_Shelf", len: inner_w - 1.0, wid: d - 50.0, thk: thk, mat: :carcase },
        { name: "Back_Sheet", len: inner_w + 10.0, wid: h - 26.0, thk: 6.0, mat: :backing },
        { name: "BiFold_Upper_Door", len: w - 3.0, wid: (h/2.0) - 2.0, thk: thk, mat: :face },
        { name: "BiFold_Lower_Door", len: w - 3.0, wid: (h/2.0) - 2.0, thk: thk, mat: :face }
      ]
    },
    hardware: ->(w, h, d) {
      [
        { sku: "BLUM-AVENTOS-HF", name: "Blum AVENTOS HF Bi-Fold Power Lift Set", qty: 1, unit: "set" }
      ]
    }
  })

  register("W_GLASS_SASH", {
    id: "W_GLASS_SASH",
    name: "Wall Senior Sash Glass Display 900mm",
    category: :wall_display,
    zone: :wall_storage,
    desc: "45° mitered anodized aluminum sash frame with 4mm smoked glass infill and tempered glass shelves",
    dimensions: {
      w: { default: 900.0, min: 450.0, max: 900.0, step: 50.0 },
      h: { default: 720.0, fixed: true },
      d: { default: 350.0, min: 300.0, max: 400.0 }
    },
    panels: ->(w, h, d, opts = {}) {
      thk = 18.0
      inner_w = w - (2 * thk)
      [
        { name: "Gable_LH", len: h, wid: d, thk: thk, mat: :carcase },
        { name: "Gable_RH", len: h, wid: d, thk: thk, mat: :carcase },
        { name: "Top_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Bottom_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Glass_Shelf_1", len: inner_w - 2.0, wid: d - 40.0, thk: 8.0, mat: :glass },
        { name: "Glass_Shelf_2", len: inner_w - 2.0, wid: d - 40.0, thk: 8.0, mat: :glass },
        { name: "Back_Sheet", len: inner_w + 10.0, wid: h - 26.0, thk: 6.0, mat: :backing }
      ]
    },
    hardware: ->(w, h, d) {
      [
        { sku: "ALU-SASH-45", name: "Senior Sash 45° Aluminum Glass Door", qty: 1, unit: "pc" },
        { sku: "LED-WARM-STRIP", name: "Integrated 3000K LED Channel Strip", qty: 1, unit: "m" }
      ]
    }
  })

  register("BLK_FLAP_HK", {
    id: "BLK_FLAP_HK",
    name: "Top Bulkhead Stay Lift Flap 900mm",
    category: :top_bulkhead,
    zone: :bulkhead,
    desc: "Blum AVENTOS HK-top stay lift with TIP-ON push-to-open latch for ceiling-height storage",
    dimensions: {
      w: { default: 900.0, min: 600.0, max: 1200.0, step: 50.0 },
      h: { default: 360.0, min: 300.0, max: 450.0 },
      d: { default: 350.0, min: 350.0, max: 600.0 }
    },
    panels: ->(w, h, d, opts = {}) {
      thk = 18.0
      inner_w = w - (2 * thk)
      [
        { name: "Gable_LH", len: h, wid: d, thk: thk, mat: :carcase },
        { name: "Gable_RH", len: h, wid: d, thk: thk, mat: :carcase },
        { name: "Top_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Bottom_Panel", len: inner_w, wid: d, thk: thk, mat: :carcase },
        { name: "Back_Sheet", len: inner_w + 10.0, wid: h - 26.0, thk: 6.0, mat: :backing },
        { name: "Bulkhead_Flap_Door", len: w - 3.0, wid: h - 3.0, thk: thk, mat: :face }
      ]
    },
    hardware: ->(w, h, d) {
      [
        { sku: "BLUM-AVENTOS-HK", name: "Blum AVENTOS HK-top Stay Lift TIP-ON", qty: 1, unit: "set" }
      ]
    }
  })

  # ----------------------------------------------------------------------------
  # 5. ISLAND STENCILS
  # ----------------------------------------------------------------------------
  register("ISL_GOLA_2D", {
    id: "ISL_GOLA_2D",
    name: "Island Double-Sided Gola Pot Bank 900mm",
    category: :island_prep,
    zone: :island,
    desc: "Freestanding island pot drawer bank with SCILM profile and solid birch organizers",
    dimensions: {
      w: { default: 900.0, min: 600.0, max: 1200.0, step: 50.0 },
      h: { default: 720.0, fixed: true },
      d: { default: 560.0, min: 560.0, max: 650.0 }
    },
    panels: ->(w, h, d, opts = {}) {
      CabinetrixCatalogue.get("B_GOLA_2D")[:panels].call(w, h, d, opts)
    },
    hardware: ->(w, h, d) {
      CabinetrixCatalogue.get("B_GOLA_2D")[:hardware].call(w, h, d)
    }
  })
end
