# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::Tree do

  before(:each) do
    @config = Nimbus::Configuration.new
    @config.load fixture_file('regression_config.yml')

    @tree = Nimbus::Tree.new @config.tree
  end

  it "is initialized with tree config info" do
    @tree.snp_total_count.should == 200
    @tree.snp_sample_size.should == 60
    @tree.node_min_size.should   == 5
  end

end