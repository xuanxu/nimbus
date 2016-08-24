require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::ClassificationTree do

  before(:each) do
    @config = Nimbus::Configuration.new
    @config.load fixture_file('classification/config.yml')

    @tree = Nimbus::ClassificationTree.new @config.tree
  end

  it "is initialized with tree config info" do
    expect(@tree.snp_total_count).to eq 100
    expect(@tree.snp_sample_size).to eq 33
    expect(@tree.node_min_size).to eq 5
    expect(@tree.classes.size).to eq 2
    expect(@tree.classes[0]).to eq '0'
    expect(@tree.classes[1]).to eq '1'
  end

  it "creates a tree structure when seeded with training data" do
    @config.load_training_data
    expect(@tree.structure).to be_nil
    @tree.seed(@config.training_set.individuals, @config.training_set.all_ids, @config.training_set.ids_fenotypes)
    expect(@tree.structure).to_not be_nil
    expect(@tree.structure).to be_kind_of Hash

    expect(@tree.structure.keys.first).to eq @tree.used_snps.last
    expect(@tree.used_snps).to_not be_empty
  end

  it "splits node when building a node and finds a suitable split" do
    @config.load_training_data
    allow_any_instance_of(Nimbus::ClassificationTree).to receive(:snps_random_sample).and_return((68..100).to_a) #97 is best split

    @tree.individuals = @config.training_set.individuals
    @tree.id_to_fenotype = @config.training_set.ids_fenotypes
    @tree.used_snps = []
    @tree.predictions = {}

    branch = @tree.build_node @config.training_set.all_ids, Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    expect(branch.keys.size).to eq 1
    expect(branch.keys.first).to eq 97
    expect(branch[97].size).to eq 3
    expect(branch[97][0]).to be_kind_of Hash
    expect([Nimbus::Tree::NODE_SPLIT_01_2, Nimbus::Tree::NODE_SPLIT_0_12]).to include(branch[97][1])
    expect(branch[97][2]).to be_kind_of Hash
  end

  it "keeps track of all SNPs used for the tree" do
    @config.load_training_data
    snps = (33..65).to_a
    allow_any_instance_of(Nimbus::ClassificationTree).to receive(:snps_random_sample).and_return(snps)
    expect(@tree.used_snps).to be_nil
    @tree.seed(@config.training_set.individuals, @config.training_set.all_ids, @config.training_set.ids_fenotypes)
    expect(@tree.used_snps.size).to be > 4
    @tree.used_snps.each{|snp|
      expect(snps.include?(snp)).to be true
    }
  end

  it "labels node when building a node and there is not a suitable split" do
    @config.load_training_data
    allow_any_instance_of(Nimbus::ClassificationTree).to receive(:snps_random_sample).and_return([11])

    @tree.individuals = @config.training_set.individuals
    @tree.id_to_fenotype = @config.training_set.ids_fenotypes
    @tree.used_snps = []
    @tree.predictions = {}

    branch = @tree.build_node @config.training_set.all_ids, Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    expect(branch[11][0]).to be_kind_of String
    expect(branch[11][1]).to be_kind_of String
    expect(branch[11][2]).to be_kind_of String
  end

  it "labels node when building a node with less individuals than the minimum node size" do
    @config.load_training_data

    @tree.individuals = @config.training_set.individuals
    @tree.id_to_fenotype = @config.training_set.ids_fenotypes
    @tree.used_snps = []
    @tree.predictions = {}

    label = @tree.build_node [1, 10, 33], Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    expect(label).to be_kind_of String

    label = @tree.build_node [2, 10], Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    expect(label).to be_kind_of String

    label = @tree.build_node [1, 10, 33], Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    expect(label).to be_kind_of String

    label = @tree.build_node [99, 22, 10, 33], Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    expect(label).to be_kind_of String
  end

  it 'computes generalization error for the tree' do
    @config.load_training_data
    @tree.seed(@config.training_set.individuals, @config.training_set.all_ids, @config.training_set.ids_fenotypes)
    expect(@tree.generalization_error).to be_nil
    @tree.generalization_error_from_oob((3..300).to_a)
    expect(@tree.generalization_error).to be_kind_of Numeric
    expect(@tree.generalization_error).to be > 0.0
    expect(@tree.generalization_error).to be < 1.0
  end

  it 'estimates importance for all SNPs' do
    @config.load_training_data
    @tree.seed(@config.training_set.individuals, @config.training_set.all_ids, @config.training_set.ids_fenotypes)
    expect(@tree.importances).to be_nil
    @tree.estimate_importances((200..533).to_a)
    expect(@tree.importances).to be_kind_of Hash
    expect(@tree.importances.keys).to_not be_empty
    expect((@tree.importances.keys - (1..100).to_a)).to be_empty #all keys are snp indexes (100 snps in training file)
  end

  it 'get prediction for an individual pushing it down a tree structure' do
    tree_structure = Psych.load(File.open fixture_file('classification/random_forest.yml')).first
    individual_data = [0]*100
    prediction = Nimbus::Tree.traverse tree_structure, individual_data
    expect(prediction).to eq '0'

    individual_data[8-1]  = 2
    individual_data[29-1] = 0
    individual_data[1-1]  = 1
    individual_data[7-1]  = 1
    prediction = Nimbus::Tree.traverse tree_structure, individual_data
    expect(prediction).to eq '1'
  end

end