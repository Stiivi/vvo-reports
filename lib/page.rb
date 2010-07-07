class Page
  PATH = File.join(Rails.root, 'pages')
  
  attr_accessor :path, :type
  
  def self.with_name(name, type = :textile)
    page = self.new
    page.type = type
    page.path = File.join(PATH, name+"."+type.to_s)
    page
  end
  
  def content
    @content ||= File.read(@path)
  end
  
  def to_s
    @content
  end
end