module Nimbus
  
  class Individual
    attr_accessor :id, :fenotype, :prediction, :snp_list
    
    def initialize(i, fen, snps={})
      self.id = i
      self.fenotype = fen
      self.snp_list = snps
    end
  end
  
end