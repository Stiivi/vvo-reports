class FactsController < ApplicationController
  def show
    @id = params[:id]
    @test_hash = {
      :lorem => "ipsum",
      :dolor => "sit",
      :amet => "hm?"
    }
  end
end