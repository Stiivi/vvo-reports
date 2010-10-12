# encoding: utf-8

module DataView
  class PieChart
    def initialize(data, options)
      @data = data
      @options = options
      raise "Missing option :labels" unless options.has_key?(:labels)
      raise "Missing option :series" unless options.has_key?(:labels)
      @color_list = ColorList.new(@options[:color_list] || 'default')
    end
    
    def as_html
      data_for_chart = []
      colors = []
      
      @data.rows.each_index do |row|
        labels = format_value_for_legend(
          @data.formatted_value_at(row, @options[:labels])
        )
        label_id = @data.value_at(row, @options[:labels])
        series = @data.value_at(row, @options[:series])
        colors << "#" + @color_list.color_at(row)
        data_for_chart << [labels, series.to_f]
      end
      
      chart_container_id = "chart_#{self.object_id}"
      chart_container = Html::Element.new("div", "", :id => chart_container_id, :class => "chart")
      
      chart_options = {
        width: 350,
        height: 150,
        is3D: true,
        legend: 'none',
        colors: colors
      }
      
      if @options[:legend]
        chart_options.merge!({
          legend: 'left',
          legendTextStyle: {
            color: 'black',
            fontName: 'Arial',
            fontSize: '15px'
          },
          width: 938,
          height: 300
        })
      end
      
      javascript_code = <<-HERE
      (function(){
        var json_data = #{data_for_chart.to_json};
        google.setOnLoadCallback(function(){
          var table = new google.visualization.DataTable();
          table.addColumn('string', 'Label');
          table.addColumn('number', 'series');
          table.addRows(json_data);
          var chart = new google.visualization.PieChart(document.getElementById('#{chart_container_id}'));
          chart.draw(table, #{chart_options.to_json});
        });
      })();
      HERE
      javascript_code = javascript_code.gsub(/\s+/, ' ')
      
      javascript_element = Html::Element.new("script", javascript_code, :type => "text/javascript")
      
      result = chart_container.to_s + javascript_element.to_s
      
      result
    end
    
    def format_value_for_legend(value)
      lines = []
      words_so_far = []
      value.split(' ').each_with_index do |word, index|
        if (words_so_far.clone<<word).join(' ').length >= 32
          lines << words_so_far.join(' ')
          words_so_far = []
        end
        words_so_far << word
      end
      lines << words_so_far.join(' ')
      if lines.length > 2
        lines = lines[0..1]
        lines[-1] += " …"
      end
      lines.join("\n")
    end
  end
end