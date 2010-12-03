module Search
  def prepare_search
    @results = {}
    prepare_date_picker
    prepare_dimension_pickers
    prepare_current_cut
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
        collect { |p| [p[:"druh_postupu.druh_postupu_desc"], p[:"druh_postupu.druh_postupu_code"]]}
    @kriteria_vyhodnotenia = [nil] +
      @cube.whole.dimension_values_at_path(:kriteria_vyhodnotenia, []).
        collect { |p| [p[:"kriteria_vyhodnotenia.kriteria_vyhodnotenia_desc"], p[:"kriteria_vyhodnotenia.kriteria_vyhodnotenia_code"]]}
  end
  
  def prepare_current_cut
    slicer = Brewery::CubeSlicer.new(@cube)
    slice = slicer.to_slice
    slicer.update_from_param(params[:current_cut])
    @current_cut = slicer.cuts.collect do |cut|
      dimension, path = *cut
      level = dimension.default_hierarchy.levels[path.count-1]
      detail = slice.dimension_detail_at_path(dimension, path)
      title = detail[level.short_description_field.to_sym]
      {:dimension => dimension, :path => path, :title => title}
    end
  end
end