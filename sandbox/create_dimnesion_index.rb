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
		column :dimension_key, :integer
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

    stmt = "INSERT INTO #{@index_table}
                            (dimension, dimension_id, dimension_key, level, level_id, level_key, field, value)
                SELECT '#{dimension.name}', #{dimension.id}, #{dimension.key_field}, '#{level.name}', #{level.id}, #{level.key_field}, '#{field}', #{field}
                FROM #{dimension.table}"
    
    @workspace.connection << stmt
end

def run
    initialize_brewery
    initialize_table    
    
    model = Model.model_with_name("verejne_obstaravania")
    
    if ! model
        raise RuntimeError, "No model"
    end
    
    puts "==> model: #{model.name}"
    puts "==> number of dimensions: #{model.dimensions.count}"
    model.dimensions.each { |dim|
        index_dimension(dim)
    }
end
end # class

tool = Tool.new
tool.run
    # end # module Brewery