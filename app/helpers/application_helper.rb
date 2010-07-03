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
end
