# encoding: utf-8

module ApplicationHelper
  
  def link_to_cut(dimension_name, label, path)
      # FIXME: normalize elements - encode ',' in path values
      path_str = path.join(',')
      cut = "cut=#{dimension_name}:#{path_str}"
      link = link_to(label, cut)

      return link
  end
  
  def update_params(with)
    params.delete(:controller)
    params.delete(:action)
    params.merge(with)
  end

  def sort_link(text, column, direction = :asc)
     current_direction = params[:dir] ? params[:dir].to_sym : :asc
     if params[:sort] == column.to_s
       if current_direction == :asc
         html_class = "sort asc"
       else
         html_class = "sort desc"
       end
     end
     if params[:sort] == column.to_s && params[:dir]
       new_direction = (current_direction == :asc ? :desc : :asc)
     else
       new_direction = direction
     end
     link_to text, update_params(:sort => column.to_s, :dir => new_direction), :class => html_class
   end
   
   def date_select
     selected_year, selected_month = nil, nil
     @slicer.cuts.each do |dim, path|
       if dim.name == "date"
         selected_year, selected_month = *path
       end
     end
     date_dim = @cube.dimension_with_name(:date)
     slice = @cube.whole

     values = slice.dimension_values_at_path(date_dim, [])
     years = values.collect { | row | [row[:year].to_s, row[:year].to_s] }
     years.insert(0, ["‹ Rok ›", nil])

     if selected_year
        year = selected_year
     else
        year = :all
     end
     
     values = slice.dimension_values_at_path(date_dim, [year])
     months = values.collect { | row | [ row[:month_name].to_s, row[:month].to_s ] }
     months.insert(0, ["‹ Mesiac ›", nil])

     years_select = select_tag(:"date[0]", options_for_select(years, selected_year), :class => "year")
     months_select = select_tag(:"date[1]", options_for_select(months, selected_month), :class => "month")

     return years_select + " " + months_select
   end
end
