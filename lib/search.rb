module Search
  def prepare_search
    @results = {}
    @param_report = {}
    prepare_date_picker
    prepare_dimension_pickers
  end
  
  def prepare_date_picker
    date_dim = @cube.dimension_with_name(:date)
    slice = @cube.whole
    @years = [nil] + slice.dimension_values_at_path(:date, []).to_a.
      collect { |k| [k[:"date.year"].to_s]*2 }
    months_hash = slice.dimension_values_at_path(:date, [:all]).to_a
    @months = []
    months_hash.each do |m|
      @months[m[:"date.month"]] = m[:"date.month_name"]
    end
    @months = @months.collect.with_index do |month, i|
      [month, i==0?nil:i.to_s]
    end
  end
  
  def prepare_dimension_pickers
    @postupy = [nil] + 
      @cube.whole.dimension_values_at_path(:druh_postupu, []).
        collect { |p| [p[:"druh_postupu.druh_postupu"]]*2}
    @kriteria_vyhodnotenia = [nil] +
      @cube.whole.dimension_values_at_path(:kriteria_vyhodnotenia, []).
        collect { |p| [p[:"kriteria_vyhodnotenia.kriteria_vyhodnotenia"]]*2}
  end
end