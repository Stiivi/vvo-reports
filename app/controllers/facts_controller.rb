class FactsController < ApplicationController
  before_filter :initialize_model

  def show
    @id = params[:id]
    
    @fact = @cube.fact(@id)

    @view_fields = [ 'vestnik_cislo', 
                     'zakazka_nazov',
                     'zmluva_hodnota',
                     'cpv.cpv_code',
                     'dodavatel.name',
                     'dodavatel.region',
                     'dodavatel.address',
                     'obstaravatel.name',
                     'obstaravatel.ico',
                     'obstaravatel.address',
                     'obstaravatel.account_sector',
                     'druh_postupu' ]
  end
end