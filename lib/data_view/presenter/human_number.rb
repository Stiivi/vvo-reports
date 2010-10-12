# encoding: utf-8

class DataView::Presenter::HumanNumber
  include ActionView::Helpers::NumberHelper
  
  def present(html_cell, data_cell, index)
    if data_cell.value.zero?
      html_cell.text = '€ 0'
    else
      html_cell.text = "€ " + number_to_human(data_cell.value)
    end
  end
end