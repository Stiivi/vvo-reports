module DataView
  class ColorCenter
    # FIXME: this is causing ActionView::Template::Error (DataView is not missing constant ColorCenter!)
    # include Singleton
    @@__instance__ = nil
    
    def self.instance
        if !@@__instance__
            @@__instance__ = self.new
        end
        return @@__instance__
    end
    
    def initialize
      @available_colors = []
      @specific_colors = {}
      @generated_colors = {}
      @config_path = File.join(Rails.root, "config", "color_center.yml")
      @config = YAML::load_file(@config_path) 
      reset(:default)
    end
    
    def color_for_string(str)
      if @specific_colors[str]
        @specific_colors[str]
      elsif @generated_colors[str]
        @generated_colors[str]
      else
        new_color = generate_for_string(str)
        @generated_colors[str] = new_color
        new_color
      end
    end
    
    def generate_for_string(str)
      @last_index ||= 0
      if @last_index >= @available_colors.size
        @last_index = 0
      end
      result = @available_colors[@last_index].to_s
      @last_index += 1
      result
    end
    
    def reset(palette_name)
      palette = @config["palettes"][palette_name.to_s]
      raise "Can't find palette named '#{palette_name}' in Color Center config file. (#{@config_path})" unless palette
      @available_colors = palette["colors"]
      @specific_colors = palette["specific_colors"] || {}
      if @specific_colors
        @specific_colors.each do |str, color|
          @available_colors.delete(color)
        end
      end
      @last_index = 0
    end
    
    def reset_generated_colors
      @generated_colors = {}
    end
  end
end