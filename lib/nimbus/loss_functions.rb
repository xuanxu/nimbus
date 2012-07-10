# encoding: utf-8
module Nimbus

  #####################################################################
  # Math functions.
  #
  # The LossFunctions class provides handy mathematical functions as class methods
  # to be used by Tree and Forest when estimating predictions, errors and loss functions
  # for training and testing data.
  #
  module LossFunctions

    class << self

      # Simple average: sum(n) / n
      def average(ids, value_table)
        ids.inject(0.0){|sum, i| sum + value_table[i]} / ids.size
      end

      # Mean squared error: sum (x-y)^2
      def mean_squared_error(ids, value_table, mean = nil)
        mean ||= self.average ids, value_table
        ids.inject(0.0){|sum, i| sum + ((value_table[i] - mean)**2) }
      end

      # Quadratic loss: averaged mean squared error: sum (x-y)^2 / n
      #
      # Default loss function for regression forests.
      def quadratic_loss(ids, value_table, mean = nil)
        self.mean_squared_error(ids, value_table, mean) / ids.size
      end

      # Difference between two values, squared. (x-y)^2
      def squared_difference(x,y)
        0.0 + (x-y)**2
      end

    end

  end
end
