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
        @color_palette = options[:color_palette]
      end
      
      def prepare(table_view)
        color_center = ColorCenter.instance
        color_center.reset(@color_palette||:default)
      end
      
      def present(html_cell, data_cell)
        wrap = html_cell.new_child(:div, "", :class => "clearfix")
        left = wrap.new_child(:div, "", :class => "fl")
        right = wrap.new_child(:div, "", :class => "fr")
        
        if @legend
          color_el = left.new_child(:span, "&nbsp;", :class => "color")
          color = ColorCenter.instance.color_for_string(data_cell.value)
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
        
        # Now we need to add special (+) button to add this cut to current
        # slice.
        # base_url = @controller.request.env['PATH_INFO']
        #         button = right.new_child(:a, "")
        #         button.new_child(:img, "", :src => "/images/plus_blue.png")
        #         report_template = @controller.params[:id] || "all"
        #         button[:href] = @controller.report_path(report_template, :cut => current_slicer.to_param, :object_id => @controller.params[:object_id])
      end
      
      def cut_path(value)
        if cut = @slicer.cut_for_dimension(@dimension)
          puts cut.inspect
          dimension = cut[0]
          path = cut[1].clone
          if dimension.levels.count <= path.count
            @link = false
          else
            path << value
          end
        else
          path = if @level == 0
            [value]
          else
            (["*"]*@level + [value])
          end
        end
        
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