# encoding: utf-8
# input: obdobie

require 'rubygems'
require 'brewery'
require 'haml'
require 'brewery/presenters/data_table_presenter'

module Brewery

class Report

def run
    Brewery::load_default_configuration
    DataObjects::Postgres.logger = DataObjects::Logger.new('sql.log', :debug) 
    
    @workspace = Brewery::Workspace.new(:default)
    @workspace.set_default
    
    @model = Brewery::Model.model_with_name("verejne_obstaravania")
    @cube = @model.cube_with_name("zmluvy")

    slice = @cube.whole
    
    # fact = @cube.fact(50)
    
    # view = [ "document_id", "dodavatel.ico", "date.month", "zmluva_hodnota" ]

    # view.each { |field|
    #    label = @cube.label_for_field(field)
    #    puts "LABEL: #{label}"
    # }

    # fact.field[:document_id]
    # fact["dodavatel.ico"]
    
    slice = slice.cut_by_point(:date, [2010, 3])

    facts = slice.facts
    puts "==> count: #{facts.count}"
    fact = facts.first
    # puts fact
    # puts fact[:"obstaravatel.name" ]
    
    dim = @cube.dimension_with_name("dodavatel")
    puts dim.all_fields.join(',')
    detail = dim.detail_for_path([:all, "44229143"])
    puts detail[:name]
end

end #class
end # module

report = Brewery::Report.new
report.run
