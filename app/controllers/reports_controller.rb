# encoding: utf-8

require "brewery"
require 'brewery/presenters/data_table_presenter'


class ReportsController < ApplicationController
  
  include Brewery
  
  def index
    Brewery::load_rails_configuration
    @connection = Brewery::data_store_manager.create_connection(:default)


    @model = Brewery::Model.first(:name => "vvo")
    @cube = @model.cubes.first( :name => "vvo" )

    # FIXME: make this nicer
    table = @connection[@cube.fact_table.to_sym]
    @cube.dataset = Brewery::Dataset.dataset_from_database_table(table)


    # TOP 10 @report

    @report = Hash.new


    # Main slice

    slice = @cube.whole.cut_by_point(:date, [2009])

    rows = slice.aggregate(:zmluva_hodnota)
    result = rows[0]

    hodnota_zmluv = result[:sum].to_f
    pocet_zmluv = result[:record_count]

    @report[:hodnota_zmluv] = hodnota_zmluv
    @report[:pocet_zmluv] = pocet_zmluv

    slice.add_computed_field(:podiel) { |record|
      record[:sum] / hodnota_zmluv
    }

    ################################################################
    # Top 10 dodavatel

    table = top_10_dodavatelia(slice)

    presenter = DataTablePresenter.new
    presenter.format_column(0) { | cell |
    "<a href='dodavatel/#{cell.value}'>#{cell.formatted_value}</a>"
    }
    @report[:top_dodavatelia] = table

    presenter = DataTablePresenter.new
    presenter.format_column(0) { | cell |
    "<a href='obstaravatel/#{cell.value}'>#{cell.formatted_value}</a>"
    }

    @report[:presenter] = presenter
    @table = presenter.present_as_html(@report[:top_dodavatelia])

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
      return table
  end
end