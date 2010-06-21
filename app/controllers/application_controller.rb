class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'application'
  
  protected
  
  def initialize_model
    Brewery::load_rails_configuration
    Brewery::crate_default_workspace(:default)
    
    @model = Brewery::Model.model_with_name("verejne_obstaravania")
    @cube = @model.cube_with_name("zmluvy")
  end
end
