# encoding: utf-8

require "brewery"

class ReportsController < ApplicationController
  
  include Brewery
  include Reports
  
  before_filter :initialize_model

  def index
    # Default slice
    slicer = Brewery::CubeSlicer.new
    slicer.update_from_param("date:2009")
    
    # Update from params
    if params[:cut]
      slicer.update_from_param(params[:cut])
    end
    
    # Create slice
    slice = slicer.to_slice(@cube)
    
    # Get aggregated values result
    result = slice.aggregate(:zmluva_hodnota)
    @hodnota_zmluv = result.summary[:sum].to_f
    @pocet_zmluv = result.summary[:record_count]
    slice.add_computed_field(:podiel) { |record|
      record[:sum] / @hodnota_zmluv
    }
    
    @dodavatelia = top_10_dodavatelia(slice)
    @dodavatelia_table = DataView::Table.new(@dodavatelia)
    @dodavatelia_table.add_cell_presenter(:firma,
      DataView::Presenter::SliceCut.new(slicer, :dodavatel, 1))
    @dodavatelia_chart = DataView::PieChart.new(@dodavatelia, {:labels => 0, :series => 1})
      
    @obstaravatelia = top_10_obstaravatelia(slice)
    @obstaravatelia_table = DataView::Table.new(@obstaravatelia)
    @obstaravatelia_table.add_cell_presenter(:org,
      DataView::Presenter::SliceCut.new(slicer, :obstaravatel, 1))
    @obstaravatelia_chart = DataView::PieChart.new(@obstaravatelia, {:labels => 0, :series => 1})
      
    @typy_tovarov = typy_tovarov(slice)
    @druh_postupu = druh_postupu(slice)
    @posledny_rok = posledny_rok(slice)
  end
  
end