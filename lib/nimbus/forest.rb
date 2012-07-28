module Nimbus

  #####################################################################
  # Forest represents the Random forest being generated
  # (or used to test samples) by the application object.
  #
  class Forest
    attr_accessor :size, :trees, :bag, :predictions, :tree_errors, :snp_importances
    attr_accessor :options

    # Initialize Forest object with options included in the Nimbus::Configuration object received.
    def initialize(config)
      @trees = []
      @tree_errors = []
      @options = config
      @size = config.forest_size
      @predictions = {}
      @times_predicted = []
      @snp_importances = {}
      @tree_snp_importances = []
      raise Nimbus::ForestError, "Forest size parameter (#{@size}) is invalid. You need at least one tree." if @size < 1
    end

    # Creates a random forest based on the TrainingSet included in the configuration, creating N random trees (size N defined in the configuration).
    #
    # This is the method called when the application's configuration flags training on.
    #
    # It performs this tasks:
    #
    # * grow the forest (all the N random trees)
    # * store generalization errors for every tree
    # * obtain averaged importances for all the SNPs
    # * calculate averaged predictions for all individuals in the training sample
    #
    # Every tree of the forest is created with a different random sample of the individuals in the training set.
    def grow
      @size.times do |i|
        Nimbus.write("\rCreating trees: #{i+1}/#{@size} ")
        tree_individuals_bag = individuals_random_sample
        tree_out_of_bag = oob tree_individuals_bag
        tree_class = (classification? ? ClassificationTree : RegressionTree)
        tree = tree_class.new @options.tree
        @trees << tree.seed(@options.training_set.individuals, tree_individuals_bag, @options.training_set.ids_fenotypes)
        @tree_errors << tree.generalization_error_from_oob(tree_out_of_bag)
        @tree_snp_importances << tree.estimate_importances(tree_out_of_bag) if @options.do_importances
        acumulate_predictions tree.predictions
        Nimbus.clear_line!
      end
      average_snp_importances if @options.do_importances
      totalize_predictions
    end

    # Traverse a testing set through every tree of the forest.
    #
    # This is the method called when the application's configuration flags testing on.
    def traverse
      classification? ? traverse_classification_forest : traverse_regression_forest
    end

    # Traverse a testing set through every regression tree of the forest and get averaged predictions for every individual in the sample.
    def traverse_regression_forest
      @predictions = {}
      prediction_count = trees.size
      @options.read_testing_data{|individual|
        individual_prediction = 0.0
        trees.each do |t|
          individual_prediction = (individual_prediction + Nimbus::Tree.traverse(t, individual.snp_list)).round(5)
        end
        @predictions[individual.id] = (individual_prediction / prediction_count).round(5)
      }
    end

    # Traverse a testing set through every classification tree of the forest and get majority class predictions for every individual in the sample.
    def traverse_classification_forest
      @predictions = {}
      @options.read_testing_data{|individual|
        individual_prediction = []
        trees.each do |t|
          individual_prediction << Nimbus::Tree.traverse(t, individual.snp_list)
        end
        @predictions[individual.id] = Nimbus::LossFunctions.majority_class_in_list(individual_prediction, @options.tree[:classes])
      }
    end

    # The array containing every tree in the forest, to YAML format.
    def to_yaml
      @trees.to_yaml
    end

    private

    def individuals_random_sample
      individuals_sample = bag.inject([]){|items, i| items << bag.sample }.sort
    end

    def oob(in_bag=[])
      bag - in_bag.uniq
    end

    def bag
      @bag ||= @options.training_set.all_ids
    end

    def acumulate_predictions(preds)
      preds.each_pair.each{|id, value|
        if @predictions[id].nil?
          @predictions[id] = (classification? ? [value] : value)
          @times_predicted[id] = 1.0
        else
          classification? ? (@predictions[id] << value) : (@predictions[id] += value)
          @times_predicted[id] += 1
        end
      }
    end

    def totalize_predictions
      classification? ? majority_class_predicted : average_predictions
    end

    def average_predictions
      @predictions.each_pair{|id, value|
        @predictions[id] = (@predictions[id] / @times_predicted[id]).round(5)
      }
    end

    def majority_class_predicted
      @predictions.each_pair{|id, values|
        @predictions[id] = Nimbus::LossFunctions.majority_class_in_list(values, @options.tree[:classes])
      }
    end

    def average_snp_importances
      1.upto(@options.tree_SNP_total_count) {|snp|
        @snp_importances[snp] = 0.0
        @tree_snp_importances.each{|tree_snp_importance|
          @snp_importances[snp] += tree_snp_importance[snp] unless tree_snp_importance[snp].nil?
        }
        @snp_importances[snp] = @snp_importances[snp] / @size
      }
    end

    def classification?
      @options.tree[:classes]
    end

    def regression?
      @options.tree[:classes].nil?
    end

  end

end