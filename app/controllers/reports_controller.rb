# encoding: utf-8

require "brewery"
require 'brewery/presenters/data_table_presenter'


class ReportsController < ApplicationController
  
  include Brewery
  
  before_filter :find_cube

  def index
    slice = @cube.whole.cut_by_point(:date, [2009])
    result = slice.aggregate(:zmluva_hodnota)[0]
    
    @hodnota_zmluv = result[:sum].to_f
    @pocet_zmluv = result[:record_count]

    slice.add_computed_field(:podiel) { |record|
      record[:sum] / @hodnota_zmluv
    }

    @top_10_dodavatelia = top_10_dodavatelia(slice)
    @top_10_obstaravatelia = top_10_obstaravatelia(slice)
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

      result.each { |row|
          table.add_row([[row[:ico], row[:name]], row[:sum], row[:podiel]])
      }
      
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
    
    result.each { |row|
        table.add_row([[row[:ico], row[:name]], row[:sum], row[:podiel]])
    }
    return table
  end
end