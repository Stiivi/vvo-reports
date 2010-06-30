module DataView
  module Presenter
    
    # Presents link causing adding a new cut to existing slice.
    class SliceCut
      
      # Initializes new SliceCut
      # @param [Hash] Options
      def initialize(options = {})
        @slicer = Presenter.slicer
        @controller = Presenter.controller
        @dimension = options[:dimension]
        @level = options[:level] || 0
        @base_url = options[:base_url] || nil
        @link = options.has_key?(:link) ? options[:link] : true
        @link_method = options[:link_method]
        @legend = options.has_key?(:legend) ? options[:legend] : true
      end
      
      def present(html_cell, data_cell)
        if @legend
          color_el = html_cell.new_child(:span, "&nbsp;", :class => "color")
          color = ColorCenter.instance.color_for_string(data_cell.value)
          color_el[:style] = "background-color: ##{color}"
        end
        
        if @link
          # LINK element
          a_element = html_cell.new_child(:a, data_cell.formatted_value)
          # [Hack - to be solved in some other way] Deep clones current slice.
          current_slicer = Marshal.load(Marshal.dump(@slicer))

          # Path
          if @level == 0
            path = data_cell.value
          else
            path = (["*"]*@level + [data_cell.value]).join("-")
          end
          
          if @dimension
            current_slicer.
              update_from_param("#{@dimension}:#{path}")
          end
          
          if @base_url
            base_url = @base_url
          elsif @link_method
            base_url = @controller.send(@link_method, data_cell.value)
          end
          
          a_element[:href] = "#{base_url}?cut=#{current_slicer.to_param}"
        else
          html_cell.new_child(:span, data_cell.formatted_value)
        end
      end
    end
  end
end