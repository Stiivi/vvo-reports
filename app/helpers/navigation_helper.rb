module NavigationHelper
  def navigation_link(label, path)
    link = link_to label, path
    puts "PROCESSING NAVIGATION ITEM #{[request.path, path].inspect}"
    if request.path.include?(path)
      html_class = "active"
    end
    li = content_tag(:li, link, :class => html_class)
  end
end