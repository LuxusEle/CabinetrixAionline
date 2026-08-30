# Quick inspector for Hinge+simplified.skp
require 'sketchup.rb'

model = Sketchup.active_model
skp_path = File.join(__dir__, 'Hinge+simplified.skp')
cdef = model.definitions.load(skp_path)

puts "=== HINGE DEFINITION INSPECTION ==="
puts "Name: #{cdef.name}"
puts "Bounds: min=#{cdef.bounds.min.to_a.map(&:to_mm)}, max=#{cdef.bounds.max.to_a.map(&:to_mm)}"
puts "Sub-entities count: #{cdef.entities.size}"
cdef.entities.each_with_index do |e, i|
  if e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
    puts "Sub #{i}: #{e.class} name='#{e.name}' bounds=#{e.bounds.min.to_a.map(&:to_mm)} -> #{e.bounds.max.to_a.map(&:to_mm)}"
  end
end
