module Nimbus
  #####################################################################
  # Nimbus Individual object.
  #
  # It represents a single individual of a training or testing sample.
  #
  # This class stores information about a individual:
  #
  # * id,
  # * values for all the SNPs of the individual,
  # * fenotype if present,
  # * the prediction is it exists.
  #
  class Individual
    attr_accessor :id, :fenotype, :prediction, :snp_list

    # Initialize individual with passed data.
    def initialize(i, fen, snps=[])
      self.id = i
      self.fenotype = fen
      self.snp_list = snps
    end
  end

end