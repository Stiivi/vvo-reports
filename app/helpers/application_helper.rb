module ApplicationHelper
  
  def link_to_cut(dimension_name, label, path)
      # FIXME: normalize elements - encode ',' in path values
      path_str = path.join(',')
      cut = "cut=#{dimension_name}:#{path_str}"
      link = link_to(label, cut)

      return link
  end
end
