# encoding: utf-8

require "brewery"

class ReportsController < ApplicationController
  
  include Brewery
  include Reports
  
  before_filter :initialize_model, :set_limit
  
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

    @slice = @slicer.to_slice

    # Report template name. 
    report = params[:id]
    if report
      # Redirect to "all" template
      if report!="all" && !report_in_slice?(report, @slicer)
        return redirect_to report_path("all", :cut => params[:cut])
      end
      @report_type = report
      self.send("report_#{report}")
      return render :action => @template || report
    else
      self.all
      return render :action => "all"
    end
  end
  
  def new
    @results = {}
    @param_report = {}
    prepare_date_picker
  end
  
  def create
    @results = {}
    @result_counts = {}
    @param_report = params[:report] || {}
    prepare_date_picker
    
    show_report = @param_report.delete(:show_report)
    unless show_report.blank?
      slicer = Brewery::CubeSlicer.new(@cube)
      @param_report.each do |dimension_name, value|
        param = "#{dimension_name}:#{value}"
        slicer.update_from_param(param)
      end
      return redirect_to report_path(:all, :cut => slicer.to_param)
    end
    
    params[:report].each do |dimension_name, query|
      if query.blank?
        @results[dimension_name.to_sym] = nil
        next
      end
      next if dimension_name == 'date'
      dimension = @cube.dimension_with_name(dimension_name)
      raise "No dimension with name #{dimension_name}" unless dimension
      search = SphinxSearch.new(query, dimension)
      search.limit = 10
      search.process
      @result_counts[dimension.name.to_sym] = search.total_found
      @results[dimension.name.to_sym] = search.results.collect do |result|
        level = dimension.levels.get(result[:level_id])
        level_order = find_level_order(dimension, level)
        param = ['*'] * level_order
        value = CGI::escape(result[:level_key].to_s)
        param.push(value)
        result[:path] = param.join('-')
        result
      end
    end
    
    render :action => "new"
  end
  
  # raise @data.to_yaml
  
  # These are private now. We don't want Rails to think of these
  # as actions. They are not. These are methods to display reports
  # user asked for.
  
  protected
  
  def prepare_date_picker
    date_dim = @cube.dimension_with_name(:date)
    slice = @cube.whole
    @years = [nil] + slice.dimension_values_at_path(:date, []).to_a.
      collect { |k| [k[:"date.year"].to_s]*2 }
    months_hash = slice.dimension_values_at_path(:date, [:all]).to_a
    @months = []
    months_hash.each do |m|
      @months[m[:"date.month"]] = m[:"date.month_name"]
    end
    @months = @months.collect.with_index do |month, i|
      [month, i==0?nil:i.to_s]
    end
  end
  
  def report_default
    @limit = 5
    current_month = Date.today.strftime("%Y-%m")
    # current_month = "2009-6"
    @slicer.update_from_param("date:#{current_month}")
    @slice = @slicer.to_slice
    
    load_all_views(@slice) do
      @dodavatelia = top_10_dodavatelia(@slice, :sum => true)
      @obstaravatelia = top_10_obstaravatelia(@slice, :sum => true)
    end
    
    @dodavatelia_table.add_cell_presenter({:col => :first, :row => [5]}, 
      @remainder_presenter)
      
    @obstaravatelia_table.add_cell_presenter({:col => :first, :row => [5]}, 
      @remainder_presenter)
    # raise @dodavatelia_table.data.rows.count.to_s
  end
  
  def report_all
    load_all_views(@slicer.to_slice)
  end
  
  def report_supplier
    @detail = @slicer.detail_for_dimension(:dodavatel)
    slice = @slicer.to_slice
    load_all_views(slice)
  end
  
  def report_procurer
    @detail = @slicer.detail_for_dimension(:obstaravatel)
    slice = @slicer.to_slice
    load_all_views(slice)
  end
  
  def report_cpv
    @detail = @slicer.detail_for_dimension(:cpv)
    slice = @slicer.to_slice
    load_all_views(slice)
  end
  
  def report_postup
    @detail = @slicer.detail_for_dimension(:druh_postupu)
    slice = @slicer.to_slice
    load_all_views(slice)
  end
  
  def report_geography
    load_all_views(@slicer.to_slice)
    @template = "all"
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
      record[:zmluva_hodnota_sum] / @hodnota_zmluv
    }
    
    DataView::Presenter.controller = self
    DataView::Presenter.slicer = @slicer

    # Default presenter options for all tables
    presenter_opts = if @report_type == "all"
      {:link => :report}
    else
      {:link => :cut}
    end
    
    yield if block_given?
    
    # This presenter will be shared across all tables.
    @remainder_presenter = DataView::Presenter::Report.new(:link => false)
    
    # Dodavatelia
    @dodavatelia ||= top_10_dodavatelia(slice)
    @dodavatelia_table = DataView::Table.new(@dodavatelia)
    @dodavatelia_table.add_cell_presenter(
      {:col => [:firma], :row => :all},
      DataView::Presenter::Report.new({:report => :supplier, :dimension => :dodavatel}.merge(presenter_opts))
    )
    @dodavatelia_table.add_cell_presenter({:col => :first, :row => :last}, 
      @remainder_presenter)
    @dodavatelia_chart = DataView::PieChart.new(@dodavatelia, {:labels => 0, :series => 1})
      
    # Obstaravatelia
    @obstaravatelia ||= top_10_obstaravatelia(slice)
    @obstaravatelia_table = DataView::Table.new(@obstaravatelia)
    @obstaravatelia_table.add_cell_presenter({:col => [:org], :row => :all},
      DataView::Presenter::Report.new({:report => :procurer, :dimension => :obstaravatel, :level => 1, :link => :report}.merge(presenter_opts)))
    @obstaravatelia_table.add_cell_presenter({:col => :first, :row => :last}, 
        @remainder_presenter)
    @obstaravatelia_chart = DataView::PieChart.new(@obstaravatelia, {:labels => 0, :series => 1})
      
    # Typy tovarov
    @typy_tovarov = typy_tovarov(slice)
    @typy_tovarov_table = DataView::Table.new(@typy_tovarov)
    @typy_tovarov_table.add_cell_presenter(
      {:col => [0], :row => :all},
      DataView::Presenter::Report.new({:dimension => :cpv, :report => :cpv}.merge(presenter_opts)))
    @typy_tovarov_table.add_cell_presenter({:col => :first, :row => :last}, 
        @remainder_presenter)
    
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
    # What dimension reports require
    # FIXME Put this somewhere else. Like maybe into YAML file or something.
    reports = {
      :supplier => [:dodavatel],
      :procurer => [:obstaravatel],
      :cpv => [:cpv],
      :postup => [:druh_postupu]
    }
    
    cuts = slicer.cuts.collect { |cut| cut[0].name }
    required_cuts = reports[report.to_sym] || []
    required_cuts.each do |cut|
      return false unless cuts.include?(cut.to_s)
    end
    
    return true
  end
  
  def set_limit
    @limit = 10
  end
  
end