class ApplicationController < ActionController::Base
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
    Brewery::create_default_workspace(:default)
    
    @model = Brewery::Model.model_with_name("verejne_obstaravania")
    @cube = @model.cube_with_name("zmluvy")
  end
  
  
  
end
