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
        if !dimension
            raise ArgumentError, "no dimension specified in parameter \'#{param_string}\'"
        end
        path = value.split(PATH_SEPARATOR).collect { |v|
          v == "*" ? :all : v
        }
        path.reverse_each do |part|
          if part == :all
            path.delete(part)
          else
            break
          end
        end
        
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
    
    # Removes a cut
    # @param [Dimension] dimension of which cut should be removed
    def remove_cut(dim)
      cut_index = @cuts.find_index { |c| 
        c[0] == dim
      }
      @cuts.delete_at(cut_index)
    end
    
    # Returns a clone and calls remove_cut
    # @param [Dimension] dimension of which cut should be removed
    # @see remove_cut
    def without(dim)
      alter_ego = self.clone
      alter_ego.remove_cut(dim)
      alter_ego
    end
    
    # Strips path of a dimension
    # @param [Dimension] dimension of which path should be stripped
    # @param [Level] level that should be left
    def strip_path(dimension, level)
      # Get dimension
      dimension, path = cut_for_dimension(dimension.name)
      
      slice = to_slice
      path.each_index do |i|
        if path[i] == :all
          # FIXME: what is this? and why is this called in a loop?
          detail = slice.dimension_detail_at_path(dimension, path)
          # detail = dimension.detail_for_path(path)
          field = dimension.levels[i].key_field
          value = detail[field.to_sym]
          path[i] = value
        end
      end
      
      dimension.levels.each do |l|
        # raise l.inspect
      end
      
      path = path.collect { |p| 
        p == :all ? "this is awkward" : p
      }
      puts "[path] #{path.inspect}"
      # Get position of requested level in dimension's levels
      position = dimension.levels.find_index(level)
      path = path[0, position+1].join(PATH_SEPARATOR)
      param = "#{dimension.name}#{DIMENSION_SEPARATOR}#{path}"
      update_from_param(param)
      self
    end
    
    # Sets value of dimension on level to value.
    # @param [Dimension] dimension
    # @param [Level] level
    # @param [value] new value
    def update_value(dimension, level, value)
      dimension = @cube.dimension_object(dimension)
      cut = cut_for_dimension(dimension.name)
      level_position = dimension.levels.find_index(level)
      
      if cut
        # There's already a cut, (ergo path) for this dimension
        dimension, path = cut_for_dimension(dimension.name)
        path[level_position] = value
        path.each do |part|
          part = "*" if part.nil?
        end
      else
        # No path, let's create a new one
        path = ["*"]*level_position + [value]
      end
      
      path = path.join(PATH_SEPARATOR)
      param = "#{dimension.name}#{DIMENSION_SEPARATOR}#{path}"
      self.update_from_param(param)
      self
    end
    
    
    # Creates slice from cuts stored in CubeSlicer.
    # @return [Slice] Slice with cuts stored in CubeSlicer.
    def to_slice
      slice = @cube.whole
      self.cuts.each do |dimension, path|
        # puts "(generating slice ...) #{dimension.name} → #{path.to_s}"
        cut = Cut.point_cut(dimension, path)
        slice = slice.cut_by(cut)
      end
      slice
    end
    
    # Converts stored cuts to URL-compatible parameter.
    # @return [String] Parameter to be used in URL.
    def to_param
      @cuts.collect do |dim, path|
        dim = dim.name
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
      slice = to_slice
      slice.dimension_detail_at_path(dimension, path)
    end
    
    def clone
      new_self = super
      new_self.instance_variable_set("@cuts", self.cuts.clone)
      new_self
    end
  end
end