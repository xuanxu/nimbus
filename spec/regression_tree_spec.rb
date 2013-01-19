require File.dirname(__FILE__) + '/spec_helper'

describe Nimbus::RegressionTree do

  before(:each) do
    @config = Nimbus::Configuration.new
    @config.load fixture_file('regression_config.yml')

    @tree = Nimbus::RegressionTree.new @config.tree
  end

  it "is initialized with tree config info" do
    @tree.snp_total_count.should == 200
    @tree.snp_sample_size.should == 60
    @tree.node_min_size.should   == 5
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

  it "split node when building a node and finds a suitable split" do
    @config.load_training_data
    @tree.stub!(:snps_random_sample).and_return((141..200).to_a) #189 is best split

    @tree.individuals = @config.training_set.individuals
    @tree.id_to_fenotype = @config.training_set.ids_fenotypes
    @tree.used_snps = []
    @tree.predictions = {}

    branch = @tree.build_node @config.training_set.all_ids, Nimbus::LossFunctions.average(@config.training_set.all_ids, @config.training_set.ids_fenotypes)
    branch.keys.size.should == 1
    branch.keys.first.should == 189
    branch[189].size.should == 3
    branch[189][0].should be_kind_of Hash
    [Nimbus::Tree::NODE_SPLIT_01_2, Nimbus::Tree::NODE_SPLIT_0_12].should include(branch[189][1])
    branch[189][2].should be_kind_of Hash
  end

  it "keeps track of all SNPs used for the tree" do
    @config.load_training_data
    snps = (131..190).to_a
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
    @tree.stub!(:snps_random_sample).and_return([91])

    @tree.individuals = @config.training_set.individuals
    @tree.id_to_fenotype = @config.training_set.ids_fenotypes
    @tree.used_snps = []
    @tree.predictions = {}

    branch = @tree.build_node @config.training_set.all_ids, Nimbus::LossFunctions.average(@config.training_set.all_ids, @config.training_set.ids_fenotypes)
    branch[91][0].should be_kind_of Numeric
    [Nimbus::Tree::NODE_SPLIT_01_2, Nimbus::Tree::NODE_SPLIT_0_12].should include(branch[91][1])
    branch[91][2].should be_kind_of Numeric
  end

  it "labels node when building a node with less individuals than the minimum node size" do
    @config.load_training_data

    @tree.individuals = @config.training_set.individuals
    @tree.id_to_fenotype = @config.training_set.ids_fenotypes
    @tree.used_snps = []
    @tree.predictions = {}

    label = @tree.build_node [1, 10, 33], Nimbus::LossFunctions.average(@config.training_set.all_ids, @config.training_set.ids_fenotypes)
    label.should be_kind_of Numeric

    label = @tree.build_node [2, 10], Nimbus::LossFunctions.average(@config.training_set.all_ids, @config.training_set.ids_fenotypes)
    label.should be_kind_of Numeric

    label = @tree.build_node [1, 10, 33], Nimbus::LossFunctions.average(@config.training_set.all_ids, @config.training_set.ids_fenotypes)
    label.should be_kind_of Numeric

    label = @tree.build_node [108, 22, 10, 33], Nimbus::LossFunctions.average(@config.training_set.all_ids, @config.training_set.ids_fenotypes)
    label.should be_kind_of Numeric
  end

  it 'computes generalization error for the tree' do
    @config.load_training_data
    @tree.seed(@config.training_set.individuals, @config.training_set.all_ids, @config.training_set.ids_fenotypes)
    @tree.generalization_error.should be_nil
    @tree.generalization_error_from_oob((2..200).to_a)
    @tree.generalization_error.should be_kind_of Numeric
    @tree.generalization_error.should > 0.0
    @tree.generalization_error.should < 1.0
  end

  it 'estimates importance for all SNPs' do
    @config.load_training_data
    @tree.seed(@config.training_set.individuals, @config.training_set.all_ids, @config.training_set.ids_fenotypes)
    @tree.importances.should be_nil
    @tree.estimate_importances((300..533).to_a)
    @tree.importances.should be_kind_of Hash
    @tree.importances.keys.should_not be_empty
    (@tree.importances.keys - (1..200).to_a).should be_empty #all keys are snp indexes (200 snps in training file)
  end

  it 'get prediction for an individual pushing it down a tree structure' do
    tree_structure = Psych.load(File.open fixture_file('regression_random_forest.yml')).first
    individual_data = [0]*200
    prediction = Nimbus::Tree.traverse tree_structure, individual_data
    prediction.should == -0.90813

    individual_data[44-1] = 2
    individual_data[98-1] = 1
    individual_data[22-1] = 1
    individual_data[31-1] = 2
    prediction = Nimbus::Tree.traverse tree_structure, individual_data
    prediction.should == -0.95805
  end

end