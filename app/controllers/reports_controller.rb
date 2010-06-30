# encoding: utf-8

require "brewery"

class ReportsController < ApplicationController
  
  include Brewery
  include Reports
  
  before_filter :initialize_model

  def index
    slice = find_slice
    load_all_views(slice)
  end
  
  def show
    self.send(params[:report])
    render :action => params[:report]
  end
  
  def supplier
    dimension = @cube.dimension_with_name(:dodavatel)
    path = [:all, params[:id]]
    @detail = dimension.detail_for_path(path)
    
    slice = find_slice
    slice = slice.cut_by_point(:dodavatel, path)
    load_all_views(slice)
  end
  
  def procurer
    dimension = @cube.dimension_with_name(:obstaravatel)
    path = [:all, params[:id]]
    @detail = dimension.detail_for_path(path)
    
    slice = find_slice
    slice = slice.cut_by_point(:obstaravatel, path)
    load_all_views(slice)
  end
  
  def load_all_views(slice)
    # Aggregated values
    result = slice.aggregate(:zmluva_hodnota)
    @hodnota_zmluv = result.summary[:sum].to_f
    @pocet_zmluv = result.summary[:record_count]
    slice.add_computed_field(:podiel) { |record|
      record[:sum] / @hodnota_zmluv
    }
    
    DataView::Presenter.controller = self
    DataView::Presenter.slicer = @slicer
    
    # Dodavatelia
    @dodavatelia = top_10_dodavatelia(slice)
    @dodavatelia_table = DataView::Table.new(@dodavatelia)
    @dodavatelia_table.add_cell_presenter(
      {:col => [:firma], :row => :all},
      DataView::Presenter::Report.new(:report => :supplier)
    )
    @dodavatelia_table.add_cell_presenter({:col => :first, :row => :last}, 
      DataView::Presenter::Report.new(:link => false))
    @dodavatelia_chart = DataView::PieChart.new(@dodavatelia, {:labels => 0, :series => 1})
      
    # Obstaravatelia
    @obstaravatelia = top_10_obstaravatelia(slice)
    @obstaravatelia_table = DataView::Table.new(@obstaravatelia)
    @obstaravatelia_table.add_cell_presenter({:col => [:org], :row => :all},
      DataView::Presenter::Report.new(:report => :procurer))
    @obstaravatelia_chart = DataView::PieChart.new(@obstaravatelia, {:labels => 0, :series => 1})
      
    # Typy tovarov
    @typy_tovarov = typy_tovarov(slice)
    @typy_tovarov_table = DataView::Table.new(@typy_tovarov)
    @typy_tovarov_table.add_cell_presenter(
      {:col => [:cpv_division_desc], :row => :all},
      DataView::Presenter::Report.new(:dimension => :cpv))
    
    # Druhy postupov
    @druhy_postupov = druh_postupu(slice)
    @druhy_postupov_table = DataView::Table.new(@druhy_postupov)
    @druhy_postupov_table.add_cell_presenter(
      {:col => [:druh_postupu], :row => :all},
      DataView::Presenter::Report.new(:dimension => :druh_postupu))
    @druhy_postupov_chart = DataView::PieChart.new(@druhy_postupov, {:labels => 0, :series => 1})
      
    @posledny_rok = posledny_rok(slice)
  end
  
  def find_slice
    # Default slice
    @slicer = Brewery::CubeSlicer.new
    @slicer.update_from_param("date:2009")
    
    # Update from params
    if params[:cut]
      @slicer.update_from_param(params[:cut])
    end
    
    # Create slice
    @slicer.to_slice(@cube)
  end
  
end