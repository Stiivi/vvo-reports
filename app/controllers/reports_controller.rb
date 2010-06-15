require "brewery"

class ReportsController < ApplicationController
  
  def index
    Brewery::load_rails_configuration
    @connection = Brewery::data_store_manager.create_connection(:default)

    @model = Brewery::Model.first(:name => "vvo")
    raise @model.cubes.to_yaml
    @cube = @model.cubes.first( :name => "vvo" )

    # FIXME: make this nicer
    table = @connection[@cube.fact_table.to_sym]
    @cube.dataset = Dataset.dataset_from_database_table(table)


    # TOP 10 report

    report = Hash.new


    # Main slice

    slice = @cube.whole.cut_by_point(:date, report_date)

    rows = slice.aggregate(:zmluva_hodnota)
    result = rows[0]

    hodnota_zmluv = result[:sum].to_f
    pocet_zmluv = result[:record_count]

    report[:hodnota_zmluv] = hodnota_zmluv
    report[:pocet_zmluv] = pocet_zmluv

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
    report[:top_dodavatelia] = table

    table = top_10_obstaravatelia(slice)
    report[:top_obstaravatelia] = table

    presenter = DataTablePresenter.new
    presenter.format_column(0) { | cell |
    "<a href='obstaravatel/#{cell.value}'>#{cell.formatted_value}</a>"
    }

    report[:presenter] = presenter

  end
end