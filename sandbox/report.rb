# input: obdobie

require 'rubygems'
require 'brewery'

module Brewery

class Report

def run
    Brewery::load_default_configuration
    # DataMapper::Logger.new($stdout, :debug)
    # DataMapper::Logger.new('log', :debug)
    DataObjects::Postgres.logger = DataObjects::Logger.new('sql.log', :debug) 
    
    initialize_model
    
    time = Time.now
    # top_level_report([2009])
    report_obstaravatel([2010], '30416094')

#    for i in 0..100
#        speed_test([2009])
#    end
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
    # Add computed slice
    
    slice.add_computed_field(:podiel) { |record|
        record[:sum] / hodnota_zmluv
    }

    ################################################################
    # Top 10 dodavatel

    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :dodavatel, 
    			                        :row_levels => [:organisation],
    			                        :limit => :rank,
    			                        :limit_value => 10,
    			                        :limit_sort => :top})

    puts
    puts "== Dodavatel"

    result.each { |row|
        puts "-- #{row[:name]}: #{row[:sum].to_f} #{row[:record_count]} #{row[:podiel]}"
    }

    ################################################################
    # Top 10 orgs - obstaravatel

    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :obstaravatel, 
    			                        :row_levels => [:organisation],
    			                        :limit => :rank,
    			                        :limit_value => 10,
    			                        :limit_sort => :top})

    puts
    puts "== Obstaravatel"

    result.each { |row|
        puts "-- #{row[:name]}: #{row[:sum].to_f} #{row[:record_count]} #{row[:podiel]}"
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
end

def report_obstaravatel(report_date, obstaravatel_ico)

    ################################################################
    # Main slice

    slice = @cube.whole.cut_by_point(:date, report_date)
    slice = slice.cut_by_point(:obstaravatel, [:all, obstaravatel_ico])
    
    rows = slice.aggregate(:zmluva_hodnota)
    result = rows[0]

    hodnota_zmluv = result[:sum].to_f
    pocet_zmluv = result[:record_count]

    puts "\n== Summary"
    puts "-- Hodnota zmluv: #{hodnota_zmluv}"
    puts "-- Pocet zmluv  : #{pocet_zmluv}"

    
    ################################################################
    # Add computed slice
    
    slice.add_computed_field(:podiel) { |record|
        record[:sum] / hodnota_zmluv
    }

    ################################################################
    # Top 10 dodavatel

    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :dodavatel, 
    			                        :row_levels => [:organisation],
    			                        :limit => :rank,
    			                        :limit_value => 10,
    			                        :limit_sort => :top})

    puts
    puts "== Dodavatel"

    result.each { |row|
        puts "-- #{row[:name]}: #{row[:sum].to_f} #{row[:record_count]} #{row[:podiel]}"
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
    to_date_id = Dimension::date_key(current_date)
    from_date_id = Dimension::date_key(current_date << 12)
    
    year_slice = slice.dup
    year_slice.remove_cuts_by_dimension(:date)
    year_slice = year_slice.cut_by_range(:date, from_date_id, to_date_id)
    
    result = year_slice.aggregate(:zmluva_hodnota, {:row_dimension => :date, 
    			                        :row_levels => [:year, :month]})
    
    result.each { |row|
        puts "-- #{row[:year]} #{row[:month_sname]}: #{row[:sum].to_f} #{row[:record_count]}"
    }

    return
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
