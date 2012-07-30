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
  # * 6) When a node stops, label the node with the average fenotype value (for regression problems) or the majority class (for classification problems) of the individuals in the node.
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
    end

    # Creates a node by taking a random sample of the SNPs and computing the loss function for every split by SNP of that sample.
    def build_node(individuals_ids, y_hat)
    end

    # Compute generalization error for the tree.
    def generalization_error_from_oob(oob_ids)
    end

    # Estimation of importance for every SNP.
    def estimate_importances(oob_ids)
    end

    # Class method to traverse a single individual through a tree structure.
    #
    # Returns the prediction for that individual (the label of the final node reached by the individual).
    def self.traverse(tree_structure, data)
      return tree_structure if tree_structure.is_a?(Numeric) || tree_structure.is_a?(String)
      raise Nimbus::TreeError, "Forest data has invalid structure. Please check your forest data (file)." if !(tree_structure.is_a?(Hash) && tree_structure.keys.size == 1)
      return self.traverse( tree_structure.values.first[ data[tree_structure.keys.first - 1].to_i], data)
    end

    protected

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
      label = value.is_a?(String) ? value : value.round(5)
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

    def split_by_value(ids, snp, value)
      split = [[], []]
      ids.each do |i|
        @individuals[i].snp_list[snp-1] > value ? (split[1] << @individuals[i].id) : (split[0] << @individuals[i].id)
      end
      split
    rescue => ex
      raise Nimbus::TreeError, "Values for SNPs columns must be numeric"
    end

    def split_by_snp(x)
      @used_snps << x
    end

    def traverse_with_permutation(tree_structure, data, snp_to_permute, individual_to_permute)
      return tree_structure if tree_structure.is_a?(Numeric) || tree_structure.is_a?(String)
      individual_data = (tree_structure.keys.first == snp_to_permute ? individual_to_permute : data)
      return traverse_with_permutation( tree_structure.values.first[ individual_data[tree_structure.keys.first - 1].to_i], data, snp_to_permute, individual_to_permute)
    end

  end

end