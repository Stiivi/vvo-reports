module DataView
  module Presenter
    
    # Presents link causing adding a new cut to existing slice.
    class SliceCut
      
      # Initializes new SliceCut
      # @param [Brewery::CubeSlicer] Slicer to be used to build URL.
      # @param [Symbol] Dimension that Presenter presents.
      # @param [Hash] Additional options.
      def initialize(slicer, dimension, options = {})
        @slicer = slicer
        @dimension = dimension
        @level = options[:level] || 0
        @base_url = options[:base_url] || ""
      end
      
      def present(html_cell, data_cell)
        a_element = html_cell.new_child(:a, data_cell.formatted_value)
        # [Hack - to be solved in some other way] Deep clones current slice.
        current_slicer = Marshal.load(Marshal.dump(@slicer))
        
        # Path
        if @level == 0
          path = data_cell.value
        else
          path = (["*"]*@level + [data_cell.value]).join("-")
        end
        
        current_slicer.
          update_from_param("#{@dimension}:#{path}")
        a_element[:href] = "#{@base_url}?cut=#{current_slicer.to_param}"
        current_slicer = nil
      end
    end
  end
end