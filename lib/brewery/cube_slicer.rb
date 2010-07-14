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
    attr_reader :cuts, :cube
    
    # Separator for cuts.
    CUT_SEPARATOR = "/"
    
    # Separates dimension name and its path.
    DIMENSION_SEPARATOR = ":"
    
    # Separates path fragments.
    PATH_SEPARATOR = "-"
    
    # Initializes new empty CubeSlicer.
    # @param [Cube] Cube which will be used to create dimensions/slices
    def initialize(cube)
      @cube = cube
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
      param_string = URI.unescape(param_string)
      cuts = param_string.split(CUT_SEPARATOR)
      
      cuts.each do |d|
        dimension, value = d.split(DIMENSION_SEPARATOR)
        return false unless dimension && value
        dimension = @cube.dimension_with_name(dimension)
        path = value.split(PATH_SEPARATOR).collect { |v|
          v == "*" ? :all : v
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
    
    def remove_cut(dim)
      cut_index = @cuts.find_index { |c| 
        c[0] == dim
      }
      @cuts.delete_at(cut_index)
    end
    
    def without(dim)
      alter_ego = Marshal.load(Marshal.dump(self))
      alter_ego.remove_cut(dim)
      alter_ego
    end
    
    # Creates slice from cuts stored in CubeSlicer.
    # @return [Slice] Slice with cuts stored in CubeSlicer.
    def to_slice
      slice = @cube.whole
      self.cuts.each do |dimension, path|
        # puts "#{dimension.to_s} → #{path.to_s}"
        cut = Cut.point_cut(dimension, path)
        slice = slice.cut_by(cut)
      end
      slice
    end
    
    # Converts stored cuts to URL-compatible parameter.
    # @return [String] Parameter to be used in URL.
    def to_param(max_level = nil)
      @cuts.collect do |dim, path|
        dim = dim.name
        if max_level
          path = path[0, max_level]
        end
        path = path.collect { |p| 
          p == :all ? "*" : p
        }.collect { |p|
          URI.escape(p.to_s)
        }.join(PATH_SEPARATOR)
        "#{dim}#{DIMENSION_SEPARATOR}#{path}"
      end.join(CUT_SEPARATOR)
    end
    
    def cuts
      @cuts
    end
    
    def cut_for_dimension(dimension_name)
      @cuts.select { |c| c[0].name == dimension_name.to_s }.first
    end
    
    def detail_for_dimension(dimension_name)
      dimension, path = cut_for_dimension(dimension_name)
      dimension.detail_for_path(path)
    end
  end
end