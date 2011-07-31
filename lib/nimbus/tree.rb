module Nimbus
  
  class Tree
    attr_accessor :loss_function, :snps_sample_size, :node_min_size, :max_branches, :structure
    attr_accessor :individuals, :id_fenotypes_table
    
    def initialize(loss, snps_n, node_min, branch_limit)
      @loss_function = loss
      @snps_sample_size = snps_n
      @node_min_size = node_min
      @max_branches = branch_limit
    end
    
    def seed(sample, ids_fenotypes)
      @individuals = sample
      @id_fenotypes_table = ids_fenotypes
    end
    
    def structure
      @structure ||= build_tree
    end
    
    def build_tree
      
    end
    
    
    
    
    
    
    
    
    def traverse
      
    end
    
    def self.traverse(structure, data)
      
    end
    
  end
  
end