# encoding: utf-8

require "brewery"

class ReportsController < ApplicationController
  
  include Brewery
  include Reports
  
  before_filter :initialize_model

  def index
    load_all_views
  end
  
  def show
    report_type = params[:id]
    load_all_views
    render :action => report_type
  end
  
  def load_all_views
    # Default slice
    @slicer = Brewery::CubeSlicer.new
    @slicer.update_from_param("date:2009")
    
    # Update from params
    if params[:cut]
      @slicer.update_from_param(params[:cut])
    end
    
    # Create slice
    slice = @slicer.to_slice(@cube)
    
    # Aggregated values
    result = slice.aggregate(:zmluva_hodnota)
    @hodnota_zmluv = result.summary[:sum].to_f
    @pocet_zmluv = result.summary[:record_count]
    slice.add_computed_field(:podiel) { |record|
      record[:sum] / @hodnota_zmluv
    }
    
    # Dodavatelia
    @dodavatelia = top_10_dodavatelia(slice)
    @dodavatelia_table = DataView::Table.new(@dodavatelia)
    @dodavatelia_table.add_cell_presenter(
      {:col => [:firma], :row => :all},
      DataView::Presenter::SliceCut.new(@slicer, :dodavatel, :level => 1, :base_url => report_path(:dodavatel))
    )
    @dodavatelia_table.remove_cell_presenter({:col => :all, :row => :last})
    @dodavatelia_chart = DataView::PieChart.new(@dodavatelia, {:labels => 0, :series => 1})
      
    # Obstaravatelia
    @obstaravatelia = top_10_obstaravatelia(slice)
    @obstaravatelia_table = DataView::Table.new(@obstaravatelia)
    @obstaravatelia_table.add_cell_presenter({:col => [:org], :row => :all},
      DataView::Presenter::SliceCut.new(@slicer, :obstaravatel, :level => 1, :base_url => report_path(:obstaravatel)))
    @obstaravatelia_chart = DataView::PieChart.new(@obstaravatelia, {:labels => 0, :series => 1})
      
    # Typy tovarov
    @typy_tovarov = typy_tovarov(slice)
    @typy_tovarov_table = DataView::Table.new(@typy_tovarov)
    @typy_tovarov_table.add_cell_presenter(
      {:col => [:cpv_division_desc], :row => :all},
      DataView::Presenter::SliceCut.new(@slicer, :cpv))
    
    # Druhy postupov
    @druhy_postupov = druh_postupu(slice)
    @druhy_postupov_table = DataView::Table.new(@druhy_postupov)
    @druhy_postupov_table.add_cell_presenter(
      {:col => [:druh_postupu], :row => :all},
      DataView::Presenter::SliceCut.new(@slicer, :druh_postupu))
    @druhy_postupov_chart = DataView::PieChart.new(@druhy_postupov, {:labels => 0, :series => 1})
      
    @posledny_rok = posledny_rok(slice)
  end
  
end