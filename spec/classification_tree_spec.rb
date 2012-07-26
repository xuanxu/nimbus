require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::ClassificationTree do

  before(:each) do
    @config = Nimbus::Configuration.new
    @config.load fixture_file('classification_config.yml')

    @tree = Nimbus::ClassificationTree.new @config.tree
  end

  it "is initialized with tree config info" do
    @tree.snp_total_count.should == 100
    @tree.snp_sample_size.should == 33
    @tree.node_min_size.should   == 5
    @tree.classes.size.should    == 2
    @tree.classes[0].should      == '0'
    @tree.classes[1].should      == '1'
  end

  it "creates a tree structure when seeded with training data" do
    @config.load_training_data
    @tree.structure.should be_nil
    @tree.seed(@config.training_set.individuals, @config.training_set.all_ids, @config.training_set.ids_fenotypes)
    @tree.structure.should_not be_nil
    @tree.structure.should be_kind_of Hash

    @tree.structure.keys.first.should == @tree.used_snps.last
    @tree.used_snps.should_not be_empty
  end

  it "splits node in three when building a node and finds a suitable split" do
    @config.load_training_data
    @tree.stub!(:snps_random_sample).and_return((68..100).to_a) #97 is best split

    @tree.individuals = @config.training_set.individuals
    @tree.id_to_fenotype = @config.training_set.ids_fenotypes
    @tree.used_snps = []
    @tree.predictions = {}

    branch = @tree.build_node @config.training_set.all_ids, Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    branch.keys.size.should == 1
    branch.keys.first.should == 97
    branch[97].size.should == 3
    branch[97][0].should be_kind_of Hash
    branch[97][1].should be_kind_of Hash
    branch[97][2].should be_kind_of Hash
  end

  it "keeps track of all SNPs used for the tree" do
    @config.load_training_data
    snps = (33..65).to_a
    @tree.stub!(:snps_random_sample).and_return(snps)
    @tree.used_snps.should be_nil
    @tree.seed(@config.training_set.individuals, @config.training_set.all_ids, @config.training_set.ids_fenotypes)
    @tree.used_snps.size.should > 4
    @tree.used_snps.each{|snp|
      snps.include?(snp).should be_true
    }
  end

  it "labels node when building a node and there is not a suitable split" do
    @config.load_training_data
    @tree.stub!(:snps_random_sample).and_return([33])

    @tree.individuals = @config.training_set.individuals
    @tree.id_to_fenotype = @config.training_set.ids_fenotypes
    @tree.used_snps = []
    @tree.predictions = {}

    branch = @tree.build_node @config.training_set.all_ids, Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    branch[33][0].should be_kind_of String
    branch[33][1].should be_kind_of String
    branch[33][2].should be_kind_of String
  end

  it "labels node when building a node with less individuals than the minimum node size" do
    @config.load_training_data

    @tree.individuals = @config.training_set.individuals
    @tree.id_to_fenotype = @config.training_set.ids_fenotypes
    @tree.used_snps = []
    @tree.predictions = {}

    label = @tree.build_node [1, 10, 33], Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    label.should be_kind_of String

    label = @tree.build_node [2, 10], Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    label.should be_kind_of String

    label = @tree.build_node [1, 10, 33], Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    label.should be_kind_of String

    label = @tree.build_node [99, 22, 10, 33], Nimbus::LossFunctions.majority_class(@config.training_set.all_ids, @config.training_set.ids_fenotypes, @config.classes)
    label.should be_kind_of String
  end

  it 'computes generalization error for the tree' do
    @config.load_training_data
    @tree.seed(@config.training_set.individuals, @config.training_set.all_ids, @config.training_set.ids_fenotypes)
    @tree.generalization_error.should be_nil
    @tree.generalization_error_from_oob((3..300).to_a)
    @tree.generalization_error.should be_kind_of Numeric
    @tree.generalization_error.should > 0.0
    @tree.generalization_error.should < 1.0
  end

  it 'estimates importance for all SNPs' do
    @config.load_training_data
    @tree.seed(@config.training_set.individuals, @config.training_set.all_ids, @config.training_set.ids_fenotypes)
    @tree.importances.should be_nil
    @tree.estimate_importances((200..533).to_a)
    @tree.importances.should be_kind_of Hash
    @tree.importances.keys.should_not be_empty
    (@tree.importances.keys - (1..100).to_a).should be_empty #all keys are snp indexes (100 snps in training file)
  end

  it 'get prediction for an individual pushing it down a tree structure' do
    tree_structure = YAML.load(File.open fixture_file('classification_random_forest.yml')).first
    individual_data = [0]*100
    prediction = Nimbus::Tree.traverse tree_structure, individual_data
    prediction.should == '1'

    individual_data[26-1] = 1
    individual_data[57-1] = 2
    individual_data[98-1] = 2
    individual_data[8-1]  = 1
    prediction = Nimbus::Tree.traverse tree_structure, individual_data
    prediction.should == '0'
  end

end