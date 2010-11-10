class Paginator
  attr_accessor :page, :total, :page_size
  
  def initialize(options)
    @page = options[:page] || 1
    @total = options[:total]
    @page_size = options[:page_size]
  end
  
  def total_pages
    (@total.to_f / @page_size.to_f).ceil
  end
  
  def paginate?
    @total > @page_size
  end
  
  def offset
    (@page-1) * @page_size
  end
  
  def limit
    @page_size
  end
end