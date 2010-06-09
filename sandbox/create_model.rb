require 'rubygems'
require 'brewery'

module Brewery

time = Time.now

Brewery::load_default_configuration
DataMapper.auto_migrate!

model = Model.model_from_path('model')

model.save
puts "created dimensions: #{model.dimensions.count}"

puts "Elapsed time: #{Time.now - time}"

# dim.save

end