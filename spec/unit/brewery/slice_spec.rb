# encoding: utf-8

require "spec_helper.rb"

module Brewery
  describe Slice do
    before do
      @slicer = Brewery::CubeSlicer.new(@cube)
      @slicer.update_from_param("date:2009")
      @slice = @slicer.to_slice
    end
    
    describe ".facts" do
      it "should order facts ascending" do
        facts = @slice.facts(:page => 1, :page_size => 5, :order_by => "id", :order_direction => "asc")
        facts = facts.to_a
        sorted_facts = facts.sort_by { |f| f[:id] }
        facts.should == sorted_facts
      end
      
      it "should order facts descending" do
        facts = @slice.facts(:page => 1, :page_size => 5, :order_by => "id", :order_direction => "desc")
        facts = facts.to_a
        sorted_facts = facts.sort_by { |f| f[:id] }.reverse
        facts.should == sorted_facts
      end
      
      it "should order by column from other dimension" do
        facts = @slice.facts(:page => 1, :page_size => 10, :order_by => "obstaravatel.name")
        facts.count.should == 10
      end
    end
    
    describe ".aggregate" do
      context "cut through druh postupu" do
        it "should return sum" do
          dimension = @cube.dimension_with_name(:druh_postupu)
          cut = Cut.point_cut(dimension, ["verejná súťaž"])
          slice = @slice.cut_by(cut)
          result = slice.aggregate(:zmluva_hodnota)
          result.summary[:sum].should be_a(Numeric)
        end
      end
      
      context "cut through date" do
        it "should give me ordered shit" do
          dimension = @cube.dimension_with_name(:date)
          cut = Brewery::Cut.point_cut(dimension, [2009])
          slice = @slice.cut_by(cut)
          result = slice.aggregate(:zmluva_hodnota, {
            :row_dimension => :dodavatel, 
      		  :row_levels => [:organisation],
            :page => 1,
            :page_size => 10,
            :order_by => "sum",
            :order_direction => "asc"
          })
          rows = result.rows.to_a.collect { |i| {:id => i[:id], :sum => i[:sum]} }
          sorted_rows = rows.sort_by { |i| i[:sum] }
          rows.should == sorted_rows
        end
      end
    end
  end
end