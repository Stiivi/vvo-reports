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
    if report && report!="all" && !params[:object_id]
      return redirect_to report_path("all", :cut => params[:cut])
    end
    if report
      @report_type = report
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
  
  def cpv
    dimension = @cube.dimension_with_name(:cpv)
    path = [params[:object_id]]
    @detail = dimension.detail_for_path(path)
    
    initialize_slicer
    @slicer.update_from_param("cpv:#{params[:object_id]}")
    slice = @slicer.to_slice
    
    load_all_views(slice)
  end
  
  def postup
    dimension = @cube.dimension_with_name(:druh_postupu)
    path = [params[:object_id]]
    @detail = dimension.detail_for_path(path)
    
    initialize_slicer
    @slicer.update_from_param("druh_postupu:#{params[:object_id]}")
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

    # Default presenter options for all tables
    presenter_opts = if @report_type == "all"
      {:link => :report}
    else
      {:link => :cut}
    end
    
    # Dodavatelia
    @dodavatelia = top_10_dodavatelia(slice)
    @dodavatelia_table = DataView::Table.new(@dodavatelia)
    @dodavatelia_table.add_cell_presenter(
      {:col => [:firma], :row => :all},
      DataView::Presenter::Report.new({:report => :supplier, :dimension => :dodavatel, :level => 1}.merge(presenter_opts))
    )
    @dodavatelia_table.add_cell_presenter({:col => :first, :row => :last}, 
      DataView::Presenter::Report.new(:link => false))
    @dodavatelia_chart = DataView::PieChart.new(@dodavatelia, {:labels => 0, :series => 1})
      
    # Obstaravatelia
    @obstaravatelia = top_10_obstaravatelia(slice)
    @obstaravatelia_table = DataView::Table.new(@obstaravatelia)
    @obstaravatelia_table.add_cell_presenter({:col => [:org], :row => :all},
      DataView::Presenter::Report.new({:report => :procurer, :dimension => :obstaravatel, :level => 1, :link => :report}.merge(presenter_opts)))
    @obstaravatelia_chart = DataView::PieChart.new(@obstaravatelia, {:labels => 0, :series => 1})
      
    # Typy tovarov
    @typy_tovarov = typy_tovarov(slice)
    @typy_tovarov_table = DataView::Table.new(@typy_tovarov)
    @typy_tovarov_table.add_cell_presenter(
      {:col => [:cpv_division_desc], :row => :all},
      DataView::Presenter::Report.new({:dimension => :cpv, :report => :cpv}.merge(presenter_opts)))
    
    # Druhy postupov
    @druhy_postupov = druh_postupu(slice)
    @druhy_postupov_table = DataView::Table.new(@druhy_postupov)
    @druhy_postupov_table.add_cell_presenter(
      {:col => [:druh_postupu], :row => :all},
      DataView::Presenter::Report.new({:dimension => :druh_postupu, :report => :postup}.merge(presenter_opts)))
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