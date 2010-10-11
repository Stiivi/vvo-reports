# encoding: utf-8

class FactsController < ApplicationController
  before_filter :initialize_model

  DEFAULT_SORT_FIELD = "vestnik_cislo"
  DEFAULT_SORT_DIRECTION = "asc"

  DEFAULT_SORT_FIELD = "zmluva_hodnota"
  DEFAULT_SORT_DIRECTION = "desc"

  def index
    @fields = {
    vestnik_cislo: "Vestník",
    zakazka_nazov: "Názov zákazky",
    zmluva_hodnota: "Hodnota zmluvy",
    :"cpv.cpv_code" => "Kategória",
    :"dodavatel.name" => "Dodávateľ",
    :"obstaravatel.name" => "Obstarávateľ",
    # druh_postupu: "Druh postupu"
    }
    
    @slicer = Brewery::CubeSlicer.new(@cube)
    if params[:cut]
      @slicer.update_from_param(params[:cut])
    end
    
    @slice = @slicer.to_slice
    total = @slice.aggregate(:zmluva_hodnota).summary[:record_count]
    
    @paginator = Paginator.new(:page => (params[:page]||1).to_i, :page_size => DEFAULT_PAGE_SIZE, :total => total)
    if params[:sort]
      sort_field = params[:sort]
      sort_direction = params[:dir] || "asc"
    else
      sort_field = DEFAULT_SORT_FIELD
      sort_direction = DEFAULT_SORT_DIRECTION
    end
        
    respond_to do |format|
      format.html {
        @facts = @slice.facts(:page => @paginator.page-1,
                             :page_size => @paginator.page_size,
                             :order_by => sort_field,
                             :order_direction => sort_direction )
      }
      format.csv {
        dataset = @slice.facts
        
        self.response_body = proc { |response, output|
          output.write(CSV.generate_line(dataset.columns))
          # For now, this downloads all data at once.
          # This is of course not what we need, but first we should
          # get this working.
          # It doesn't work at the moment, because of Sequel error when
          # calling something like `dataset.collect` from inside the proc.
          data = dataset.collect {|line| line.values }
          data.each do |line|
            output.write(CSV.generate_line(line))
          end
        }
      }
    end
    
  end

  def show
    @id = params[:id]
    
    @fact = @cube.fact(@id)
    
    dim = @cube.dimension_with_name('cpv')
    levels = dim.default_hierarchy.levels

    @cpv_path = []
    @cpv_view = []
    levels.each { |level|
        key = @fact[level.key_field.to_sym]
        @cpv_path << (key ? key : '*')

        value =  @fact[level.description_field.to_sym]
        value = '(bez popisu)' if !value
        hash = { :label => level.label.capitalize,
                 :path => @cpv_path.join('-'),
                 :value => value,
                 :key => key}
        @cpv_view << hash
    }
    @cpv_view.reverse!
  end
  
  protected
  
  def render_csv_from_dataset_to_output(dataset, output)
    total = dataset.count
    step_size = 200
    step_count = ceil(total.to_f / step_size.to_f)
  end
end