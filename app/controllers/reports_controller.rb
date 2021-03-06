# encoding: utf-8

require "brewery"

class ReportsController < ApplicationController
  
  include Brewery
  include Reports
  include Search
  
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
    prepare_search
    respond_to do |wants|
      wants.html
      wants.js
    end
  end
  
  def create
    slicer = Brewery::CubeSlicer.new(@cube)
    if params[:current_cut]
      slicer.update_from_param(params[:current_cut])
    end
    params[:report].each do |dimension_name, value|
      next if dimension_name =~ /_name$/
      param = "#{dimension_name}:#{value}"
      slicer.update_from_param(param)
    end
    respond_to do |wants|
      if params[:current_path].present?
        path = params[:current_path] + "?cut=" + slicer.to_param
      else
        path = report_path(:all, :cut => slicer.to_param)
      end
      wants.html { return redirect_to path }
      wants.js { return render :text => "window.location = '#{path}'" }
    end
  end
  
  def search
    @results = {}
    # <REFACTOR_ME>
    if params[:dimension] && params[:query]
      params[:report] ||= {}
      params[:report]["#{params[:dimension]}_name"] = params[:query]
    end
    # </REFACTOR_ME>
    params[:report].each do |dimension_name, query|
      next if query.blank?
      next if dimension_name == 'date'
      dimension_name = dimension_name.to_s.sub('_name', '')
      dimension = @cube.dimension_with_name(dimension_name)
      raise "No dimension with name #{dimension_name}" unless dimension
      query = query.split(' ').collect { |word|
        word + "*"
      }.join(' ')
      search = SphinxSearch.new_with_dimension(query, dimension)
      search.limit = 10
      search.process
      @results[dimension.name.to_sym] = search.results.collect do |result|
        sanitized_path = CGI::escape(result[:path].to_s)
        result[:path] = sanitized_path
        result
      end
    end
    
    respond_to do |format|
      format.json { render :json => @results.to_json }
    end
  end
  
  # raise @data.to_yaml
  
  # These are private now. We don't want Rails to think of these
  # as actions. They are not. These are methods to display reports
  # user asked for.
  
  protected
  
  def report_default
    prepare_search
    @limit = 5
    current_month = Date.today.strftime("%Y-%m")
    # current_month = "2009-6"
    @slicer.update_from_param("date:#{current_month}")
    @slice = @slicer.to_slice

    load_all_views(@slice) do
      @dodavatelia = top_10_dodavatelia(@slice, :sum => true)
      @obstaravatelia = top_10_obstaravatelia(@slice, :sum => true)
    end
    
    @total_presenter = DataView::Presenter::Report.new(:link => false)
    
    @dodavatelia_table.add_cell_presenter({:col => :first, :row => [5, 6]}, 
      DataView::Presenter::Remainder.new(:list => 'supplier'))
    @dodavatelia_table.add_cell_presenter({:col => :first, :row => :last}, @total_presenter)
    
      
    @obstaravatelia_table.add_cell_presenter({:col => :first, :row => [5, 6]}, 
      DataView::Presenter::Remainder.new(:list => 'procurer'))
    @obstaravatelia_table.add_cell_presenter({:col => :first, :row => :last}, @total_presenter)
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
      record[:zmluva_hodnota_sum] / @hodnota_zmluv unless @hodnota_zmluv == 0
    }
    
    DataView::Presenter.controller = self
    DataView::Presenter.slicer = @slicer

    # Default presenter options for all tables
    if @report_type == "all" || @report_type == "default"
      presenter_opts = {:link => :report}
    else
      presenter_opts = {:link => :cut}
    end
    
    yield if block_given?
    
    # Dodavatelia
    @dodavatelia ||= top_10_dodavatelia(slice)
    @dodavatelia_table = DataView::Table.new(@dodavatelia)
    @dodavatelia_table.add_cell_presenter(
      {:col => [:firma], :row => :all},
      DataView::Presenter::Report.new({:report => :supplier, :dimension => :dodavatel}.merge(presenter_opts))
    )
    if @dodavatelia.rows.last && @dodavatelia.rows.last.first.value.to_s == "ostatne"
      @dodavatelia_table.add_cell_presenter({:col => :first, :row => :last}, 
        DataView::Presenter::Remainder.new(:list => 'procurer'))
    end
    
    @dodavatelia_table.add_cell_presenter({:col => [:suma], :row => :all}, 
                                          DataView::Presenter::HumanNumber.new)
    @dodavatelia_chart = DataView::PieChart.new(@dodavatelia, {:labels => 0, :series => 1, :dimension => "dodavatel"})
      
    # Obstaravatelia
    @obstaravatelia ||= top_10_obstaravatelia(slice)
    @obstaravatelia_table = DataView::Table.new(@obstaravatelia)
    @obstaravatelia_table.add_cell_presenter({:col => [:org], :row => :all},
      DataView::Presenter::Report.new({:report => :procurer, :dimension => :obstaravatel, :level => 1, :link => :report}.merge(presenter_opts)))
    @obstaravatelia_table.add_cell_presenter({:col => [:suma], :row => :all}, 
                                             DataView::Presenter::HumanNumber.new)
    if @obstaravatelia.rows.last && @obstaravatelia.rows.last.first.value == "ostatne"
      @obstaravatelia_table.add_cell_presenter({:col => :first, :row => :last}, 
        DataView::Presenter::Remainder.new(:list => 'supplier'))
    end
    @obstaravatelia_chart = DataView::PieChart.new(@obstaravatelia, {:labels => 0, :series => 1, :dimension => "obstaravatel"})
      
    # Typy tovarov
    @typy_tovarov = typy_tovarov(slice)
    @typy_tovarov_table = DataView::Table.new(@typy_tovarov)
    @typy_tovarov_table.add_cell_presenter(
      {:col => [0], :row => :all},
      DataView::Presenter::Report.new({:dimension => :cpv, :report => :cpv}.merge(presenter_opts)))
    @typy_tovarov_table.add_cell_presenter({:col => [:suma], :row => :all}, 
                                           DataView::Presenter::HumanNumber.new)
    if @typy_tovarov.rows.last && @typy_tovarov.rows.last.first.value == "ostatne"
      @typy_tovarov_table.add_cell_presenter({:col => :first, :row => :last}, 
        DataView::Presenter::Remainder.new(:list => 'cpv'))
    end
    
    # Druhy postupov
    @druhy_postupov = druh_postupu(slice)
    @druhy_postupov_table = DataView::Table.new(@druhy_postupov)
    @druhy_postupov_table.add_cell_presenter(
      {:col => [:druh_postupu], :row => :all},
      DataView::Presenter::Report.new({
        :dimension => :druh_postupu, 
        :report => :postup, 
        :color_list => 'druh_postupu'
      }.merge(presenter_opts))
    )
    @druhy_postupov_table.add_cell_presenter({:col => [:suma], :row => :all}, 
                                             DataView::Presenter::HumanNumber.new)
    if @druhy_postupov.rows.last && @druhy_postupov.rows.last.first.value == "ostatne"
      @druhy_postupov_table.add_cell_presenter({:col => :first, :row => :last}, 
        DataView::Presenter::Remainder.new(:list => 'postup'))
    end
    @druhy_postupov_chart = DataView::PieChart.new(
      @druhy_postupov,
      {:labels => 0, :series => 1, :color_list => 'druh_postupu', :dimension => "druh_postupu"}
    )
      
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