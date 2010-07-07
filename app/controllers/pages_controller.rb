class PagesController < ApplicationController
  def show
    @page = Page.with_name(params[:id])
  end
end