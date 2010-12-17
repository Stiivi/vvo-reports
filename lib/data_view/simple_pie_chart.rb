class DataView::SimplePieChart
  include ActionView::Helpers::TextHelper
  
  def initialize(data, options)
    @data = data
    @options = options
    raise "Missing option :labels" unless options.has_key?(:labels)
    raise "Missing option :series" unless options.has_key?(:labels)
    @color_list = DataView::ColorList.new(@options[:color_list] || 'default')
  end
  
  def as_html
    data_for_chart = []
    colors         = []
    
    labels         = []
    data           = []
    sum            = 0
    
    @data.rows.each_index do |row|
      labels << truncate(
        @data.formatted_value_at(row, @options[:labels]),
        :length => 28
      )
      value   = @data.value_at(row, @options[:series]).to_f
      sum     += value
      data    << value
      colors  << @color_list.color_with_name_or_index(
        @data.value_at(row, @options[:labels]), 
        row
      ).to_s
    end
    
    data = data.collect do |value|
      value/sum * 100
    end
    
    base = "http://chart.apis.google.com/chart"
    params = {}
    params[:chl] = labels.join("|")
    params[:chs] = "450x150"
    params[:cht] = "p"
    params[:chd] = "t:" + data.collect { |d| d.to_s }.join(",")
    params[:chco] = colors.join("|")
    
    url = base + "?" + params.collect do |par, val|
      "#{par}=#{val}"
    end.join("&")
    
    
    chart = Html::Element.new("img", "", :src => url)
    
    chart
  end
end