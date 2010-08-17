require 'rubygems'
require 'brewery'

module Brewery

time = Time.now

Brewery::load_default_configuration
DataMapper.auto_migrate!

model = LogicalModel.model_from_path('model')

model.save

result = model.validate
if result.count > 0
    result.each { | msg |
        puts "#{msg[0]}: #{msg[1]}"
    }
end

puts "created dimensions: #{model.dimensions.count}"

puts "Elapsed time: #{Time.now - time}"

# dim.save

end