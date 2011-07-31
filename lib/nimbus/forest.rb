module Nimbus
  
  class Forest
    attr_accessor :id_fenotype_table, :individuals
    attr_accessor :size, :trees
    attr_accessor :loss_function, :snps_sample_size, :node_min_size, :max_branches
    attr_accessor :options
    
    def initialize(config)
      @trees = []
      @options = config
    end
    
    def data=(individuals_array ,ids_fenotypes = nil)
      @individuals = individuals_array
      @id_fenotype_table = ids_fenotypes
    end
    
    def grow
      @size.times do        
        tree = Tree.new @loss_function, @snps_sample_size, @node_min_size, @max_branches
        @trees << Tree.seed(individuals_random_sample).structure
      end
    end
    
    def to_yaml
      @trees.to_yaml
    end
    
    
    private
    def individuals_random_sample
      bag = (1..@individuals.size).to_a      
      individuals_sample = bag.inject([]){|items, i| items << bag.sample }
    end
    
    
  end
  
end