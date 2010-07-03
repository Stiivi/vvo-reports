# encoding: utf-8

require "brewery"

class ReportsController < ApplicationController
  
  include Brewery
  include Reports
  
  before_filter :initialize_model
  
  # The only two methods Rails need. Will find and display
  # report.

  def index
    redirect_to :action => "show", :id => "all"
  end

  def show
    # Report template name. 
    report = params[:id]
    if report
      self.send(report)
      return render :action => report
    else
      self.all
      return render :action => "all"
    end
  end
  
  # These are private now. We don't want Rails to think of these
  # as actions. They are not. These are methods to display reports
  # user asked for.
  
  protected
  
  def all
    initialize_slicer
    load_all_views(@slicer.to_slice)
  end
  
  def supplier
    dimension = @cube.dimension_with_name(:dodavatel)
    path = [:all, params[:object_id]]
    @detail = dimension.detail_for_path(path)
    
    initialize_slicer
    @slicer.update_from_param("dodavatel:*-#{params[:object_id]}")
    slice = @slicer.to_slice
    
    load_all_views(slice)
  end
  
  def procurer
    dimension = @cube.dimension_with_name(:obstaravatel)
    path = [:all, params[:object_id]]
    @detail = dimension.detail_for_path(path)
    
    initialize_slicer
    @slicer.update_from_param("obstaravatel:*-#{params[:object_id]}")
    slice = @slicer.to_slice
    
    load_all_views(slice)
  end
  
  # One very special methods. For now, it's shared across all report
  # methods. It will load all fundamental data and turn 'em into table
  # or graph views.
  
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
      DataView::Presenter::Report.new(:report => :supplier, :dimension => :dodavatel, :level => 1)
    )
    @dodavatelia_table.add_cell_presenter({:col => :first, :row => :last}, 
      DataView::Presenter::Report.new(:link => false))
    @dodavatelia_chart = DataView::PieChart.new(@dodavatelia, {:labels => 0, :series => 1})
      
    # Obstaravatelia
    @obstaravatelia = top_10_obstaravatelia(slice)
    @obstaravatelia_table = DataView::Table.new(@obstaravatelia)
    @obstaravatelia_table.add_cell_presenter({:col => [:org], :row => :all},
      DataView::Presenter::Report.new(:report => :procurer, :dimension => :obstaravatel, :level => 1))
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
  
  def initialize_slicer
    @slicer = Brewery::CubeSlicer.new(@cube)
    @slicer.update_from_param("date:2009")
    
    # Update from params
    if params[:cut]
      @slicer.update_from_param(params[:cut])
    end
  end
  
end