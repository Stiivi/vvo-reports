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
    
    client.offset = @offset
    client.limit = @limit
    
    if @order == "alphabet"
      client.sort_mode = :attr_asc
      client.sort_by = 'description_value_ordinal'
    end
    
    result = client.query(@query)
    
    document_ids = result[:matches].collect do |match|
      match[:doc]
    end
    
    connection = Brewery::workspace.connection
    dataset = connection[:idx_dimensions]
    
    query = dataset.filter(:id => document_ids) #.limit(@limit, @offset)
    # Problem here. Order at two places. This is because Sphinx
    # returns list of IDs which are in correct order, but SQL won't
    # use that order and it will mess it up. So I have to reorder 
    # by description value again.
    # I have no idea what happens when I use default ordering option
    # called "Relevance". I suppose as long as client thinks it's Relevance
    # it doesn't matter that it's actually random mess.
    if @order == "alphabet"
      query = query.order_by(:description_value)
    end
    @results = query.all
    @total_found = result[:total_found]    
  end
  
end