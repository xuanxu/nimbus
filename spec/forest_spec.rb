# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::Forest do
  describe "Regression" do
    before(:each) do
      @config = Nimbus::Configuration.new
      @config.load fixture_file('regression_config.yml')
      @config.load_training_data
      @forest = ::Nimbus::Forest.new @config
    end

    it 'grows a regression forest of N trees' do
      @forest.trees.should == []
      @config.forest_size.should == 3
      @forest.should_not be_classification
      @forest.should be_regression
      @forest.grow
      @forest.trees.size.should == @config.forest_size
      @forest.trees.each{|t| t.should be_kind_of Hash}
    end

    it 'creates averaged predictions for individuals in the training set' do
      @forest.predictions.should == {}
      @forest.grow
      (@forest.predictions.keys - (1..800).to_a ).should == [] # 800 individuals in the training file
      @forest.predictions.values.each{|v| v.should be_kind_of Numeric}
    end

    it 'computes averaged SNP importances for every SNP' do
      @forest.snp_importances.should == {}
      @forest.grow
      @forest.snp_importances.keys.sort.should == (1..200).to_a # 200 snps in the training file
      @forest.snp_importances.values.each{|v| v.should be_kind_of Numeric}
    end

    it 'does not compute SNP importances if config set to false' do
      @forest.snp_importances.should == {}
      @forest.options.do_importances = false
      @forest.grow
      @forest.snp_importances.should == {}
    end

    it 'traverses a set of testing individuals through every tree in the forest and returns predictions' do
      @forest = @config.load_forest
      @forest.predictions.should == {}

      tree_structure = Psych.load(File.open fixture_file('regression_random_forest.yml'))
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
      Psych.load(File.open fixture_file('regression_random_forest.yml')) == Psych.load(@forest.to_yaml)
    end
  end

  describe "Classification" do
    before(:each) do
      @config = Nimbus::Configuration.new
      @config.load fixture_file('classification_config.yml')
      @config.load_training_data
      @forest = ::Nimbus::Forest.new @config
    end

    it 'grows a classification forest of N trees' do
      @forest.trees.should == []
      @config.forest_size.should == 3
      @forest.should be_classification
      @forest.should_not be_regression
      @forest.grow
      @forest.trees.size.should == @config.forest_size
      @forest.trees.each{|t| t.should be_kind_of Hash}
    end

    it 'creates predictions for individuals in the training set' do
      @forest.predictions.should == {}
      @forest.grow
      (@forest.predictions.keys - (1..1000).to_a ).should == [] # 1000 individuals in the training file
      @forest.predictions.values.each{|v| v.should be_kind_of String}
    end

    it 'computes averaged SNP importances for every SNP' do
      @forest.snp_importances.should == {}
      @forest.options.do_importances = true
      @forest.grow
      @forest.snp_importances.keys.sort.should == (1..100).to_a # 100 snps in the training file
      @forest.snp_importances.values.each{|v| v.should be_kind_of Numeric}
    end

    it 'does not compute SNP importances if config set to false' do
      @forest.snp_importances.should == {}
      @forest.options.do_importances = false
      @forest.grow
      @forest.snp_importances.should == {}
    end

    it 'traverses a set of testing individuals through every tree in the forest and returns predictions' do
      @forest = @config.load_forest
      @forest.predictions.should == {}

      tree_structure = Psych.load(File.open fixture_file('classification_random_forest.yml'))
      expected_predictions = {}
      @config.read_testing_data{|individual|
        individual_prediction = []
        tree_structure.each do |t|
          individual_prediction << Nimbus::Tree.traverse(t, individual.snp_list)
        end
        class_sizes = Nimbus::LossFunctions.class_sizes_in_list(individual_prediction, @config.tree[:classes]).map{|p| (p/individual_prediction.size.to_f).round(3)}
        expected_predictions[individual.id] = Hash[@config.tree[:classes].zip class_sizes].map{|k,v| "'#{k}': #{v}"}.join(' , ')
      }

      @forest.traverse
      @forest.predictions.should == expected_predictions
    end

    it 'can output forest structure in YAML format' do
      @forest = @config.load_forest
      Psych.load(File.open fixture_file('classification_random_forest.yml')) == Psych.load(@forest.to_yaml)
    end
  end
end