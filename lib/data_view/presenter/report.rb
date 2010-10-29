module DataView
  module Presenter
    
    TRUNCATED_LENGTH = 29
    
    # Presents link causing adding a new cut to existing slice.
    class Report
      
      # Initializes new SliceCut
      # @param [Hash] Options
      def initialize(options = {})
        @slicer = Presenter.slicer
        @cube = @slicer.cube
        @controller = Presenter.controller
        @dimension = options[:dimension]
        @level = options[:level] || 0
        @link = options[:link]
        @legend = options.has_key?(:legend) ? options[:legend] : true
        @report = options[:report]
        @color_list = ColorList.new(options[:color_list] || 'default')
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
        
        if @link
          a_element = left.new_child(:a, truncate_string(data_cell.formatted_value))
          cut_path = cut_path(data_cell.value)
          url = path(cut_path)
          a_element[:href] = url
          data_element = a_element
        else
          data_element = left.new_child(:span, truncate_string(data_cell.formatted_value))
        end
      end
      
      def cut_path(value)
        if cut = @slicer.cut_for_dimension(@dimension)
          dimension = cut[0]
          path = cut[1].clone
          if dimension.levels.count <= path.count
            @link = false
          else
            path << value
          end
        else
          path = @level == 0 ? [value] : (["*"]*@level + [value])
        end
        # FIXME: this is temporary hack
        path = path.collect { | elem | elem == :all ? '*' : elem }
        path = path.join("-")
        path
      end
      
      def path(path)
        # path = cut_path(value)
        
        current_slicer = @slicer.clone
        
        # Add it to our slicer
        current_slicer.
          update_from_param("#{@dimension}:#{path}")
        
        # Make some params out of this
        params = @controller.params
        params[:cut] = current_slicer.to_param
        
        # Add report name to params
        if @link == :report && @report
          params[:id] = @report
        else
          params[:id] = params[:id] || "all"
        end
        
        url = @controller.url_for(params)
      end
      
      def truncate_string(string)
        if string.length > TRUNCATED_LENGTH
          return string[0, TRUNCATED_LENGTH] + " &hellip;"
        else
          string
        end
      end
    end
  end
end