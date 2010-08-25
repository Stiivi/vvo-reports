module DataView
  class PieChart
    def initialize(data, options)
      @data = data
      @options = options
      raise "Missing option :labels" unless options.has_key?(:labels)
      raise "Missing option :series" unless options.has_key?(:labels)
    end
    
    def as_html
      data_for_chart = []
      colors = []
      color_center = ColorCenter.instance
      
      @data.rows.each_index do |row|
        labels = format_value_for_legend(
          @data.formatted_value_at(row, @options[:labels])
        )
        label_id = @data.value_at(row, @options[:labels])
        series = @data.value_at(row, @options[:series])
        colors << "#" + color_center.color_for_string(label_id)
        data_for_chart << [labels, series.to_f]
      end
      
      chart_container_id = "chart_#{self.object_id}"
      chart_container = Html::Element.new("div", "", :id => chart_container_id)
      
      colors_json = colors.to_json
      
      javascript_code = <<-HERE
      (function(){
        var json_data = #{data_for_chart.to_json};
        google.setOnLoadCallback(function(){
          var table = new google.visualization.DataTable();
          table.addColumn('string', 'Label');
          table.addColumn('number', 'series');
          table.addRows(json_data);
          var chart = new google.visualization.PieChart(document.getElementById('#{chart_container_id}'));
          chart.draw(table, {width: 450, height: 240, is3D: true, legend: 'none', colors: #{colors_json}});
        });
      })();
      HERE
      javascript_code = javascript_code.gsub(/\s+/, ' ')
      
      javascript_element = Html::Element.new("script", javascript_code, :type => "text/javascript")
      
      result = chart_container.to_s + javascript_element.to_s
      
      result
    end
    
    def format_value_for_legend(value)
      result = []
      inserted = false
      value.split(' ').each_with_index do |word, index|
        if result.join(' ').length >= 32
          result.insert(result.length-1, "\n") unless inserted
          inserted = true
        end
        result << word
      end
      result.join(' ')
    end
  end
end