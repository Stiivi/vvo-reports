# encoding: utf-8

require 'riddle/1.10'

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
    client = Riddle::Client.new
    
    # So here's the hack. After two hours of fun I still
    # couldn't get Sphinx sorting to work. 
    # So I'm gonna get all IDs (but max 10k) from Sphinx and let the database
    # do the sorting.
    client.limit = 10000
    
    # For the case I'll ever want to get this sorting to work:
    # if @order == "alphabet"
    #   client.sort_mode = :attr_asc
    #   client.sort_by = 'description_value'
    # end
    
    result = client.query(@query)
    document_ids = result[:matches].collect do |match|
      match[:doc]
    end
    
    connection = Brewery::workspace.connection
    dataset = connection[:idx_dimensions]
    
    query = dataset.filter(:id => document_ids).limit(@limit, @offset)
    if @order == "alphabet"
      query = query.order_by(:description_value)
    end
    @results = query.all
    @total_found = result[:total_found]

    # I'm gonna keep this piece around for a while. I'm pretty sure
    # sure some bug was getting resolved by this piece, I just don't
    # know which one. Anyway, I'm pretty sure client will let us know
    # if there's still a problem and I'll be happy to uncomment this
    # again in that case.
    #
    #     query = @query.force_encoding('utf-8')
    #     converted_query = Iconv.conv('us-ascii//translit', 'utf-8', query).gsub(/'/, '')
    
  end
  
end