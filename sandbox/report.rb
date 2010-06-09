# input: obdobie

require 'rubygems'
require 'brewery'

module Brewery

class Report

def run
    Brewery::load_default_configuration
    DataMapper::Logger.new($stdout, :debug)
    
    initialize_model
    
    time = Time.now
    top_level_report([2009])
    puts "Elapsed time: #{Time.now - time}"
end

def initialize_model
    store_manager = Brewery::data_store_manager
    @connection = store_manager.create_connection("default")

    @model = Model.first(:name => "vvo")
    @cube = @model.cubes.first( :name => "vvo" )

    # FIXME: make this nicer
    table = @connection[@cube.fact_table.to_sym]
    @cube.dataset = Dataset.dataset_from_database_table(table)
end

def top_level_report(report_date)

    ################################################################
    # Main slice

    slice = @cube.whole.cut_by_point(:date, report_date)

    rows = slice.aggregate(:zmluva_hodnota)
    result = rows[0]

    hodnota_zmluv = result[:sum].to_f
    pocet_zmluv = result[:record_count]

    puts "\n== Summary"
    puts "-- Hodnota zmluv: #{hodnota_zmluv}"
    puts "-- Pocet zmluv  : #{pocet_zmluv}"

    
    ################################################################
    # Top 10 orgs

    dim = @cube.dimension_with_name (:dodavatel)
    level = dim.level_with_name(:organisation)
    desc_field = level.description_field.to_sym
t = Time.now
    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => dim, 
    			                        :row_levels => [:organisation],
    			                        :limit => :rank,
    			                        :limit_value => 10,
    			                        :limit_sort => :top})

puts "ELAPSED: #{Time.now - t}"

    puts
    puts "== #{dim.label} '#{desc_field}'"

    result.each { |row|
        puts "-- #{row[desc_field]}: #{row[:sum].to_f} #{row[:record_count]}"
    }

    ################################################################
    # CPV
    dim = @cube.dimension_with_name (:cpv)
    level = dim.level_with_name(:division)
    desc_field = level.description_field.to_sym
    
    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => dim, 
    			                        :row_levels => [:division],
    			                        :limit => :rank,
    			                        :limit_value => 10,
    			                        :limit_sort => :top})

    puts
    puts "== #{dim.label} '#{desc_field}'"

    result.each { |row|
        puts "-- #{row[desc_field]}: #{row[:sum].to_f} #{row[:record_count]}"
    }


    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :druh_postupu, 
    			                        :row_levels => [:druh_postupu]})

    puts "\n"
    puts "== Druh postupu"

    result.each { |row|
        puts "-- #{row[:druh_postupu]}: #{row[:sum].to_f} #{row[:record_count]}"
    }

    
    puts "\n"
    puts "== Poslednych 12 mesiacov"

    current_date = Date.today
    to_date_id = current_date.strftime('%Y%m%d').to_i
    from_date_id = (current_date << 12).strftime('%Y%m%d').to_i
    
    year_slice = slice.dup
    year_slice.remove_cuts_by_dimension(:date)
    year_slice = year_slice.cut_by_range(:date, from_date_id, to_date_id)
    
    result = year_slice.aggregate(:zmluva_hodnota, {:row_dimension => :date, 
    			                        :row_levels => [:year, :month]})
    
    result.each { |row|
        puts "-- #{row[:year]} #{row[:month_sname]}: #{row[:sum].to_f} #{row[:record_count]}"
    }

    return

    slice = slice.slice(:cpv, ["48"])
    result = slice.aggregate(:zakazka_hodnota, [:sum])
    puts "SLICE SUM: #{result[:sum].to_f} #{result[:record_count]}"

    slice = @cube.slice(:date, [2009])
    # results = slice.drill_down_aggregate(:dodavatel, :region, :zakazka_hodnota, [:sum])
    results = top10_hodnota(slice, :dodavatel, :organisation)
    
    results.each { |result|
        puts "| #{result[:ico]} #{result[:name]} #{result[:sum].to_f} #{result[:record_count]} |"
    }

    results.each { |result|
        puts "| #{result[:ico]} #{result[:name]} #{result[:sum].to_f} #{result[:record_count]} |"
    }


    # puts date_dim.to_yaml

end

def top10_hodnota(slice, dimension, level)
    results = slice.drill_down_aggregate(dimension, level, :zakazka_hodnota, [:sum])

    sorted = results.sort { |a, b|
        b[:sum].to_f <=> a[:sum].to_f
    }
    
    return sorted.first(10)
end

# cpv_dim = Dimension.new(:cpv_code, [:cpv_division, :cpv_group, :cpv_class, :cpv_category, :cpv_detail])




# date = cube.dimension(:vestnik_datum)
# path = [2009]
# sum = 0.0
# count = 0
# for month in 1..12
#   slice = cube.slice(:vestnik_datum, [2009, month])
#   values = cube.aggregated_measuers(:zakazka_hodnota, [:sum, :count])
#   sum += values[:sum]
#   count += values[:count]
#   puts "MONTH #{month} SUM:#{values[:sum]} COUNT:#{values[:count]}"
# end
# 
# slice = cube.slice(:vestnik_datum, [2009])
# values = cube.aggregated_measuers(:zakazka_hodnota, [:sum, :count])
# 
# puts "TOTAL       : SUM: #{values[:sum]} COUNT:#{values[:count]}"
# puts "TOTAL SLICED: SUM: #{sum} COUNT: #{count}"
end #class
end # module

report = Brewery::Report.new
report.run
