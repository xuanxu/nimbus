module Nimbus
  class Configuration
    attr_accessor(
      :training_file,
      :testing_file,
      :forest_file,
      :config_file,
      :forest_size,
      :tree_SNP_sample_size,
      :tree_SNP_total_count,
      :tree_max_branches,
      :tree_node_min_size,
      :loss_function_discrete,
      :loss_function_continuous,
      :do_training,
      :do_testing,
      :training_set,
      :output_forest_file,
      :output_training_file
    )
    
    DEFAULTS = {
      :forest_size          => 500,
      :tree_SNP_sample_size => 60,
      :tree_SNP_total_count => 200,
      :tree_max_branches    => 2000,
      :tree_node_min_size   => 5,
      
      :loss_function_discrete   => 'majority_class',
      :loss_function_continuous => 'mean',
      
      :training_file => 'training.data',
      :testing_file  => 'testing.data',
      :forest_file   => 'forest.yml',
      :config_file   => 'config.yml',
      
      :output_forest_file => 'random_forest.yml',
      :output_training_file => 'training_file_predictions.yml'
    }
    
    
    def initialize
      @do_training = false
      @do_testing  = false
      
      @forest_size              = DEFAULTS[:forest_size]
      @tree_SNP_sample_size     = DEFAULTS[:tree_SNP_sample_size]
      @tree_SNP_total_count     = DEFAULTS[:tree_SNP_total_count]
      @tree_max_branches        = DEFAULTS[:tree_max_branches]
      @tree_node_min_size       = DEFAULTS[:tree_node_min_size]
      @loss_function_discrete   = DEFAULTS[:loss_function_discrete]
      @loss_function_continuous = DEFAULTS[:loss_function_continuous]
      
      @output_forest_file = File.expand_path(DEFAULTS[:output_forest_file], Dir.pwd)
      @output_training_file = File.expand_path(DEFAULTS[:output_training_file], Dir.pwd)
    end
    
    def tree
      { 
        :snp_sample_size => @tree_SNP_sample_size,
        :snp_total_count => @tree_SNP_total_count,
        :tree_max_branches => @tree_max_branches,
        :tree_node_min_size => @tree_node_min_size
      }
    end
    
    def load(config_file = DEFAULTS[:config_file])
      user_config_params = {}
      if File.exists?(File.expand_path(config_file, Dir.pwd))
        begin
          user_config_params = YAML.load(File.open(File.expand_path config_file, Dir.pwd))
        rescue ArgumentError => e
          raise Nimbus::WrongFormatFileError, "It was not posible to parse the config file (#{config_file}): \r\n#{e.message} "
        end
      end
      
      if user_config_params['input']
        @training_file = File.expand_path(user_config_params['input']['training'], Dir.pwd) if user_config_params['input']['training']
        @testing_file  = File.expand_path(user_config_params['input']['testing' ], Dir.pwd) if user_config_params['input']['testing']
        @forest_file   = File.expand_path(user_config_params['input']['forest'  ], Dir.pwd) if user_config_params['input']['forest']
      else
        @training_file = File.expand_path(DEFAULTS[:training_file], Dir.pwd) if File.exists? File.expand_path(DEFAULTS[:training_file], Dir.pwd)
        @testing_file  = File.expand_path(DEFAULTS[:testing_file ], Dir.pwd) if File.exists? File.expand_path(DEFAULTS[:testing_file ], Dir.pwd)
        @forest_file   = File.expand_path(DEFAULTS[:forest_file  ], Dir.pwd) if File.exists? File.expand_path(DEFAULTS[:forest_file  ], Dir.pwd)
      end
      
      @do_training = true if @training_file
      @do_testing  = true if @testing_file
      
      if @do_testing && !@do_training && !@forest_file
        raise Nimbus::InputFileError, "There is not random forest data (training file not defined, and forest file not found)."
      end
      
      if user_config_params['forest']
        @forest_size          = user_config_params['forest']['forest_size'].to_i if user_config_params['forest']['forest_size']
        @tree_SNP_total_count = user_config_params['forest']['SNP_total_count'].to_i if user_config_params['forest']['SNP_total_count']
        @tree_SNP_sample_size = user_config_params['forest']['SNP_sample_size_mtry'].to_i  if user_config_params['forest']['SNP_sample_size_mtry']
        @tree_max_branches    = user_config_params['forest']['max_branches'].to_i  if user_config_params['forest']['max_branches']
        @tree_node_min_size   = user_config_params['forest']['node_min_size'].to_i if user_config_params['forest']['node_min_size']
      end
      
      check_configuration
      log_configuration
    end
    
    def load_training_data
      File.open(@training_file) {|file|
        @training_set = Nimbus::TrainingSet.new({}, {})
        file.each do |line|
          next if line.strip == ''
          data_feno, data_id, *snp_list = line.strip.split
          raise Nimbus::InputFileError, "Individual ##{data_id} from training set has no value for all #{@tree_SNP_total_count} SNPs" unless snp_list.size == @tree_SNP_total_count
          @training_set.individuals[data_id.to_i] = Nimbus::Individual.new(data_id.to_i, data_feno.to_f, snp_list.map{|snp| snp.to_i})
          @training_set.ids_fenotypes[data_id.to_i] = data_feno.to_f
        end
      }
    end
    
    def load_testing_data
    end
    
    def load_forest_data
    end
    
    def check_configuration
      raise Nimbus::ConfigurationError, "The mtry sample size must be smaller than the total SNPs count." if @tree_SNP_sample_size > @tree_SNP_total_count
    end
    
    def log_configuration
      if !@do_training && !@do_testing
        Nimbus.message "*" * 50
        Nimbus.message "* Nimbus could not find any input file: "
        Nimbus.message "*   No training file (default: training.data)"
        Nimbus.message "*   No testing file (default: testing.data)"
        Nimbus.message "*   Not defined in config file (default: config.yml)"
        Nimbus.message "* Nothing to do."
        Nimbus.message "*" * 50
        Nimbus.stop "Error: No input data. Nimbus finished."
      end
      
      Nimbus.message "*" * 50
      Nimbus.message "* Nimbus configured with the following parameters: "
      Nimbus.message "*   Forest size: #{@forest_size} trees"
      Nimbus.message "*   Total SNP count: #{@tree_SNP_total_count}"
      Nimbus.message "*   SNPs sample size (mtry): #{@tree_SNP_sample_size}"
      Nimbus.message "*   Maximum number of branches per tree: #{@tree_max_branches}"
      Nimbus.message "*   Minimun node size in tree: #{@tree_node_min_size}"
      Nimbus.message "*" * 50
      
      if @do_training
        Nimbus.message "* Training data:"
        Nimbus.message "*   Training file: #{@training_file}"
        Nimbus.message "*" * 50
      end
      
      if @do_testing
        Nimbus.message "* Data to be tested:"
        Nimbus.message "*   Testing file: #{@testing_file}"
        if @forest_file && !@do_training
          Nimbus.message "* using the structure of the random forest stored in:" 
          Nimbus.message "*   Random forest file: #{@forest_file}"
        end
        Nimbus.message "*" * 50
      end
    end
    
  end
end