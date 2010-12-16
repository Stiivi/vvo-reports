module DataView
  class BarChart
    def initialize(data, options)
      @data = data
      @options = options
      raise "Missing option :labels" unless options.has_key?(:labels)
      raise "Missing option :series" unless options.has_key?(:labels)
      raise "Missing option :dimension" unless options.has_key?(:dimension)
    end
    
    def as_html
      data_for_chart = []
      links = []
      
      presenter = Presenter::Report.new(:dimension => @options[:dimension])
      @data.rows.each_index do |row|
        labels = @data.formatted_value_at(row, @options[:labels])
        series = @data.value_at(row, @options[:series])
        link = presenter.path(@data.value_at(row, @options[:labels]))
        links << link
        data_for_chart << [labels, series.to_f]
      end
      
      chart_container_id = "chart_#{self.object_id}"
      chart_container = Html::Element.new("div", "", :id => chart_container_id)
      
      javascript_code = <<-HERE
      (function(){
        var json_data = #{data_for_chart.to_json};
        var links_data = #{links.to_json};
        google.setOnLoadCallback(function(){
          var table = new google.visualization.DataTable();
          table.addColumn('string', 'Label');
          table.addColumn('number', '');
          table.addRows(json_data);
          var chart = new google.visualization.ColumnChart(document.getElementById('#{chart_container_id}'));
          chart.draw(table, {width: 900, height: 240, is3D: true, legend: 'none'});
          google.visualization.events.addListener(chart, 'select', function(){
            var selection = chart.getSelection();
            var selected = selection[0];
            if (selected) {
              document.location = links_data[selected.row];
            };
          });
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