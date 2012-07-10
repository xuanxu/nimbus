module Nimbus
  #####################################################################
  # Set of individuals to be used as training sample for a random forest.
  #
  # the TrainingSet class stores an array of individuals, and a hash with the fenotypes of every individual indexed by id.
  #
  class TrainingSet
    attr_accessor :individuals, :ids_fenotypes

    # Initialize a new training set with the individuals and fenotype info received.
    def initialize(individuals, ids_fenotypes)
      @individuals   = individuals
      @ids_fenotypes = ids_fenotypes
    end

    # Array of all the ids of the individuals in this training sample.
    def all_ids
      @all_ids ||= @ids_fenotypes.keys
      @all_ids
    end
  end

end