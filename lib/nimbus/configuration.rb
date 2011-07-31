module Nimbus
  class Configuration
    attr_accessor(
      :training_file,
      :testing_file,
      :forest_file,
      :log_file,
      :forest_size,
      :tree_SNP_sample_size,
      :tree_SNP_total_count,
      :tree_max_branches,
      :tree_node_min_size,
      :loss_function_discrete,
      :loss_function_continuous,
      :do_training,
      :do_testing
    )
    attr_reader :data
    
    def initialize
      # @training_file = 'training'
      # @testing_file  = 'testing'
      # @forest_file  = 'nimbus_random_forest'
      @log_file  = 'nimbus_log.txt'
      @do_training = false
      @do_testing  = false
      
      @forest_size = 500
      @SNP_sample_size = 60
      @SNP_total_count = 200
      @tree_max_branches  = 2000
      @tree_node_min_size = 5
      @loss_function_discrete   = :majority_class
      @loss_function_continuous = :mean
    end
    
    def load(config_file = 'config.yml')
      
      user_config_params = File.exists?(File.expand_path(config_file, Dir.pwd)) ? {} : begin
        YAML.load(File.open(File.expand_path config_file, Dir.pwd))
      rescue ArgumentError => e
        Nimbus.stop "Could not parse #{config_file} (config YAML file): #{e.message}"
      end
      
      if user_config_params['input']
        @training_file = File.expand_path(user_config_params['input']['training'], Dir.pwd) if user_config_params['input']['training']
        @testing_file  = File.expand_path(user_config_params['input']['testing'], Dir.pwd) if user_config_params['input']['testing']
        @forest_file   = File.expand_path(user_config_params['input']['forest'], Dir.pwd) if user_config_params['input']['forest']
      else
        @training_file = File.expand_path('training.data', Dir.pwd) if File.exists? File.expand_path('training.data', Dir.pwd)
        @testing_file  = File.expand_path('testing.data', Dir.pwd)  if File.exists? File.expand_path('testing.data', Dir.pwd)
        @forest_file   = File.expand_path('forest.data', Dir.pwd)   if File.exists? File.expand_path('forest.data', Dir.pwd)
      end
      
      @do_training = true if @training_file
      @do_testing  = true if @testing_file
      
      if user_config_params['forest']
        @forest_size          = user_config_params['forest']['forest_size'].to_i if user_config_params['forest']['forest_size']
        @SNP_total_count      = user_config_params['forest']['number_of_SNPs'].to_i if user_config_params['forest']['number_of_SNPs']
        @tree_SNP_sample_size = user_config_params['forest']['mtry'].to_i  if user_config_params['forest']['sample_size_m']
        @tree_max_branches    = user_config_params['forest']['max_branches'].to_i  if user_config_params['forest']['max_branches']
        @tree_node_min_size   = user_config_params['forest']['node_min_size'].to_i if user_config_params['forest']['node_min_size']
      end
    end
    
  end
end




# 
# def general_options
# end
# 
# def forest
#   {:size => @forest_size}
# end
# 
# def tree
#   { 
#     :SNP_sample_size => @tree_SNP_sample_size,
#     :SNP_total_count => @tree_SNP_total_count,
#     :tree_max_branches => @tree_max_branches,
#     :tree_node_min_size => @tree_node_min_size
#   }
# end