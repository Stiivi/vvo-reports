module DataView
  class Table
    ALL = :all
    NONE = :none
    
    attr_reader :cell_presenters, :data
    
    # Initializes Table view (presenter?)
    # @param [Brewery::DataTable] Data table to be rendered
    def initialize(data_table)
      @columns = {}
      @data = data_table
      @cell_presenters = []
      @data.columns.count.times do |c|
        @cell_presenters[c] = []
        @data.rows.count.times do |r|
          @cell_presenters[c][r] = nil
        end
      end
    end
    
    # Renders Data Table as HTML
    # @return [String] Data Table in HTML form
    def as_html
      @cell_presenters.flatten.uniq.each do |p|
        p.prepare(self) if p.respond_to? :prepare
      end
      
      table = Html::Element.new(:table, "", :class => "data_table")
      header = table.new_child(:tr)
      
      @data.columns.each do |col|
        header.new_child(:th, col.label, :class => col.identifier)
      end
      
      @data.rows.each_index do |row|
        html_class = (row % 2 == 1) ? "odd" : "even"
        if row == @data.rows.size-1
          html_class += " last"
        end
        row_element = table.new_child(:tr, "", :class => html_class)
        @data.rows[row].each_index do |col|
          cell_element = row_element.new_child(:td,
                           @data.formatted_value_at(row, col),
                           :class => @data.columns[col].identifier)
          if presenter = presenter_at(row, col)
            presenter.present(cell_element, @data.rows[row][col], row)
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
    
    # Adds cell presenter to a position.
    # @param [Hash] Hash of position. {:col => ..., :row => ...}
    # @param [ID] Presenter class.
    #
    # Passed hash must have two keys, :col and :row. It can be
    # either a symbol (:all, :none, :first, :last) or array of
    # elements specified by symbol (column identifier) or an Integer
    # (column or row number.)
    # 
    # @example Adding presenter to all rows, but only first column
    #   table.add_cell_presenter({:row => :all, :col => :first})
    # @example Adding presenter to first two rows and column with id :title
    #   table.add_cell_presenter({:row => [0, 1], :col => [:title]})
    def add_cell_presenter(position, presenter)
      @data.columns.each_index do |col|
        @data.rows.each_index do |row|
          if matches_position(position, col, row)
            @cell_presenters[col][row] = presenter
          end
        end
      end
    end
    
    # Removes cell presenter from a position.
    # @param [Hash] Hash of position. {:col => ..., :row => ...}
    # @see Table#add_cell_presenter
    def remove_cell_presenter(position)
      @data.columns.each_index do |col|
        @data.rows.each_index do |row|
          if matches_position(position, col, row)
            @cell_presenters[col][row] = nil
          end
        end
      end
    end
    
    # Returns presenter at specified index.
    # @param [Integer] Row
    # @param [Integer] Column
    def presenter_at(row, col)
      @cell_presenters[col][row]
    end
    
    # Matches position hash against particular index and returns
    # true if it's matched.
    # @param [Hash] Position
    # @param [Integer] Column
    # @param [Integer] Row
    def matches_position(position, col, row)
      matches_col = if position[:col].is_a? Symbol
        if position[:col] == :all
          true
        elsif position[:col] == :none
          false
        elsif position[:col] == :first &&
          col == 0
          true
        elsif position[:col] == :last &&
          col == @data.columns.size-1
          true
        else
          false
        end
      elsif position[:col].is_a? Array
        if position[:col].include?(col)
          true
        elsif position[:col].include?(@data.columns[col].identifier)
          true
        else
          false
        end
      end
      
      matches_row = if position[:row].is_a? Symbol
        if position[:row] == :all
          true
        elsif position[:row] == :none
          false
        elsif position[:row] == :first &&
          row == 0
          true
        elsif position[:row] == :last &&
          row == @data.rows.size-1
          true
        else
          false
        end
      elsif position[:row].is_a? Array
        if position[:row].include?(row)
          true
        else
          false
        end
      end
      
      matches_col && matches_row
    end
  end
end