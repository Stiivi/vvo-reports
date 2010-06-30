class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'application'
  
  helper_method :create_report_path
  
  def create_report_path(opts)
    if opts[:report]
      report_path(opts)
    else
      reports_path
    end
    
  end
  
  protected
  
  def initialize_model
    Brewery::load_rails_configuration
    Brewery::create_default_workspace(:default)
    
    @model = Brewery::Model.model_with_name("verejne_obstaravania")
    @cube = @model.cube_with_name("zmluvy")
  end
  
end
