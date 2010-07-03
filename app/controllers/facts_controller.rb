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
    # druh_postupu: "Druh postupu"
  }

  def index
    @slicer = Brewery::CubeSlicer.new(@cube)
    @slicer.update_from_param("date:2009")
    if params[:cut]
      @slicer.update_from_param(params[:cut])
    end
    
    slice = @slicer.to_slice
    total = slice.aggregate(:zmluva_hodnota).summary[:record_count]
    
    @paginator = Paginator.new(:page => (params[:page]||1).to_i, :page_size => 20, :total => total)
    if params[:sort]
      sort_field = params[:sort]
      sort_direction = params[:dir]
    end
    @facts = slice.facts(:page => @paginator.page-1,
                         :page_size => @paginator.page_size, 
                         :order_by => sort_field, 
                         :order_direction => sort_direction)
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