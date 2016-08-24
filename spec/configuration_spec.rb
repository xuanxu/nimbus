# encoding: UTF-8
require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::Configuration do

  it "loads configuration options from config file" do
    config = Nimbus::Configuration.new
    config.load fixture_file('regression/config.yml')

    expect(config.training_file).to eq fixture_file('regression/training.data')
    expect(config.testing_file).to eq fixture_file('regression/testing.data')
    expect(config.forest_file).to eq fixture_file('regression/random_forest.yml')
    expect(config.classes).to be_nil
    expect(config.do_importances).to be

    expect(config.forest_size).to eq 3
    expect(config.tree_SNP_sample_size).to eq 60
    expect(config.tree_SNP_total_count).to eq 200
    expect(config.tree_node_min_size).to eq 5

    config = Nimbus::Configuration.new
    config.load fixture_file('classification/config.yml')

    expect(config.training_file).to eq fixture_file('classification/training.data')
    expect(config.testing_file).to eq fixture_file('classification/testing.data')
    expect(config.forest_file).to eq fixture_file('classification/random_forest.yml')
    expect(config.classes).to eq ['0','1']
    expect(config.do_importances).to_not be

    expect(config.forest_size).to eq 3
    expect(config.tree_SNP_sample_size).to eq 33
    expect(config.tree_SNP_total_count).to eq 100
    expect(config.tree_node_min_size).to eq 5
  end

  it 'tree method return tree-related subset of options for regression trees' do
    config = Nimbus::Configuration.new
    config.load fixture_file('regression/config.yml')
    tree_options = config.tree

    expect(tree_options[:snp_sample_size]).to_not be_nil
    expect(tree_options[:snp_total_count]).to_not be_nil
    expect(tree_options[:tree_node_min_size]).to_not be_nil
    expect(tree_options[:classes]).to be_nil
  end

  it 'tree method return tree-related subset of options for classification trees' do
    config = Nimbus::Configuration.new
    config.load fixture_file('classification/config.yml')
    tree_options = config.tree

    expect(tree_options[:snp_sample_size]).to_not be_nil
    expect(tree_options[:snp_total_count]).to_not be_nil
    expect(tree_options[:tree_node_min_size]).to_not be_nil
    expect(tree_options[:classes]).to_not be_nil
  end

  it "creates a training set object from training data file" do
    config = Nimbus::Configuration.new
    config.load fixture_file('regression/config.yml')
    expect(config.training_set).to be_nil
    config.load_training_data
    expect(config.training_set).to be_kind_of Nimbus::TrainingSet
    expect(config.training_set.all_ids.sort).to eq (1..800).to_a

    File.open(fixture_file('regression/training.data')) {|file|
      feno1, id1, *snp_list_1 = file.readline.split
      feno2, id2, *snp_list_2 = file.readline.split
      feno3, id3, *snp_list_3 = file.readline.split

      i1 = Nimbus::Individual.new(id1.to_i, feno1.to_f, snp_list_1.map{|snp| snp.to_i})
      i2 = Nimbus::Individual.new(id2.to_i, feno2.to_f, snp_list_2.map{|snp| snp.to_i})
      i3 = Nimbus::Individual.new(id3.to_i, feno3.to_f, snp_list_3.map{|snp| snp.to_i})

      expect(config.training_set.individuals[id1.to_i].id).to eq i1.id
      expect(config.training_set.individuals[id2.to_i].fenotype).to eq i2.fenotype
      expect(config.training_set.individuals[id3.to_i].snp_list).to eq i3.snp_list

      config.training_set.ids_fenotypes[id1.to_i] = feno1.to_f
      config.training_set.ids_fenotypes[id2.to_i] = feno2.to_f
      config.training_set.ids_fenotypes[id3.to_i] = feno3.to_f
    }
  end

  it "reads testing data and yields one individual at a time" do
    config = Nimbus::Configuration.new
    config.load fixture_file('regression/config.yml')

    test_individuals = []
    File.open(fixture_file('regression/testing.data')) {|file|
      file.each do |line|
        data_id, *snp_list = line.strip.split
        test_individuals << Nimbus::Individual.new(data_id.to_i, nil, snp_list.map{|snp| snp.to_i})
      end
    }
    expect(test_individuals.size).to eq 200
    config.read_testing_data{|individual|
      test_individual = test_individuals.shift
      expect(individual.id).to_not be_nil
      expect(individual.id).to eq test_individual.id
      expect(individual.snp_list).to_not be_empty
      expect(individual.snp_list).to eq test_individual.snp_list
    }
  end

  it "creates a forest object loading data from a yaml file" do
    config = Nimbus::Configuration.new
    config.load fixture_file('regression/config.yml')

    trees = Psych.load(File.open fixture_file('regression/random_forest.yml'))
    expect(trees.first.keys.first).to eq 176
    expect(trees.size).to eq 3

    forest = config.load_forest
    expect(forest).to be_kind_of Nimbus::Forest
    expect(forest.trees[0]).to eq trees.first
    expect(forest.trees[1]).to eq trees[1]
    expect(forest.trees.last).to eq trees[2]
  end

end