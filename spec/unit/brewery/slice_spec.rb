require "spec_helper.rb"

module Brewery
  describe Slice do
    before do
      slicer = Brewery::CubeSlicer.new(@cube)
      slicer.update_from_param("date:2009")
      @slice = slicer.to_slice
    end
    
    describe ".facts" do
      it "should order by column from other dimension" do
        facts = @slice.facts(:page => 1, :page_size => 10, :order => "obstaravatel.name")
        facts.count.should == 10
      end
    end
  end
end