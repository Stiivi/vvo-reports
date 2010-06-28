# encoding: utf-8

module Html
  class Element
    attr_accessor :text
    
    def initialize(type, text = "", options = {})
      @type = type
      @text = text
      @children = []
      @options = options
    end
    
    def to_s
      if @children.empty?
        ("<%s%s>%s</%s>" % [@type, options_to_s, @text, @type]).html_safe
      else
        ("<%s%s>%s</%s>" % [@type, options_to_s, children_to_s, @type]).html_safe
      end
    end
    
    def children_to_s
      @children.collect{|c|c.to_s}.join("")
    end
    
    def options_to_s
      return "" if @options.empty?
      " " + @options.collect do |key, value|
        '%s="%s"' % [key, value]
      end.join(" ")
    end
    
    def new_child(type, text = "", options = {})
      child = Element.new(type, text, options)
      @children << child
      child
    end
    
    def []= (option, value)
      @options[option] = value
    end
  end
end