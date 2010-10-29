# encoding: utf-8

class SphinxSearch
  INDEX_NAME = "dimensions"
  
  attr_reader :results, :total_found
  attr_accessor :limit, :offset, :order
  
  def initialize(query, dimension = nil)
    @query = query
    @dimension = dimension
    @offset = 0
    @limit = 30
  end
  
  def process
    sphinx_client = Sphinx::Client.new
    if @dimension
      sphinx_client.SetFilter('dimension_id', [@dimension.id])
    end
    if @limit
      sphinx_client.SetLimits(@offset, @limit)
    end
    @result = {}
    query = @query.force_encoding('utf-8')
    converted_query = Iconv.conv('us-ascii//translit', 'utf-8', query).gsub(/'/, '')
    result = sphinx_client.Query(converted_query, INDEX_NAME)
    @total_found = result['total_found']
    document_ids= result['matches'].collect { |match|
      match['id']
    }
    connection = Brewery::workspace.connection
    dataset = connection[:idx_dimensions]
    if @order == "alphabet"
      @results = dataset.filter(:id => document_ids).order_by(:value).all
    else
      @results = dataset.filter(:id => document_ids).all
    end
  end
  
end