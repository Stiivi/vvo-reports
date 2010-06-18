# encoding: utf-8

require "brewery"

class OrganisationsController < ApplicationController
  
  include Brewery
  include Reports
  
  before_filter :find_cube

  def show    
    slice = @cube.whole.cut_by_point(:date, [2009])
    # CUT BY organisation_id = params[:id]
    result = slice.aggregate(:zmluva_hodnota)[0]
    
    @hodnota_zmluv = result[:sum].to_f
    @pocet_zmluv = result[:record_count]

    slice.add_computed_field(:podiel) { |record|
      record[:sum] / @hodnota_zmluv
    }

    @top_10_dodavatelia = top_10_dodavatelia(slice)
    @top_10_obstaravatelia = top_10_obstaravatelia(slice)
    @typy_tovarov = typy_tovarov(slice)
    @druh_postupu = druh_postupu(slice)
    @posledny_rok = posledny_rok(slice)
  end
  
end