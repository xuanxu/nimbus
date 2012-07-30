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
      ## REGRESSION

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
      
      # Simplified Huber function
      def pseudo_huber_error(ids, value_table, mean = nil)
        mean ||= self.average ids, value_table
        ids.inject(0.0){|sum, i| sum + (Math.log(Math.cosh(value_table[i] - mean))) }
      end

      # Simplified Huber loss function: PHE / n
      def pseudo_huber_loss(ids, value_table, mean = nil)
        self.pseudo_huber_error(ids, value_table, mean) / ids.size
      end

      ## CLASSSIFICATION

      # Gini index of a list of classified individuals.
      #
      # If a dataset T contains examples from n classes, then:
      # gini(T) = 1 - Sum (Pj)^2
      # where Pj is the relative frequency of class j in T
      def gini_index(ids, value_table, classes)
        total_size = ids.size.to_f
        gini = 1 - class_sizes(ids, value_table, classes).inject(0.0){|sum, size|
          sum + (size/total_size)**2}
        gini.round(5)
      end

      # Majority class of a list of classified individuals.
      # If more than one class has the same number of individuals,
      # one of the majority classes is selected randomly.
      def majority_class(ids, value_table, classes)
        sizes = class_sizes(ids, value_table, classes)
        Hash[classes.zip sizes].keep_if{|k,v| v == sizes.max}.keys.sample
      end

      # Majority class of a list of classes.
      # If more than one class has the same number of individuals,
      # one of the majority classes is selected randomly.
      def majority_class_in_list(list, classes)
        sizes = classes.map{|c| list.count{|i| i == c}}
        Hash[classes.zip sizes].keep_if{|k,v| v == sizes.max}.keys.sample
      end

      # Array with the list of sizes of each class in the given list of individuals.
      def class_sizes(ids, value_table, classes)
        classes.map{|c| ids.count{|i| value_table[i] == c}}
      end

      # Array with the list of sizes of each class in the given list of classes.
      def class_sizes_in_list(list, classes)
        classes.map{|c| list.count{|i| i == c}}
      end
    end

  end
end
