# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::Individual do

  it "stores id, fenotype and SNPs information for an individual" do
    @individual = Nimbus::Individual.new(11, 33.275, [1,0,2,1])
    expect(@individual.id).to eq 11
    expect(@individual.fenotype).to eq 33.275
    expect(@individual.snp_list).to eq [1,0,2,1]
  end

end