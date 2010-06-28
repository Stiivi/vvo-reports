module DataView
  class ColorCenter
    # FIXME: this is causing ActionView::Template::Error (DataView is not missing constant ColorCenter!)
    # include Singleton
    @@__instance__ = nil

    PALETTE = %w{b3121a ee2029 e90b8e a60d67 ce0beb 9409a9 6e0ce7 4f0aa5 0f57eb 0640b6 04baf6 0788b2 06ea4c 0b9c37 7be707 478504 e0dd05 e3751c db3716}
    
    def self.instance
        if !@@__instance__
            @@__instance__ = self.new
        end
        return @@__instance__
    end
    
    def initialize
      @generated_colors = {}
      # @palette = PALETTE.sort { rand }
      @palette = PALETTE
    end
    
    def color_for_string(str)
      if @generated_colors[str]
        @generated_colors[str]
      else
        new_color = generate_for_string(str)
        @generated_colors[str] = new_color
        new_color
      end
    end
    
    def generate_for_string(str)
      @last_index ||= 0
      if @last_index >= @palette.size
        @last_index = 0
      end
      result = @palette[@last_index]
      @last_index += 1
      result
    end
  end
end