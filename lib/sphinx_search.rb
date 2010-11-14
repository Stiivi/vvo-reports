# encoding: utf-8

require 'riddle/1.10'

class SphinxSearch
  INDEX_NAME = "dimensions"
  DEFAULT_SPHINX_SERVER = "localhost"
  DEFAULT_SPHINX_PORT = 9312
  
  attr_reader :results, :total_found, :conditions
  attr_accessor :limit, :offset, :order
  
  def initialize(query)
    @query = query
    @offset = 0
    @limit = 30
    @conditions = {}
  end
  
  def self.new_with_dimension(query, dimension)
    alter_ego = self.new(query)
    alter_ego.conditions[:dimension_id] = dimension.id
    alter_ego
  end
  
  def process
    sphinx_server = ENV["SPHINX_SERVER"]
    if !sphinx_server
        sphinx_server = DEFAULT_SPHINX_SERVER
    end
    sphinx_port = ENV["SPHINX_PORT"]
    if sphinx_port
        sphinx_port = sphinx_port.to_i
    else
        sphinx_port = DEFAULT_SPHINX_PORT
    end

    client = Riddle::Client.new(sphinx_server, sphinx_port)
    
    # Limit
    client.offset = @offset
    client.limit = @limit
    
    # Order
    if @order == "alphabet"
      client.sort_mode = :attr_asc
      client.sort_by = 'description_value_ordinal'
    end
    
    # Conditions
    @conditions.each do |field, value|
      client.filters << Riddle::Client::Filter.new(field.to_s, [value])
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