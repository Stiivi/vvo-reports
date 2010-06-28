# encoding: utf-8

module Brewery
  # CubeSlicer represents state of current slice, all its cuts.
  # It parses URL-like-formatted params and generates actual Brewery::Slice
  # objects. 
  # It provides methods for examining current slicing state and 
  # changing it.
  # 
  # @author Vojto Rinik <vojto@rinik.net>
  
  class CubeSlicer
    # Separator for cuts.
    CUT_SEPARATOR = "/"
    
    # Separates dimension name and its path.
    DIMENSION_SEPARATOR = ":"
    
    # Separates path fragments.
    PATH_SEPARATOR = "-"
    
    # Initializes new empty CubeSlicer.
    def initialize
      @cuts = []
    end
    
    # Initializes CubeSlicer and adds cuts from param.
    # @see CubeSlicer#update_from_param
    # @param [String] string to parse
    # @return [CubeSlicer] newly created instance
    def self.slicer_with_param(param_string)
      slicer = self.new
      slicer.update_from_param(param_string)
      slicer
    end
    
    # Adds cuts from param.
    # @param [String] string to parse
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
    
    # Creates slice from cuts stored in CubeSlicer.
    # @param [Cube] Cube that will be used to create slices.
    # @return [Slice] Slice with cuts stored in CubeSlicer.
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
    
    # Converts stored cuts to URL-compatible parameter.
    # @return [String] Parameter to be used in URL.
    def to_param
      @cuts.collect do |dim, val|
        path = val.collect { |p| 
          p == nil ? "*" : p
        }.collect { |p|
          URI.escape(p)
        }.join(PATH_SEPARATOR)
        "#{dim}#{DIMENSION_SEPARATOR}#{path}"
      end.join(CUT_SEPARATOR)
    end
  end
end