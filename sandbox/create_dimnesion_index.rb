require 'rubygems'
require 'brewery'

class Tool
include Brewery

def initialize_brewery
    Brewery::load_default_configuration
    Brewery::create_default_workspace(:vvo_data)

    @workspace = Brewery::workspace
    puts "WS: #{@workspace} CONN: #{@workspace.connection}"

    @index_table = :idx_dimensions
end

def initialize_table
	@workspace.connection << "DROP TABLE IF EXISTS #{@index_table.to_s}"

	@workspace.connection.create_table(@index_table) do
		primary_key :id
		column :dimension, :varchar
		column :dimension_id, :integer
		column :level, :varchar
		column :level_id, :integer
		column :level_key, :varchar
		column :field, :varchar
		column :value, :text
	end
end

def index_dimension(dimension)
    puts "==> indexing dimension #{dimension.name}"
    levels = dimension.levels
    levels.each { |level|
        puts "-->   indexing level #{level.name} (#{level.id})"
        level.level_fields.each { |field|
            puts "---     field #{field}"
#            begin
                index_field(dimension, level, field)
#            rescue
#                puts "!!! unable to index field #{field}"
#            end
        }
    }
end

def index_field(dimension, level, field)

    query = @cube.create_star_query
    
    query.create_dimension_field_index(@index_table, dimension, level, field)
end

def run
    initialize_brewery
    initialize_table    
    
    @model_name = "verejne_obstaravania"
    model = Brewery::LogicalModel.model_with_name(@model_name)
    @cube = model.cube_with_name('zmluvy')
    
    if ! model
        raise "No model '#{@model_name}'"
        return
    end

    if ! @cube
        raise "No cube 'zmluvy'"
        return
    end
    
    puts "Indexing #{model.dimensions.count} dimensions"
    @cube.dimensions.each { |dim|
        index_dimension(dim)
    }
end
end # class

tool = Tool.new
tool.run
    # end # module Brewery