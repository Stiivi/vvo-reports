module DataView
  module Presenter
    class Remainder < Report
      def initialize(options = {})
        super
        @list = options[:list]
      end
      
      def present(html_cell, data_cell, index)
        wrap = html_cell.new_child(:div, "", :class => "clearfix")
        left = wrap.new_child(:div, "", :class => "fl")
        right = wrap.new_child(:div, "", :class => "fr")
        
        if @legend
          color_el = left.new_child(:span, "&nbsp;", :class => "color")
          color = @color_list.color_with_name_or_index(data_cell.value, index)
          color_el[:style] = "background-color: ##{color}"
        end

        left[:title] = data_cell.formatted_value

        a_element = left.new_child(:a, truncate_string(data_cell.formatted_value))
        
        current_cut = @slicer.to_param
        url = @controller.list_path(@list, :cut => current_cut)

        a_element[:href] = url
        data_element = a_element
      end
    end
  end
end