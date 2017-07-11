# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::Tree do

  before(:each) do
    @config = Nimbus::Configuration.new
    @config.load fixture_file('regression/config.yml')

    @tree = Nimbus::Tree.new @config.tree
  end

  it "is initialized with tree config info" do
    expect(@tree.snp_total_count).to eq 200
    expect(@tree.snp_sample_size).to eq 60
    expect(@tree.node_min_size).to eq 5
  end

end