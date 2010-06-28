module DataView
  class Table
    attr_reader :cell_presenters
    
    # Initializes Table view (presenter?)
    # @param [Brewery::DataTable] Data table to be rendered
    def initialize(data_table)
      @columns = {}
      @data = data_table
      @cell_presenters = {}
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
        html_class = (row % 2 == 1) ? "odd" : "even"
        row_element = table.new_child(:tr, "", :class => html_class)
        @data.rows[row].each_index do |col|
          cell_element = row_element.new_child(:td,
                         @data.formatted_value_at(row, col))
          cell_identifier = @data.columns[col].identifier.to_sym
          if self.cell_presenters[cell_identifier]
            self.cell_presenters[cell_identifier].present(cell_element, @data.rows[row][col])
          end
        end
      end
      
      table.to_s
    end
    
    def link(column)
      @columns[:firma] ||= {}
      @columns[:firma][:link] = true
      self
    end
    
    def add_cell_presenter(cell_name, presenter)
      @cell_presenters[cell_name.to_sym] = presenter
    end
  end
end