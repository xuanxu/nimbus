# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::Individual do

  it "stores id, fenotype and SNPs information for an individual" do
    @individual = Nimbus::Individual.new(11, 33.275, [1,0,2,1])
    @individual.id.should       == 11
    @individual.fenotype.should == 33.275
    @individual.snp_list.should == [1,0,2,1]
  end

end