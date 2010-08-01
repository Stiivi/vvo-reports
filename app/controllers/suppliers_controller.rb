# encoding: utf-8

require "brewery"

class SuppliersController < ReportsController
  
  include Brewery
  include Reports
  
  before_filter :initialize_model
  
  def show
    dimension = @cube.dimension_with_name(:dodavatel)
    path = [params[:id]]
    @detail = dimension.detail_for_path(path)
    
    slice = find_slice
    slice = slice.cut_by_point(:dodavatel, path)
    load_all_views(slice)
  end
  
end