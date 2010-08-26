# encoding: utf-8

module SearchHelper
  SPECIAL_SYMBOLS = %w{aá eéě ií oó uú yý zž sš cč tť dď lľĺ nň rřŕ}
  
  @@queries = {}
  
  def highlight_query(sentence, query)
    @@queries[query] ||= create_query(query)
    query = @@queries[query]
    sentence.gsub(/(#{query})/i, '<em>\1</em>').html_safe
  end
  
  protected
  
  def create_query(query)
    query = query.clone
    query.gsub!('*', '')
    SPECIAL_SYMBOLS.each do |s|
      query_regexp = /[#{s}]/
      query.gsub!(query_regexp, "[#{s}]")
    end
    query
  end
end