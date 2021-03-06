# encoding: utf-8

require 'riddle/1.10'

class SphinxSearch
  INDEX_NAME = "dimensions"
  DEFAULT_SPHINX_SERVER = "localhost"
  DEFAULT_SPHINX_PORT = 9312
  
  attr_reader :results, :total_found, :conditions
  attr_accessor :limit, :offset, :order, :dictionary
  
  def initialize(query)
    @query = query
    @offset = 0
    @limit = 30
    @conditions = {}
    @dictionary = SearchDictionary.new
  end
  
  def self.new_with_dimension(query, dimension)
    alter_ego = self.new(query)
    alter_ego.conditions[:dimension_id] = dimension.id
    alter_ego
  end
  
  def preprocess_query
    @query = @dictionary.extend_query(@query)
  end
  
  def process
    server = ENV["SPHINX_SERVER"] || DEFAULT_SPHINX_SERVER
    port   = ENV["SPHINX_PORT"] || DEFAULT_SPHINX_PORT
    client = Riddle::Client.new(server, port.to_i)
    
    client.match_mode = :extended
    
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
    
    preprocess_query
    result = client.query(@query)
    
    document_ids = result[:matches].collect do |match|
      match[:doc]
    end
    
    connection = Brewery::workspace.connection
    dataset = connection[:idx_dimensions]
    
    query = dataset.filter(:id => document_ids)
    
    if @order == "alphabet"
      query = query.order_by(:description_value)
    end
    
    @results = query.all
    @total_found = result[:total_found]    
  end
  
end