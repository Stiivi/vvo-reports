# This is a dimension data lister. It will show stuff to user.
# it can drilldown through dimensions, and it can take user to
# the report.

class DimensionsController < ApplicationController
  before_filter do
    @report_map = {
      :cpv => :cpv,
      :dodavatel => :supplier,
      :obstaravatel => :procurer
    }
  end
  before_filter :initialize_model
  
  before_filter do
    @dimension_name = params[:id].to_sym
    @dimension = @cube.dimension_with_name(@dimension_name)
  end
  
  ##
  # Shows particular dimension listing
  def show
    if params[:path]
      @path = params[:path].split('-')
    else
      @path = []
    end

    @level_number = @path.count
    @level = @dimension.default_hierarchy.levels[0..@level_number].last
    @levels = @dimension.levels
    @description_field = @level.short_description_field
    
    # Prepare paginator & sort
    # FIXME: two requests? make only one
    query = @cube.whole.dimension_values_at_path(@dimension, @path)
    total = query.count
    @paginator = Paginator.new(:page => (params[:page]||1).to_i, :page_size => DEFAULT_PAGE_SIZE, :total => total)
    
    options = {:order_by => @description_field,
               :page_size => @paginator.page_size,
               :page => @paginator.page - 1}
    
    @data = @cube.whole.dimension_values_at_path(@dimension, @path, options)

    @slicer = Brewery::CubeSlicer.new(@cube)
    @slicer.update_from_param("#{@dimension.name}:#{@path.join('-')}")
  end
  
  def search
    @query = params[:query]
    search = SphinxSearch.new(params[:query], @dimension)
    # Order
    params[:order] ||= "relevance"
    search.order = params[:order]
    search.process
    @results = search.results

    slicer = Brewery::CubeSlicer.new(@cube)

    @results.each do |result|
      level = @dimension.levels.get(result[:level_id])
      level_order = find_level_order(@dimension, level)

      param = ['*'] * level_order
      value = CGI::escape(result[:level_key].to_s)
      param.push(value)
      param_string = param.join('-')
      param = "#{@dimension.name}:#{param_string}"

      slicer.update_from_param(param)

      result[:link] = report_path(@report_map[@dimension.name.to_sym], :cut => slicer.to_param)
      result[:level_obj] = level
    end
  end
end