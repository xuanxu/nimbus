module Nimbus
  
  class Forest
    attr_accessor :size, :trees, :bag, :predictions
    attr_accessor :options
    
    def initialize(config)
      @trees = []
      @options = config
      @size = config.forest_size
      @predictions = {}
      raise Nimbus::ForestError, "Forest size parameter (#{@size}) is invalid. You need at least one tree." if @size < 1
    end
    
    def grow
      @size.times do
        tree_individuals_bag = individuals_random_sample
        tree_out_of_bag = oob tree_individuals_bag
        tree = Tree.new @options.tree
        @trees << tree.seed(@options.training_set.individuals, tree_individuals_bag, @options.training_set.ids_fenotypes)
        acumulate_predictions tree.predictions
      end
      average_predictions
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
      @bag ||= (1..@options.training_set.individuals.size).to_a
    end
    
    def acumulate_predictions(preds)
      preds.each_pair.each{|id, value|
        if @predictions[id].nil?
          @predictions[id] = value
        else
          @predictions[id] += value
        end
      }
    end
    
    def average_predictions
      @predictions.each_pair{|id, value|
        @predictions[id] = (@predictions[id] / @size).round(5)
      }
    end
    
  end
  
end