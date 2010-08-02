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
    @data = @dimension.list_of_values(@path)
    # raise data.to_yaml
  end
  
  def search
    search = SphinxSearch.new(params[:query], @dimension)
    search.process
    @results = search.results
  end
end