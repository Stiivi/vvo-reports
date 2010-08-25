class ApplicationController < ActionController::Base
  DEFAULT_PAGE_SIZE = 30
  
  protect_from_forgery
  layout 'application'
  
  helper_method :create_report_path,
                :additional_params
  
  def create_report_path(opts)
    if opts[:report]
      opts.merge({:controller => "reports", :action => "show"})
      report_path(opts)
    else
      opts.merge({:controller => "reports", :action => "index"})
      url_for(opts)
    end
  end
  
  def additional_params
    additional = params.clone
    additional.delete(:controller)
    additional.delete(:action)
    additional
  end
  
  protected
  
  def initialize_model
    Brewery::load_rails_configuration
    Brewery::create_default_workspace(:vvo_data)
    
    @model = Brewery::LogicalModel.model_with_name("verejne_obstaravania")
    @cube = @model.cube_with_name("zmluvy")
  end
  
  # FIXME: Move to a class for generating paths generally
  def find_level_order(dimension, level)
     if !level
         # this should not happen
         return 0
     end
     order = 0
     dimension.default_hierarchy.levels.each do |dim_level|
       break if dim_level.id == level.id
       order += 1
     end
     return order
   end
  
end
