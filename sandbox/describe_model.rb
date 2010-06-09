require 'rubygems'
require 'brewery'

module Brewery

time = Time.now

Brewery::load_default_configuration

model = Model.first(:name => "vvo")

if ! model
    raise RuntimeError, "No model"
end

puts "model: #{model.name}"
puts "dimensions: #{model.dimensions.count}"
model.dimensions.each { |dim|
    puts "    - #{dim.name}"
}

puts "cubes: #{model.cubes.count}"
model.cubes.each { |cube|
    puts "    - #{cube.name}"
}


puts "ET: #{Time.now - time}"

# dim.save

end