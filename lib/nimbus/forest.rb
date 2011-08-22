module Nimbus
  
  class Forest
    attr_accessor :size, :trees, :bag, :predictions, :tree_errors
    attr_accessor :options
    
    def initialize(config)
      @trees = []
      @tree_errors = []
      @options = config
      @size = config.forest_size
      @predictions = {}
      @times_predicted =[]
      raise Nimbus::ForestError, "Forest size parameter (#{@size}) is invalid. You need at least one tree." if @size < 1
    end
    
    def grow
      @size.times do |i|
        Nimbus.write("Creating trees: #{i+1}/#{@size} ")
        tree_individuals_bag = individuals_random_sample
        tree_out_of_bag = oob tree_individuals_bag
        tree = Tree.new @options.tree
        @trees << tree.seed(@options.training_set.individuals, tree_individuals_bag, @options.training_set.ids_fenotypes)
        @tree_errors << tree.generalization_error_from_oob(tree_out_of_bag)
        acumulate_predictions tree.predictions
        Nimbus.clear_line!
      end
      average_predictions
    end
    
    def traverse
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
          @predictions[id] = value
          @times_predicted[id] = 1.0
        else
          @predictions[id] += value
          @times_predicted[id] += 1
        end
      }
    end
    
    def average_predictions
      @predictions.each_pair{|id, value|
        @predictions[id] = (@predictions[id] / @times_predicted[id]).round(5)
      }
    end
    
  end
  
end