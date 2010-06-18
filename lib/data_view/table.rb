module DataView
  class Table
    # Initializes Table view (presenter?)
    # @param [Brewery::DataTable] Data table to be rendered
    def initialize(data_table)
      @data = data_table
    end
    
    # Renders Data Table as HTML
    # @return [String] Data Table in HTML form
    def as_html
      table = Html::Element.new(:table, "", :class => "data_table")
      header = table.new_child(:tr)
      
      @data.columns.each do |col|
        header.new_child(:th, col.label, :class => col.identifier)
      end
      
      @data.rows.each_index do |row|
        row_element = if (row % 2 == 1)
          table.new_child(:tr, "", :class => "odd")
        else
          table.new_child(:tr, "", :class => "even")
        end
        @data.rows[row].each_index do |col|
          cell_element = row_element.new_child(:td,
                         @data.formatted_value_at(row, col))
        end
      end
      
      table.to_s
    end
  end
end