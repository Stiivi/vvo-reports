module NavigationHelper
  def navigation_link(label, path, matcher = nil)
    link = link_to label, path
    if matcher && matcher =~ request.path
      html_class = "active"
    elsif !matcher && request.path.include?(path)
      html_class = "active"
    end
    li = content_tag(:li, link, :class => html_class)
  end
end