# =============================================================================
# Cabinex AI — Cabinet Comparison Grid (GEMINI MODULE)
# (c) 2026 Cabinex AI. All Rights Reserved.
#
# Production reference builders:
#   CabinetrixLJointDemo        -> demo_ljoint_connections.rb
#   CabinetrixMasterGola        -> gola_drawer_bank_master.rb
#   CabinetrixLuxuryKitchen     -> build_luxury_gola_kitchen_master.rb
#
# USAGE (SketchUp Ruby console):
#   load "C:/Users/asank/Documents/CabinetrixAionline/gemini/run_cabinet_grid.rb"
#   RunCabinetGrid.build
# =============================================================================

require 'sketchup.rb'

module RunCabinetGrid
  $CABINETRIX_DEMO_NO_AUTORUN = true
  $CABINETRIX_NO_AUTORUN = true

  REF = [
    File.join(__dir__, 'demo_ljoint_connections.rb'),
    File.join(__dir__, 'gola_drawer_bank_master.rb'),
    File.join(__dir__, 'build_luxury_gola_kitchen_master.rb')
  ].freeze

  def self.load_refs
    REF.each do |f|
      load f if File.exist?(f)
    end
    defined?(CabinetrixMasterGola) && defined?(CabinetrixLJointDemo)
  end

  def self.materials(model)
    return CabinetrixMasterGola.get_materials(model) if defined?(CabinetrixMasterGola)
    {}
  end

  def self.build
    model = Sketchup.active_model
    raise 'No active model.' unless model
    raise 'Production reference builders not found.' unless load_refs

    model.start_operation('CabinetGrid', true)
    ents = model.active_entities
    ents.grep(Sketchup::Group).select { |g| g.name.to_s.start_with?('CG_') || g.name.to_s.start_with?('Cabinetrix') }.each { |g| g.erase! }
    ents.grep(Sketchup::Text).each { |t| t.erase! }

    mats = materials(model)

    # ---- ZONE A: L-JOINT connection comparison (4 joints, spaced) ----
    build_l_joint_row(ents, 0.mm, mats)

    # ---- ZONE B: production Gola 2x drawer bank (canonical) ----
    a = CabinetrixMasterGola.build_complete_system(
      ents, Geom::Point3d.new(2000.mm, 0, 0), mats, mode: :hybrid
    )
    a.name = 'CG_GolaDrawerBank_Hybrid'

    b = CabinetrixMasterGola.build_complete_system(
      ents, Geom::Point3d.new(4000.mm, 0, 0), mats, mode: :carcase_only
    )
    b.name = 'CG_GolaDrawerBank_Joinery'

    model.commit_operation
    model.active_view.zoom_extents rescue nil
    puts '>> CabinetGrid built from GEMINI references:'
    puts '   1. L-Joint connections (minifix / dowel / screw / combined)'
    puts '   2. Gola drawer bank - hybrid (open/closed)'
    puts '   3. Gola drawer bank - joinery (100% minifix & stretchers)'
    puts '>> OK'
  end

  def self.build_l_joint_row(ents, x0, mats)
    spacing = 380.mm
    [:minifix, :dowel, :screw, :combined].each_with_index do |type, i|
      g = CabinetrixLJointDemo.build_l_joint(
        ents, Geom::Point3d.new(x0 + (i * spacing), 0, 0), type, mats
      )
      g.name = "CG_LJoint_#{type.to_s.upcase}"
    end
  end
end

RunCabinetGrid.build if defined?(Sketchup) && Sketchup.active_model
