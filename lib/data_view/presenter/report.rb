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

        # Make path
        if cut = @slicer.cut_for_dimension(@dimension)
          dimension = cut[0]
          path = cut[1].clone
          if dimension.levels.count <= path.count
            @link = false
          else
            path << data_cell.value
          end
        else
          path = if @level == 0
            [data_cell.value]
          else
            (["*"]*@level + [data_cell.value])
          end
        end
        
        path = path.join("-")
        
        if @link
          a_element = left.new_child(:a, data_cell.formatted_value)
          # [Hack - to be solved in some other way] Deep clones current slice.
          current_slicer = Marshal.load(Marshal.dump(@slicer))
          
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
          a_element[:href] = url
          data_element = a_element
        else
          data_element = left.new_child(:span, data_cell.formatted_value)
        end
        
        stripped_data_element = data_element.clone
        data_element[:class] = "full"
        stripped_data_element[:class] = "stripped"
        truncate_text_in(stripped_data_element)
        
        # Now we need to add special (+) button to add this cut to current
        # slice.
        # base_url = @controller.request.env['PATH_INFO']
        #         button = right.new_child(:a, "")
        #         button.new_child(:img, "", :src => "/images/plus_blue.png")
        #         report_template = @controller.params[:id] || "all"
        #         button[:href] = @controller.report_path(report_template, :cut => current_slicer.to_param, :object_id => @controller.params[:object_id])
      end
      
      def truncate_text_in(element)
        element.text ||= ""
        if element.text.length > TRUNCATED_LENGTH
          element.text = element.text[0, TRUNCATED_LENGTH] + " &hellip;"
        end
      end
    end
  end
end