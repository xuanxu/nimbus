module Nimbus

  #####################################################################
  # Tree object representing a random classification tree.
  #
  # A tree is generated following this steps:
  #
  # * 1: Calculate loss function for the individuals in the node (first node contains all the individuals).
  # * 2: Take a random sample of the SNPs (size m << total count of SNPs)
  # * 3: Compute the loss function (default: gini index) for the split of the sample based on value of every SNP.
  # * 4: If the SNP with minimum loss function also minimizes the general loss of the node, split the individuals sample in three nodes, based on value for that SNP [0, 1, or 2]
  # * 5: Repeat from 1 for every node until:
  #   - a) The individuals count in that node is < minimum size OR
  #   - b) None of the SNP splits has a loss function smaller than the node loss function
  # * 6) When a node stops, label the node with the majority class in the node.
  #
  class ClassificationTree < Tree
    attr_accessor :classes

    # Initialize Tree object with the configuration (as in Nimbus::Configuration.tree) options received.
    def initialize(options)
      @classes = options[:classes]
      super
    end

    # Creates the structure of the tree, as a hash of SNP splits and values.
    #
    # It just initializes the needed variables and then defines the first node of the tree.
    # The rest of the structure of the tree is computed recursively building every node calling +build_node+.
    def seed(all_individuals, individuals_sample, ids_fenotypes)
      super
      @structure = build_node individuals_sample, Nimbus::LossFunctions.majority_class(individuals_sample, @id_to_fenotype, @classes)
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
      node_loss_function = Nimbus::LossFunctions.gini_index individuals_ids, @id_to_fenotype, @classes

      # Finding the SNP that minimizes loss function
      snps = snps_random_sample
      min_loss, min_SNP, split, ginis = node_loss_function, nil, nil, nil

      snps.each do |snp|
        individuals_split_by_snp_value = split_by_snp_value individuals_ids, snp
        y_hat_0 = Nimbus::LossFunctions.majority_class(individuals_split_by_snp_value[0], @id_to_fenotype, @classes)
        y_hat_1 = Nimbus::LossFunctions.majority_class(individuals_split_by_snp_value[1], @id_to_fenotype, @classes)
        y_hat_2 = Nimbus::LossFunctions.majority_class(individuals_split_by_snp_value[2], @id_to_fenotype, @classes)
        
        gini_0 = Nimbus::LossFunctions.gini_index individuals_split_by_snp_value[0], @id_to_fenotype, @classes
        gini_1 = Nimbus::LossFunctions.gini_index individuals_split_by_snp_value[1], @id_to_fenotype, @classes
        gini_2 = Nimbus::LossFunctions.gini_index individuals_split_by_snp_value[2], @id_to_fenotype, @classes
        loss_snp = (individuals_split_by_snp_value[0].size * gini_0 +
                    individuals_split_by_snp_value[1].size * gini_1 + 
                    individuals_split_by_snp_value[2].size * gini_2) / individuals_count

        min_loss, min_SNP, split, ginis = loss_snp, snp, individuals_split_by_snp_value, [y_hat_0, y_hat_1, y_hat_2] if loss_snp < min_loss
      end
      return build_branch(min_SNP, split, ginis, y_hat) if min_loss < node_loss_function
      return label_node(y_hat, individuals_ids)
    end

    # Compute generalization error for the tree.
    #
    # Traversing the 'out of bag' (OOB) sample (those individuals of the training set not
    # used in the building of this tree) through the tree, and comparing
    # the prediction with the real fenotype class of the individual is possible
    # to calculate the error frequency, an unbiased generalization error for the tree.
    def generalization_error_from_oob(oob_ids)
      return nil if (@structure.nil? || @individuals.nil? || @id_to_fenotype.nil?)
      oob_errors = 0.0
      oob_ids.each do |oobi|
        oob_errors += 1 unless @id_to_fenotype[oobi] == Tree.traverse(@structure, individuals[oobi].snp_list)
      end
      @generalization_error = oob_errors / oob_ids.size
    end

    # Estimation of importance for every SNP.
    #
    # The importance of any SNP in the tree is calculated using the OOB sample.
    # For every SNP, every individual in the sample is pushed down the tree but with the
    # value of that SNP permuted with other individual in the sample.
    #
    # That way the difference between the generalization error and the error frequency with the SNP value modified can be estimated for any given SNP.
    #
    # This method computes importance estimations for every SNPs used in the tree (for any other SNP it would be 0).
    def estimate_importances(oob_ids)
      return nil if (@generalization_error.nil? && generalization_error_from_oob(oob_ids).nil?)
      oob_individuals_count = oob_ids.size
      @importances = {}
      @used_snps.uniq.each do |current_snp|
        shuffled_ids = oob_ids.shuffle
        permutated_snp_errors = 0.0
        oob_ids.each_with_index {|oobi, index|
          permutated_prediction = traverse_with_permutation @structure, individuals[oobi].snp_list, current_snp, individuals[shuffled_ids[index]].snp_list
          permutated_snp_errors += 1 unless @id_to_fenotype[oobi] == permutated_prediction
        }
        @importances[current_snp] = ((permutated_snp_errors / oob_individuals_count) - @generalization_error).round(5)
      end
      @importances
    end

  end

end