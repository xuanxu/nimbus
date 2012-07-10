# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::Configuration do

  it "loads configuration options from config file" do
    config = Nimbus::Configuration.new
    config.load fixture_file('regression_config.yml')

    config.training_file.should == fixture_file('regression_training.data')
    config.testing_file.should == fixture_file('regression_testing.data')
    config.forest_file.should == fixture_file('regression_random_forest.yml')

    config.forest_size.should == 3
    config.tree_SNP_sample_size.should == 60
    config.tree_SNP_total_count.should == 200
    config.tree_node_min_size.should == 5
  end

  it 'tree method return tree-related subset of options' do
    config = Nimbus::Configuration.new
    tree_options = config.tree

    tree_options[:snp_sample_size].should_not be_nil
    tree_options[:snp_total_count].should_not be_nil
    tree_options[:tree_node_min_size].should_not be_nil
  end

  it "creates a training set object from training data file" do
    config = Nimbus::Configuration.new
    config.load fixture_file('regression_config.yml')
    config.training_set.should be_nil
    config.load_training_data
    config.training_set.should be_kind_of Nimbus::TrainingSet
    config.training_set.all_ids.sort.should == (1..800).to_a

    File.open(fixture_file('regression_training.data')) {|file|
      feno1, id1, *snp_list_1 = file.readline.split
      feno2, id2, *snp_list_2 = file.readline.split
      feno3, id3, *snp_list_3 = file.readline.split

      i1 = Nimbus::Individual.new(id1.to_i, feno1.to_f, snp_list_1.map{|snp| snp.to_i})
      i2 = Nimbus::Individual.new(id2.to_i, feno2.to_f, snp_list_2.map{|snp| snp.to_i})
      i3 = Nimbus::Individual.new(id3.to_i, feno3.to_f, snp_list_3.map{|snp| snp.to_i})

      config.training_set.individuals[id1.to_i].id.should == i1.id
      config.training_set.individuals[id2.to_i].fenotype.should == i2.fenotype
      config.training_set.individuals[id3.to_i].snp_list.should == i3.snp_list

      config.training_set.ids_fenotypes[id1.to_i] = feno1.to_f
      config.training_set.ids_fenotypes[id2.to_i] = feno2.to_f
      config.training_set.ids_fenotypes[id3.to_i] = feno3.to_f
    }
  end

  it "reads testing data and yields one individual at a time" do
    config = Nimbus::Configuration.new
    config.load fixture_file('regression_config.yml')

    test_individuals = []
    File.open(fixture_file('regression_testing.data')) {|file|
      file.each do |line|
        data_id, *snp_list = line.strip.split
        test_individuals << Nimbus::Individual.new(data_id.to_i, nil, snp_list.map{|snp| snp.to_i})
      end
    }
    test_individuals.size.should == 200
    config.read_testing_data{|individual|
      test_individual = test_individuals.shift
      individual.id.should_not be_nil
      individual.id.should == test_individual.id
      individual.snp_list.should_not be_empty
      individual.snp_list.should == test_individual.snp_list
    }
  end

  it "creates a forest object loading data from a yaml file" do
    config = Nimbus::Configuration.new
    config.load fixture_file('regression_config.yml')

    trees = YAML.load(File.open fixture_file('regression_random_forest.yml'))
    trees.first.keys.first.should == 189
    trees.size.should == 3

    forest = config.load_forest
    forest.should be_kind_of Nimbus::Forest
    forest.trees[0].should == trees.first
    forest.trees[1].should == trees[1]
    forest.trees.last.should == trees[2]
  end

end