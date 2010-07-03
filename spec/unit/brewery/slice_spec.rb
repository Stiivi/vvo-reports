require "spec_helper.rb"

module Brewery
  describe Slice do
    before do
      slicer = Brewery::CubeSlicer.new(@cube)
      slicer.update_from_param("date:2009")
      @slice = slicer.to_slice
    end
    
    describe ".facts" do
      it "should order facts ascending" do
        facts = @slice.facts(:page => 1, :page_size => 5, :order_by => "vestnik_cislo", :order_direction => "asc")
        facts = facts.to_a
        sorted_facts = facts.sort_by { |f| f[:vestnik_cislo] }
        facts.should == sorted_facts
      end
      
      it "should order facts descending" do
        facts = @slice.facts(:page => 1, :page_size => 5, :order_by => "vestnik_cislo", :order_direction => "desc")
        facts = facts.to_a
        sorted_facts = facts.sort_by { |f| f[:vestnik_cislo] }.reverse
        facts.should == sorted_facts
      end
      
      it "should order by column from other dimension" do
        facts = @slice.facts(:page => 1, :page_size => 10, :order_by => "obstaravatel.name")
        facts.count.should == 10
      end
    end
  end
end