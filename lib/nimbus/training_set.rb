module Nimbus
  
  class TrainingSet
    attr_accessor :individuals, :ids_fenotypes
    
    def initialize(individuals, ids_fenotypes)
      @individuals   = individuals
      @ids_fenotypes = ids_fenotypes
    end
  end
  
end