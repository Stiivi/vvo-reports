class SphinxSearch
  INDEX_NAME = "dimensions"
  
  attr_reader :results
  
  def initialize(query, dimension = nil)
    @query = query
    @dimension = dimension
  end
  
  def process
    sphinx_client = Sphinx::Client.new
    if @dimension
      sphinx_client.SetFilter('dimension_id', [@dimension.id])
    end
    @result = {}
    result = sphinx_client.Query(@query, INDEX_NAME)
    document_ids= result['matches'].collect { |match|
      match['id']
    }
    connection = Brewery::workspace.connection
    dataset = connection[:idx_dimensions]
    @results = dataset.filter(:id => document_ids).all
  end
  
  # def create_search_with_string(string)
  #   search = Search.new
  #   search.query_string = string
  #   search.search_type = "text"
  #   
  #   query = SearchQuery.query_with_string(string, :scope=>'global', :object=>nil)
  #   search.query = query
  #   query.save
  #   search.save
  #   search
  # end
  # 
  # def perform_search(search)
  #   # TODO. If can't use Sphinx, return false or something.
  #   
  #   sphinx_client = Sphinx::Client.new
  #   
  #   all_results = []
  #   
  #   datasets = DatasetDescription.all
  #   datasets.each do |dataset|
  #     sphinx_client.SetLimits(0, 10)
  #     results = sphinx_client.Query(search.query_string, "index_#{dataset.identifier}")
  #     results['matches'].each do |r|
  #       all_results << {:table_name => dataset.identifier, :record_id => r['id'], :search_query_id => search.query.id}
  #     end
  #   end
  #   
  #   values = all_results.collect{|r|"('#{r[:table_name]}', #{r[:record_id]}, #{r[:search_query_id]})"}.join(",")
  #   
  #   sql_query = "INSERT INTO search_results(table_name, record_id, search_query_id) VALUES #{values}"
  #   
  #   DatasetDescription.connection.execute(sql_query)
  #   
  # end
end