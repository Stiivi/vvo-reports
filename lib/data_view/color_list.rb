module DataView
  class ColorList
    # FIXME: this is causing ActionView::Template::Error (DataView is not missing constant ColorCenter!)
    # include Singleton

    attr_reader :default_color
    
    @@lists = nil
    
    def self.load_lists
        lists_path = File.join(Rails.root, "config", "color_lists.yml")
        @@lists = YAML::load_file(lists_path) 
    end
    
    def initialize(list_name)
        if !@@lists
            ColorList::load_lists
        end
        @list = @@lists[list_name]
        if !@list
            raise ArgumentError, "No color list with name #{list_name}"
        end
        @named_colors = @list["named_colors"]
        @indexed_colors = @list["colors"]
        @indexed_color_count = @indexed_colors.count
        @default_color = @list["default_color"]
    end
    
    def named_color(name)
        color = @named_colors[name]
        if ! color
            color = @default_color
        end
        return color
    end

    def color_at(index)
        return @indexed_colors[index % @indexed_color_count]
    end
    
  end
end