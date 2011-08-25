# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::Forest do
  before(:each) do
    @config = Nimbus::Configuration.new
    @config.load fixture_file('regression_config.yml')
    @config.load_training_data
    @forest = ::Nimbus::Forest.new @config
  end
  
  it 'grows a forest of N trees' do
    @forest.trees.should == []
    @config.forest_size.should == 3
    @forest.grow
    @forest.trees.size.should == @config.forest_size
    @forest.trees.each{|t| t.should be_kind_of Hash}
  end
  
  it 'creates averaged predictions for individuals in the training set' do
    @forest.predictions.should == {}
    @forest.grow
    (@forest.predictions.keys - (1..800).to_a ).should == []
    @forest.predictions.values.each{|v| v.should be_kind_of Numeric}
  end
  
  it 'computes averaged SNP importances for every SNP' do
    @forest.snp_importances.should == {}
    @forest.grow
    @forest.snp_importances.keys.sort.should == (1..200).to_a
    @forest.snp_importances.values.each{|v| v.should be_kind_of Numeric}
  end
  
  it 'traverses a set of testing individuals through every tree in the forest and return predictions' do
    @forest = @config.load_forest
    @forest.predictions.should == {}
    
    tree_structure = YAML.load(File.open fixture_file('regression_random_forest.yml'))
    expected_predictions = {}
    @config.read_testing_data{|individual|
      individual_prediction = 0.0
      tree_structure.each do |t|
        individual_prediction = (individual_prediction + Nimbus::Tree.traverse(t, individual.snp_list)).round(5)
      end
      expected_predictions[individual.id] = (individual_prediction / 3).round(5)
    }
    
    @forest.traverse
    @forest.predictions.should == expected_predictions    
  end
  
  it 'can output forest structure in YAML format' do
    @forest = @config.load_forest
    YAML.load(File.open fixture_file('regression_random_forest.yml')) == YAML.load(@forest.to_yaml)
  end
  
end