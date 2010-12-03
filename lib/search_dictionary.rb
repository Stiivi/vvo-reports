# encoding: utf-8

class SearchDictionary
  def initialize
    @dictionary = {
      "pergamon" => ["p e r g a m o n"]
    }
  end
  
  def extend_query(query)
    words = query.split(" ")
    matches = []
    words.each do |word|
      match = @dictionary[word]
      if match
        matches.concat(match.collect do |w|
          '("%s")' % w
        end)
      end
    end
    
    if matches.present?
      "(" + query + ") | " + matches.join(" | ")
    else
      query
    end
  end
end