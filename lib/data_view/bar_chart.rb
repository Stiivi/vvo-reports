module DataView
  class BarChart
    def initialize(data, options)
      @data = data
      @options = options
      raise "Missing option :labels" unless options.has_key?(:labels)
      raise "Missing option :series" unless options.has_key?(:labels)
    end
    
    def as_html
      data_for_chart = []
      
      @data.rows.each_index do |row|
        labels = @data.formatted_value_at(row, @options[:labels])
        series = @data.value_at(row, @options[:series])
        data_for_chart << [labels, series.to_f]
      end
      
      chart_container_id = "chart_#{self.object_id}"
      chart_container = Html::Element.new("div", "", :id => chart_container_id)
      
      javascript_code = <<-HERE
      (function(){
        var json_data = #{data_for_chart.to_json};
        google.setOnLoadCallback(function(){
          var table = new google.visualization.DataTable();
          table.addColumn('string', 'Label');
          table.addColumn('number', '');
          table.addRows(json_data);
          var chart = new google.visualization.ColumnChart(document.getElementById('#{chart_container_id}'));
          chart.draw(table, {width: 900, height: 240, is3D: true, labels: 'none'});
        });
      })();
      HERE
      javascript_code = javascript_code.gsub(/\s+/, ' ')
      
      javascript_element = Html::Element.new("script", javascript_code, :type => "text/javascript")
      
      result = chart_container.to_s + javascript_element.to_s
      
      result
    end
  end
end