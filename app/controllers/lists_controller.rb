class ListsController < ApplicationController
  before_filter :initialize_model
  
  # params[:id] - field for the list to be show
  #               the one that should be used for aggregation
  def show
    type = params[:id]
    raise "Invalid type #{type}" unless \
      %w{supplier procurer cpv method}.include?(type)
    self.send(type)
    render :action => type
  end
  
  def supplier
    initialize_slicer
    slice = @slicer.to_slice
    add_shared_field(slice)
    @result = slice.aggregate(:zmluva_hodnota, {:row_dimension => :dodavatel, 
  		                        :row_levels => [:organisation],
  		                        :page_size => 50,
  		                        :page => 1 })
  end
  
  protected
  
  def add_shared_field(slice)
    result = slice.aggregate(:zmluva_hodnota)
    @total = result.summary[:record_count]
    hodnota_zmluv = result.summary[:sum].to_f
    slice.add_computed_field(:podiel) { |record|
      record[:sum] / hodnota_zmluv
    }
  end
  
  def initialize_slicer
    @slicer = Brewery::CubeSlicer.new(@cube)
    
    # Update from params
    if params[:cut]
      @slicer.update_from_param(params[:cut])
    end
  end
end