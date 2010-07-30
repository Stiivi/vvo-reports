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
    # Slicer with cuts from param
    @slicer = Brewery::CubeSlicer.new(@cube)
    # @slicer.update_from_param("date:2009")
    
    # Update from params
    if params[:cut]
      @slicer.update_from_param(params[:cut])
    end    
    
    # Report template name. 
    report = params[:id]
    if report
      # Redirect to "all" template
      if report!="all" && !report_in_slice?(report, @slicer)
        return redirect_to report_path("all", :cut => params[:cut])
      end
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
    load_all_views(@slicer.to_slice)
  end
  
  def supplier
    @detail = @slicer.detail_for_dimension(:dodavatel)
    slice = @slicer.to_slice
    load_all_views(slice)
  end
  
  def procurer
    @detail = @slicer.detail_for_dimension(:obstaravatel)
    slice = @slicer.to_slice
    load_all_views(slice)
  end
  
  def cpv
    @detail = @slicer.detail_for_dimension(:cpv)
    slice = @slicer.to_slice
    load_all_views(slice)
  end
  
  def postup
    @detail = @slicer.detail_for_dimension(:druh_postupu)
    slice = @slicer.to_slice
    load_all_views(slice)
  end
  
  protected
  
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
    
    # This presenter will be shared across all tables.
    remainder_presenter = DataView::Presenter::Report.new(:link => false)
    
    # Dodavatelia
    @dodavatelia = top_10_dodavatelia(slice)
    @dodavatelia_table = DataView::Table.new(@dodavatelia)
    @dodavatelia_table.add_cell_presenter(
      {:col => [:firma], :row => :all},
      DataView::Presenter::Report.new({:report => :supplier, :dimension => :dodavatel, :level => 1}.merge(presenter_opts))
    )
    @dodavatelia_table.add_cell_presenter({:col => :first, :row => :last}, 
      remainder_presenter)
    @dodavatelia_chart = DataView::PieChart.new(@dodavatelia, {:labels => 0, :series => 1})
      
    # Obstaravatelia
    @obstaravatelia = top_10_obstaravatelia(slice)
    @obstaravatelia_table = DataView::Table.new(@obstaravatelia)
    @obstaravatelia_table.add_cell_presenter({:col => [:org], :row => :all},
      DataView::Presenter::Report.new({:report => :procurer, :dimension => :obstaravatel, :level => 1, :link => :report}.merge(presenter_opts)))
    @obstaravatelia_table.add_cell_presenter({:col => :first, :row => :last}, 
        remainder_presenter)
    @obstaravatelia_chart = DataView::PieChart.new(@obstaravatelia, {:labels => 0, :series => 1})
      
    # Typy tovarov
    @typy_tovarov = typy_tovarov(slice)
    @typy_tovarov_table = DataView::Table.new(@typy_tovarov)
    @typy_tovarov_table.add_cell_presenter(
      {:col => [0], :row => :all},
      DataView::Presenter::Report.new({:dimension => :cpv, :report => :cpv}.merge(presenter_opts)))
    @typy_tovarov_table.add_cell_presenter({:col => :first, :row => :last}, 
        remainder_presenter)
    
    # Druhy postupov
    @druhy_postupov = druh_postupu(slice)
    @druhy_postupov_table = DataView::Table.new(@druhy_postupov)
    @druhy_postupov_table.add_cell_presenter(
      {:col => [:druh_postupu], :row => :all},
      DataView::Presenter::Report.new({
        :dimension => :druh_postupu, 
        :report => :postup, 
        :color_palette => :druh_postupu
      }.merge(presenter_opts))
    )
    @druhy_postupov_chart = DataView::PieChart.new(@druhy_postupov, {:labels => 0, :series => 1})
      
    @posledny_rok = posledny_rok(slice)
  end
  
  def report_in_slice?(report, slicer)
    # report: supplier
    # slicer: #<Brewery::CubeSlicer:0x00000103b326b8 @cube=#<Brewery::Cube @id=1 @name="zmluvy" @label="UzatvorenÃ© zmluvy verejnÃ©ho obstarÃ¡vania" @description=<not loaded> @fact_table="ft_vvo_zmluvy">, @cuts=[[#<Brewery::Dimension @id=2 @name="date" @label="DÃ¡tum" @description=<not loaded> @key_field="id" @table="dm_date" @default_hierarchy_name=nil>, ["2009"]], [#<Brewery::Dimension @id=3 @name="dodavatel" @label="DodÃ¡vateÄ¾" @description=<not loaded> @key_field="id" @table="dm_supplier" @default_hierarchy_name=nil>, [:all, "36862631"]]]>
    # slicer.cuts: [[#<Brewery::Dimension @id=2 @name="date" @label="DÃ¡tum" @description=<not loaded> @key_field="id" @table="dm_date" @default_hierarchy_name=nil>, ["2009"]], [#<Brewery::Dimension @id=3 @name="dodavatel" @label="DodÃ¡vateÄ¾" @description=<not loaded> @key_field="id" @table="dm_supplier" @default_hierarchy_name=nil>, [:all, "36862631"]]]
    
    # What dimension reports require
    # FIXME Put this somewhere else. Like maybe into YAML file or something.
    reports = {
      :supplier => [:dodavatel],
      :procurer => [:obstaravatel],
      :cpv => [:cpv],
      :postup => [:druh_postupu]
    }
    
    cuts = slicer.cuts.collect { |cut| cut[0].name }
    required_cuts = reports[report.to_sym]
    required_cuts.each do |cut|
      return false unless cuts.include?(cut.to_s)
    end
    
    return true
  end
  
  
end