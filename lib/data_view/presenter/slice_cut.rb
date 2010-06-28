module DataView
  module Presenter
    class SliceCut
      def initialize(slicer, dimension, level = 0)
        @slicer = slicer
        @dimension = dimension
        @level = level
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
        a_element[:href] = "?cut=#{current_slicer.to_param}"
        current_slicer = nil
      end
    end
  end
end