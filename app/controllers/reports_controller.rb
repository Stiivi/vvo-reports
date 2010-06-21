# encoding: utf-8

require "brewery"
require 'brewery/presenters/data_table_presenter'


class ReportsController < ApplicationController
  
  include Brewery
  
  before_filter :initialize_model

  def index
    slice = @cube.whole.cut_by_point(:date, [2009])
    result = slice.aggregate(:zmluva_hodnota)
    
    @hodnota_zmluv = result.summary[:sum].to_f
    @pocet_zmluv = result.summary[:record_count]

    slice.add_computed_field(:podiel) { |record|
      record[:sum] / @hodnota_zmluv
    }

    @top_10_dodavatelia = top_10_dodavatelia(slice)
    @top_10_obstaravatelia = top_10_obstaravatelia(slice)
    @typy_tovarov = typy_tovarov(slice)
    @druh_postupu = druh_postupu(slice)
    @posledny_rok = posledny_rok(slice)
  end
  
  def top_10_dodavatelia(slice)
      result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :dodavatel, 
      			                        :row_levels => [:organisation],
      			                        :limit => :rank,
      			                        :limit_value => 10,
      			                        :limit_sort => :top})

      table = DataTable.new
      table.add_column(:text, "Firma", :firma)
      table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€', :alignment => :right})
      table.add_column(:percent, "Podiel", :podiel, { :precision => 2 , :alignment => :right} )

      result.rows.each { |row|
          table.add_row([[row[:ico], row[:name]], row[:sum], row[:podiel]])
      }
      row = result.remainder
      table.add_row(["Ostatne", row[:sum], row[:podiel]])
      
      table
  end
  
  def top_10_obstaravatelia(slice)
    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :obstaravatel, 
    			                        :row_levels => [:organisation],
    			                        :limit => :rank,
    			                        :limit_value => 10,
    			                        :limit_sort => :top})

    table = DataTable.new
    table.add_column(:text, "Obstarávateľ", :org)
    table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€', :alignment => :right})
    table.add_column(:percent, "Podiel", :podiel, { :precision => 2 , :alignment => :right} )
    
    result.rows.each { |row|
        table.add_row([[row[:ico], row[:name]], row[:sum], row[:podiel]])
    }
      row = result.remainder
      table.add_row(["Ostatne", row[:sum], row[:podiel]])
    return table
  end
  
  def typy_tovarov(slice)
    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :cpv, 
    			                        :row_levels => [:division],
    			                        :limit => :rank,
    			                        :limit_value => 5,
    			                        :limit_sort => :top})

    table = DataTable.new
    table.add_column(:text, "Typ tovaru", :cpv_division_desc)
    table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€'})
    table.add_column(:percent, "Podiel", :podiel, { :precision => 2} )
    
    result.rows.each { |row|
        table.add_row([[row[:cpv_division], row[:cpv_division_desc]], row[:sum], row[:podiel]])
    }
      row = result.remainder
      table.add_row(["Ostatne", row[:sum], row[:podiel]])
    return table
  end
  
  def druh_postupu(slice)
    result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :druh_postupu, 
    			                        :row_levels => [:druh_postupu],
    			                        :limit => :rank,
    			                        :limit_value => 10,
    			                        :limit_sort => :top})

    table = DataTable.new
    table.add_column(:text, "Typ tovaru", :druh_postupu)
    table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€'})
    table.add_column(:percent, "Podiel", :podiel, { :precision => 2} )
    
    result.rows.each { |row|
        table.add_row([[row[:druh_postupu], row[:druh_postupu]], row[:sum], row[:podiel]])
    }
    return table
  end
  
  def posledny_rok(slice)
    current_date = Date.today
    to_date_id = Dimension::date_key(current_date)
    from_date_id = Dimension::date_key(current_date << 12)
    
    year_slice = slice.dup
    year_slice.remove_cuts_by_dimension(:date)
    year_slice = year_slice.cut_by_range(:date, from_date_id, to_date_id)
    
    result = year_slice.aggregate(:zmluva_hodnota, {:row_dimension => :date, 
    			                        :row_levels => [:year, :month]})

    result.rows.collect do |item|
      ["#{item[:month_name]} #{item[:year]}", item[:sum]]
    end
  end
end