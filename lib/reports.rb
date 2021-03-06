# encoding: utf-8

module Reports
  include Brewery
  
  def top_10_dodavatelia(slice, options = {})
      result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :dodavatel, 
      			                        :row_levels => [:organisation],
      			                        :limit => :rank,
      			                        :limit_value => @limit,
      			                        :limit_sort => :top})

      table = DataTable.new
      table.add_column(:text, "Firma", :firma)
      table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€', :alignment => :right})
      table.add_column(:percent, "Podiel", :podiel, { :precision => 2 , :alignment => :right} )

      result.rows.each { |row|
          table.add_row([[row[:"dodavatel.ico"], row[:"dodavatel.name"]], row[:zmluva_hodnota_sum], row[:podiel]])
      }
      remainder_row = result.remainder
      if remainder_row[:record_count] > 0 && remainder_row[:sum] > 0
        table.add_row([["ostatne", "Ostatné"], remainder_row[:sum], remainder_row[:podiel]]) if remainder_row[:record_count] > 0
      end
      
      if options[:sum]
        table.add_row([["spolu", "Spolu"], result.summary[:sum], 1])
      end
      
      table
  end
  
  def top_10_obstaravatelia(slice, options = {})
    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :obstaravatel, 
    			                        :row_levels => [:organisation],
    			                        :limit => :rank,
    			                        :limit_value => @limit,
    			                        :limit_sort => :top})

    table = DataTable.new
    table.add_column(:text, "Obstarávateľ", :org)
    table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€', :alignment => :right})
    table.add_column(:percent, "Podiel", :podiel, { :precision => 2 , :alignment => :right} )
    result.rows.each { |row|
        table.add_row([[row[:"obstaravatel.ico"], row[:"obstaravatel.name"]], row[:zmluva_hodnota_sum], row[:podiel]])
    }
    remainder_row = result.remainder

    if remainder_row[:record_count] > 0 && remainder_row[:sum] > 0
      table.add_row([["ostatne", "Ostatné"], remainder_row[:sum], remainder_row[:podiel]]) if remainder_row[:record_count] > 0
    end
    
    if options[:sum]
      table.add_row([["spolu", "Spolu"], result.summary[:sum], 1])
    end
    
    return table
  end
  
  def typy_tovarov(slice)
    dimension = @cube.dimension_with_name(:cpv)
    level = level_for_dimension(slice, dimension)

    levels_to_select = []
    dimension.levels.each do |l|
      levels_to_select << l
      if l == level
        break
      end
    end
    levels_to_select.collect! { |l| l.name }
    description_field = level.description_field.to_sym
    key_field = level.key_field.to_sym

    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => dimension.name, 
    			                        :row_levels => levels_to_select,
    			                        :limit => :rank,
    			                        :limit_value => 5,
    			                        :limit_sort => :top})

    table = DataTable.new
    table.add_column(:text, "Typ tovaru", description_field)
    table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€'})
    table.add_column(:percent, "Podiel", :podiel, { :precision => 2} )
    
    result.rows.each { |row|
      table.add_row([[row[key_field], row[description_field]], row[:zmluva_hodnota_sum], row[:podiel]])
    }
    
    remainder_row = result.remainder

    if remainder_row[:record_count] > 0 && remainder_row[:sum] > 0
      table.add_row([["ostatne", "Ostatné"], remainder_row[:sum], remainder_row[:podiel]]) if remainder_row[:record_count] > 0
    end
    
    return table
  end
  
  def druh_postupu(slice)
    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :druh_postupu, 
    			                        :row_levels => [:druh_postupu],
    			                        :limit => :rank,
    			                        :limit_value => 10,
    			                        :limit_sort => :top})

    table = DataTable.new
    table.add_column(:text, "Druh postupu", :druh_postupu)
    table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€'})
    table.add_column(:percent, "Podiel", :podiel, { :precision => 2} )
    
    result.rows.each { |row|
        table.add_row([[row[:"druh_postupu.druh_postupu_code"], row[:"druh_postupu.druh_postupu_desc"]], row[:zmluva_hodnota_sum], row[:podiel]])
    }
    return table
  end
  
  def posledny_rok(slice)
    year_slice = slice.dup
        
    if date_cut_level(year_slice) == :none
      year_slice = cut_slice_for_last_year(year_slice)
    elsif date_cut_level(year_slice) == :month
      year_slice = cut_slice_by_extending(year_slice)
    end
    
    result = year_slice.aggregate(:zmluva_hodnota, {:row_dimension => :date, 
    			                        :row_levels => [:year, :month]})

    table = DataTable.new
    table.add_column(:text, "Dátum", :date)
    table.add_column(:currency, "Suma", :sum, {:precision => 0, :currency => '€'})

    result.rows.each { |row|
        table.add_row([["#{row[:"date.year"]}-#{row[:"date.month"]}", "#{row[:"date.month_name"]} #{row[:"date.year"]}"], row[:zmluva_hodnota_sum]])
    }

    table
  end
  
  def level_for_dimension(slice, dimension)
    # FIXME: use hierarchy
    # FIXME: rename method to something more appropriate/descriptive
    cut = slice.cuts.find_all{|c|c.dimension == dimension}.first
    if cut
      level = dimension.next_level(cut.path)
    else
      level = dimension.levels.first
    end

    level ||= dimension.levels.last
    
    level    
  end
  
  protected
  
  def cut_slice_for_last_year(slice)
    current_date = Date.today
    to_date_id = Dimension::date_key(current_date)
    from_date_id = Dimension::date_key(current_date << 12)
    
    slice.remove_cuts_by_dimension(:date)
    slice = slice.cut_by_range(:date, from_date_id, to_date_id)
    
    slice
  end
  
  def cut_slice_by_extending(slice)
    date_cuts = slice.cuts_for_dimension(:date)

    return slice unless date_cuts.length == 1
    
    date_path   = date_cuts.first.path
    date_string = "%d-%02d-%02d" % [date_path[0], date_path[1]||1, date_path[2]||1]
    date        = Date.parse(date_string)
    
  
    from_date_id  = Dimension::date_key(date - 3.months)
    to_date_id    = Dimension::date_key(date + 3.months)
    
    slice.remove_cuts_by_dimension(:date)
    slice = slice.cut_by_range(:date, from_date_id, to_date_id)

    slice
  end
  
  def date_cut_level(slice)
    date_cuts = slice.cuts_for_dimension(:date)
    date_cut = date_cuts.first # Won't work if there are more than 1 cuts on date dim.
    if date_cuts.empty?
      :none
    elsif date_cut.path.length == 1
      :year
    elsif date_cut.path.length == 2
      :month
    elsif date_cut.path.length == 3
      :day
    end
  end
end