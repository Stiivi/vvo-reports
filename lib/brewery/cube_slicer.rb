# encoding: utf-8

module Brewery
  class CubeSlicer
    CUT_SEPARATOR = "/"
    DIMENSION_SEPARATOR = ":"
    PATH_SEPARATOR = "-"
    
    def initialize
      @cuts = []
    end
    
    def self.reference_with_param(param_string)
      reference = self.new
      reference.update_from_param(param_string)
      reference
    end
    
    def update_from_param(param_string)
      cuts = param_string.split(CUT_SEPARATOR)
      
      cuts.each do |d|
        dimension, value = d.split(DIMENSION_SEPARATOR)
        path = value.split(PATH_SEPARATOR).collect { |v|
          v == "*" ? nil : v
        }
        # Find cut with same dimension
        cut_index = @cuts.find_index { |c| c[0] == dimension }
        if cut_index
          # If there's already cut with this index, we want to 
          # update stuff.
          # FIXME: Now, we're swapping whole path. In future, we want
          # to add those parts of path, that have changed. 
          # e.g.: If current path is *-*-10, and we add 2010, it should
          # be 2010-*-10
          @cuts[cut_index] = [dimension, path]
        else
          @cuts << [dimension, path]
        end
      end
    end
    
    def to_slice(cube)
      slice = cube.whole
      @cuts.each do |dimension, path|
        path = path.collect { |s| s == nil ? :all : s }
        # path = path.collect { |s| s =~ /\d+/ ? s.to_i : s }
        cut = Cut.point_cut(cube.dimension_object(dimension), path)
        slice = slice.cut_by(cut)
      end
      slice
    end
    
    def to_param
      @cuts.collect do |dim, val|
        path = val.collect { |p| 
          p == nil ? "*" : p
        }.join(PATH_SEPARATOR)
        "#{dim}#{DIMENSION_SEPARATOR}#{path}"
      end.join(CUT_SEPARATOR)
    end
  end
end