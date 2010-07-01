# encoding: utf-8

class FactsController < ApplicationController
  before_filter :initialize_model
  before_filter do
    @fields = VIEW_FIELDS
  end

  VIEW_FIELDS = {
    vestnik_cislo: "Vestník",
    zakazka_nazov: "Názov zákazky",
    zmluva_hodnota: "Hodnota zmluvy",
    :"cpv.cpv_code" => "Kategória",
    :"dodavatel.name" => "Dodávateľ",
    :"obstaravatel.name" => "Obstarávateľ",
    druh_postupu: "Druh postupu"
  }

  def index
    @slicer = Brewery::CubeSlicer.new(@cube)
    @slicer.update_from_param("date:2009")
    if params[:cut]
      @slicer.update_from_param(params[:cut])
    end
    
    slice = @slicer.to_slice
    @facts = slice.facts
  end

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