module Nimbus
  module LossFunctions
    
    class << self
   
      def average(ids, value_table)
        ids.inject(0.0){|sum, i| sum + value_table[i]} / ids.size
      end

      def mean_squared_error(ids, value_table, mean = nil)
        mean ||= self.average ids, value_table
        ids.inject(0.0){|sum, i| sum + ((value_table[i] - mean)**2) }
      end

      def quadratic_loss(ids, value_table, mean = nil)
        self.mean_squared_error(ids, value_table, mean) / ids.size
      end
      
    end
    
  end
end
    