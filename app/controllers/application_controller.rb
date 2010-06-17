class ApplicationController < ActionController::Base
  protect_from_forgery
  layout 'application'
  
  protected
  
  def find_cube
    Brewery::load_rails_configuration
    @connection = Brewery::data_store_manager.create_connection(:default)


    @model = Brewery::Model.first(:name => "vvo")
    @cube = @model.cubes.first( :name => "vvo" )
    table = @connection[@cube.fact_table.to_sym]
    @cube.dataset = Brewery::Dataset.dataset_from_database_table(table)
  end
end
