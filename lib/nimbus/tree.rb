module Nimbus

  #####################################################################
  # Tree object representing a random tree.
  #
  # A tree is generated following this steps:
  #
  # * 1: Calculate loss function for the individuals in the node (first node contains all the individuals).
  # * 2: Take a random sample of the SNPs (size m << total count of SNPs)
  # * 3: Compute the loss function for the split of the sample based on value of every SNP.
  # * 4: If the SNP with minimum loss function also minimizes the general loss of the node, split the individuals sample in three nodes, based on value for that SNP [0, 1, or 2]
  # * 5: Repeat from 1 for every node until:
  #   - a) The individuals count in that node is < minimum size OR
  #   - b) None of the SNP splits has a loss function smaller than the node loss function
  # * 6) When a node stops, label the node with the average fenotype value of the individuals in the node.
  #
  class Tree
    attr_accessor :snp_sample_size, :snp_total_count, :node_min_size, :used_snps, :structure, :generalization_error, :predictions, :importances
    attr_accessor :individuals, :id_to_fenotype

    # Initialize Tree object with the configuration (as in Nimbus::Configuration.tree) options received.
    def initialize(options)
      @snp_total_count = options[:snp_total_count]
      @snp_sample_size = options[:snp_sample_size]
      @node_min_size = options[:tree_node_min_size]
    end

    # Creates the structure of the tree, as a hash of SNP splits and values.
    #
    # It just initializes the needed variables and then defines the first node of the tree.
    # The rest of the structure of the tree is computed recursively building every node calling +build_node+.
    def seed(all_individuals, individuals_sample, ids_fenotypes)
      @individuals = all_individuals
      @id_to_fenotype = ids_fenotypes
      @predictions = {}
      @used_snps = []

      @structure = build_node individuals_sample, Nimbus::LossFunctions.average(individuals_sample, @id_to_fenotype)
    end

    # Creates a node by taking a random sample of the SNPs and computing the loss function for every split by SNP of that sample.
    #
    # * If SNP_min is the SNP with smaller loss function and it is < the loss function of the node, it splits the individuals sample in three:
    # (those with value 0 for the SNP_min, those with value 1 for the SNP_min, and those with value 2 for the SNP_min) then it builds these 3 new nodes.
    # * Otherwise every individual in the node gets labeled with the average of the fenotype values of all of them.
    def build_node(individuals_ids, y_hat)
      # General loss function value for the node
      individuals_count = individuals_ids.size
      return label_node(y_hat, individuals_ids) if individuals_count < @node_min_size
      node_loss_function = Nimbus::LossFunctions.quadratic_loss individuals_ids, @id_to_fenotype, y_hat

      # Finding the SNP that minimizes loss function
      snps = snps_random_sample
      min_loss, min_SNP, split, means = node_loss_function, nil, nil, nil

      snps.each do |snp|
        individuals_split_by_snp_value = split_by_snp_value individuals_ids, snp
        mean_0 = Nimbus::LossFunctions.average individuals_split_by_snp_value[0], @id_to_fenotype
        mean_1 = Nimbus::LossFunctions.average individuals_split_by_snp_value[1], @id_to_fenotype
        mean_2 = Nimbus::LossFunctions.average individuals_split_by_snp_value[2], @id_to_fenotype
        loss_0 = Nimbus::LossFunctions.mean_squared_error individuals_split_by_snp_value[0], @id_to_fenotype, mean_0
        loss_1 = Nimbus::LossFunctions.mean_squared_error individuals_split_by_snp_value[1], @id_to_fenotype, mean_1
        loss_2 = Nimbus::LossFunctions.mean_squared_error individuals_split_by_snp_value[2], @id_to_fenotype, mean_2
        loss_snp = (loss_0 + loss_1 + loss_2) / individuals_count

        min_loss, min_SNP, split, means = loss_snp, snp, individuals_split_by_snp_value, [mean_0, mean_1, mean_2] if loss_snp < min_loss
      end

      return build_branch(min_SNP, split, means, y_hat) if min_loss < node_loss_function
      return label_node(y_hat, individuals_ids)
    end

    # Compute generalization error for the tree.
    #
    # Traversing the 'out of bag' (OOB) sample (those individuals of the training set not
    # used in the building of this tree) through the tree, and comparing
    # the prediction with the real fenotype of the individual (and then averaging) is
    # possible to calculate the unbiased generalization error for the tree.
    def generalization_error_from_oob(oob_ids)
      return nil if (@structure.nil? || @individuals.nil? || @id_to_fenotype.nil?)
      oob_errors = {}
      oob_ids.each do |oobi|
        oob_prediction = Tree.traverse @structure, individuals[oobi].snp_list
        oob_errors[oobi] = Nimbus::LossFunctions.squared_difference oob_prediction, @id_to_fenotype[oobi]
      end
      @generalization_error = Nimbus::LossFunctions.average oob_ids, oob_errors
    end

    # Estimation of importance for every SNP.
    #
    # The importance of any SNP in the tree is calculated using the OOB sample.
    # For every SNP, every individual in the sample is pushed down the tree but with the
    # value of that SNP permuted with other individual in the sample.
    #
    # That way the difference between the regular prediction and the prediction with the SNP value modified can be estimated for any given SNP.
    #
    # This method computes importance estimations for every SNPs used in the tree (for any other SNP it would be 0).
    def estimate_importances(oob_ids)
      return nil if (@generalization_error.nil? && generalization_error_from_oob(oob_ids).nil?)
      oob_individuals_count = oob_ids.size
      @importances = {}
      @used_snps.uniq.each do |current_snp|
        shuffled_ids = oob_ids.shuffle
        permutated_snp_error = 0.0
        oob_ids.each_with_index {|oobi, index|
          permutated_prediction = traverse_with_permutation @structure, individuals[oobi].snp_list, current_snp, individuals[shuffled_ids[index]].snp_list
          permutated_snp_error += Nimbus::LossFunctions.squared_difference @id_to_fenotype[oobi], permutated_prediction
        }
        @importances[current_snp] = ((permutated_snp_error / oob_individuals_count) - @generalization_error).round(5)
      end
      @importances
    end

    # Class method to traverse a single individual through a tree structure.
    #
    # Returns the prediction for that individual (the label of the final node reached by the individual).
    def self.traverse(tree_structure, data)
      return tree_structure if tree_structure.is_a? Numeric
      raise Nimbus::TreeError, "Forest data has invalid structure. Please check your forest data (file)." if !(tree_structure.is_a?(Hash) && tree_structure.keys.size == 1)
      return self.traverse( tree_structure.values.first[ data[tree_structure.keys.first - 1].to_i], data)
    end

    private

    def snps_random_sample
      (1..@snp_total_count).to_a.sample(@snp_sample_size).sort
    end

    def build_branch(snp, split, y_hats, parent_y_hat)
      node_0 = split[0].size == 0 ? label_node(parent_y_hat, []) : build_node(split[0], y_hats[0])
      node_1 = split[1].size == 0 ? label_node(parent_y_hat, []) : build_node(split[1], y_hats[1])
      node_2 = split[2].size == 0 ? label_node(parent_y_hat, []) : build_node(split[2], y_hats[2])

      split_by_snp(snp)
      return { snp => [node_0, node_1, node_2] }
    end

    def label_node(value, ids)
      label = value.round(5)
      ids.uniq.each{|i| @predictions[i] = label}
      label
    end

    def split_by_snp_value(ids, snp)
      split = [[], [], []]
      ids.each do |i|
        split[ @individuals[i].snp_list[snp-1] ] << @individuals[i].id
      end
      split
    rescue => ex
      raise Nimbus::TreeError, "Values for SNPs columns must be in [0, 1, 2]"
    end

    def split_by_snp(x)
      @used_snps << x
    end

    def traverse_with_permutation(tree_structure, data, snp_to_permute, individual_to_permute)
      return tree_structure if tree_structure.is_a? Numeric
      individual_data = (tree_structure.keys.first == snp_to_permute ? individual_to_permute : data)
      return traverse_with_permutation( tree_structure.values.first[ individual_data[tree_structure.keys.first - 1].to_i], data, snp_to_permute, individual_to_permute)
    end

  end

end