module DataView
  module Presenter
    
    # Presents link causing adding a new cut to existing slice.
    class Report
      
      # Initializes new SliceCut
      # @param [Hash] Options
      def initialize(options = {})
        @slicer = Presenter.slicer
        @controller = Presenter.controller
        @dimension = options[:dimension]
        @level = options[:level] || 0
        @link = options.has_key?(:link) ? options[:link] : true
        @legend = options.has_key?(:legend) ? options[:legend] : true
        @report = options[:report]
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
        
        if @link
          a_element = left.new_child(:a, data_cell.formatted_value)
          # [Hack - to be solved in some other way] Deep clones current slice.
          current_slicer = Marshal.load(Marshal.dump(@slicer))
          
          params = {}
          
          if @dimension
            if @level == 0
              path = data_cell.value
            else
              path = (["*"]*@level + [data_cell.value]).join("-")
            end
            
            current_slicer.
              update_from_param("#{@dimension}:#{path}")
              
            params[:cut] = current_slicer.to_param
          end

          # We want to render particular report template, if chosen so.
          if @report
            report_params = {:id => data_cell.value}.merge(params)
            report_params.delete(:cut)
            url = @controller.create_report_path(report_params.merge(:report => @report))
          # Otherwise we want to render general report with no template.
          else
            url = @controller.reports_path(params)
          end
          
          a_element[:href] = url
        else
          left.new_child(:span, data_cell.formatted_value)
        end
        
        # Now we need to add special (+) button to add this cut to current
        # slice.
        base_url = @controller.request.env['PATH_INFO']
        button = right.new_child(:a, "")
        button.new_child(:img, "", :src => "/images/plus_blue.png")
        base_params = @controller.params
        params = base_params.merge({:cut => current_slicer.to_param})
        button[:href] = @controller.create_report_path(params)
      end
    end
  end
end