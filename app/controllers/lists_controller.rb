# encoding: utf-8

class ListsController < ApplicationController
  before_filter :initialize_model
  include Reports
  
  # params[:id] - field for the list to be show
  #               the one that should be used for aggregation
  def show
    type = params[:id]
    raise "Invalid type #{type}" unless \
      %w{supplier procurer cpv postup}.include?(type)
    
    # All preparation shit comes in here.
    initialize_slicer
    @slice = @slicer.to_slice
    result = @slice.aggregate(:zmluva_hodnota)
    @total = result.summary[:record_count]
    hodnota_zmluv = result.summary[:sum].to_f
    @slice.add_computed_field(:podiel) { |record|
      record[:zmluva_hodnota_sum] / hodnota_zmluv
    }

    # Options
    @aggregate_options = {}
    
    # Paginator
    @paginator = Paginator.new(:page => (params[:page]||1).to_i, :page_size => 20, :total => @total)
    unless params[:format] == "csv"
      @aggregate_options.merge!({
        :page_size => @paginator.page_size,
        :page => @paginator.page-1
      })
    end
    
    # Sorting
    @aggregate_options.merge!({
      :order_by => params[:sort] ||= "zmluva_hodnota_sum",
      :order_direction => params[:dir] ||= "desc"
    })
    
    self.send(type)
    
    respond_to do |format|
      format.html do
        render :action => type
      end
      format.csv do
        slice_filename = @slicer.to_a.flatten.join("-")
        filename = "#{type}-#{slice_filename}.csv"
        response.headers["Content-Disposition"] = "attachment; filename=#{filename}"
        render :text => table_as_csv(@table)
      end
    end
  end
  
  def supplier
    aggregate_options = @aggregate_options.merge({
      :row_dimension => :dodavatel, 
      :row_levels => [:organisation]
    })
    result = @slice.aggregate(:zmluva_hodnota, aggregate_options)

    @table = Brewery::DataTable.new
    @table.add_column(:text, "Firma", :firma)
    @table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€'})
    @table.add_column(:percent, "Podiel", :podiel, { :precision => 2 } )
    result.rows.each { |row|
      @table.add_row([[row[:"dodavatel.ico"], row[:"dodavatel.name"]], row[:zmluva_hodnota_sum], row[:podiel]])
    }
  end
  
  def procurer
    aggregate_options = @aggregate_options.merge({
      :row_dimension => :obstaravatel, 
      :row_levels => [:organisation]
    })
    result = @slice.aggregate(:zmluva_hodnota, aggregate_options)
    
    @table = Brewery::DataTable.new
    @table.add_column(:text, "Obstaravatel", :firma)
    @table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€'})
    @table.add_column(:percent, "Podiel", :podiel, { :precision => 2 } )
    result.rows.each { |row|
      @table.add_row([[row[:"obstaravatel.ico"], row[:"obstaravatel.name"]], row[:zmluva_hodnota_sum], row[:podiel]])
    }
  end
  
  def cpv
    @dimension = @cube.dimension_with_name(:cpv)
    @next_level = level = level_for_dimension(@slice, @dimension)

    levels_to_select = []
    @dimension.levels.each do |l|
      levels_to_select << l
      if l == level
        break
      end
    end
    levels_to_select.collect! { |l| l.name }
    @description_field = description_field = level.description_field.to_sym
    key_field = level.key_field.to_sym
    
    aggregate_options = @aggregate_options.merge({
      :row_dimension => @dimension.name, 
      :row_levels => levels_to_select
    })
    result = @slice.aggregate(:zmluva_hodnota, aggregate_options)
    @table = Brewery::DataTable.new
    @table.add_column(:text, "Typ tovaru", description_field)
    @table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€'})
    @table.add_column(:percent, "Podiel", :podiel, { :precision => 2 } )
    result.rows.each { |row|
        @table.add_row([[row[key_field], row[description_field]], row[:zmluva_hodnota_sum], row[:podiel]])
    }
  end
  
  def postup
    aggregate_options = @aggregate_options.merge({
      :row_dimension => :druh_postupu, 
      :row_levels => [:druh_postupu]
    })
    result = @slice.aggregate(:zmluva_hodnota, aggregate_options)
    @table = Brewery::DataTable.new
    @table.add_column(:text, "Druh postupu", :druh_postupu)
    @table.add_column(:currency, "Suma", :suma, {:precision => 0, :currency => '€'})
    @table.add_column(:percent, "Podiel", :podiel, { :precision => 2 } )
    result.rows.each { |row|
        @table.add_row([[row[:"druh_postupu.druh_postupu_code"], row[:"druh_postupu.druh_postupu_desc"]], row[:zmluva_hodnota_sum], row[:podiel]])
    }
  end
  
  protected
  
  def table_as_csv(table)
    result = ""
    data = CSV.new(result)
    data << table.columns.collect(&:identifier)
    table.rows.each do |row|
      data << row.collect { |cell| (cell.formatted_value || "%f"%cell.value) }
    end
    result
  end
  
  def initialize_slicer
    @slicer = Brewery::CubeSlicer.new(@cube)
    
    # Update from params
    if params[:cut]
      @slicer.update_from_param(params[:cut])
    end
  end
end