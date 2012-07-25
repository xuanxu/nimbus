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
      # REGRESSION

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

      # CLASSSIFICATION

      # Majority class of a list of classified individuals.
      # If more than one class has the same number of individuals, 
      # one of the majority classes is selected randomly.
      def majority_class(ids, value_table, classes)
        sizes = class_sizes(ids, value_table, classes)
        majority_classes = Hash[classes.zip sizes].keep_if{|k,v| v == sizes.max}.keys.sample
      end

      def group_by_class(ids, value_table, classes)
        ids.group_by{|i| value_table[i] if classes.include? value_table[i]}
      end

      def class_sizes(ids, value_table, classes)
        classes.map{|c| ids.count{|i| value_table[i] == c}}
      end
    end

  end
end
