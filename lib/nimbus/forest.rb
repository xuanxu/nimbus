module Nimbus
  
  class Forest
    attr_accessor :size, :trees
    attr_accessor :options
    
    def initialize(config)
      @trees = []
      @options = config
      @size = config.forest_size
      raise Nimbus::ForestError, "Forest size parameter (#{@size}) is invalid. You need at least one tree." if @size < 1
    end
    
    def grow
      i=0
      @size.times do
        i+=1
        tree = Tree.new @options.tree
        @trees << tree.seed(@options.training_set.individuals, individuals_random_sample, @options.training_set.ids_fenotypes)
        #OOB << Tree.traverse OOB por el tree.
      end
    end
    
    def to_yaml
      @trees.to_yaml
    end
    
    
    private
    
    def individuals_random_sample
      bag = (1..@options.training_set.individuals.size).to_a
      individuals_sample = bag.inject([]){|items, i| items << bag.sample }.sort
    end
    
  end
  
end