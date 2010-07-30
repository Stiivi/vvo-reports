class CutsController < ApplicationController
  before_filter :initialize_model
  ##
  # Updates cut from request
  def update
    @slicer = Brewery::CubeSlicer.new(@cube)
    @slicer.update_from_param("date:2009")
    if params[:current_cut]
      @slicer.update_from_param(params[:current_cut])
    end
    
    dimensions = [:date]
    
    dimensions.each do |dim|
      next unless params[dim]
      path = []
      params[dim].each do |key, value|
        value = "*" if value.blank?
        path[key.to_i] = value
      end
      path = path.join("-")
      param = "#{dim}:#{path}"
      @slicer.update_from_param(param)
    end
    
    new_cut = @slicer.to_param
    current_path = params[:current_path]
    redirect_to "#{current_path}?cut=#{new_cut}"
  end
end