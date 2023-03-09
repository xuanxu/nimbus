module Nimbus
  #####################################################################
  # Nimbus configuration object.
  #
  # This class reads every user file.
  # Once the user's config.yml file is loaded, a set of default and
  # custom options is created and stored.
  #
  # Nimbus::Configuration also reads the testing files and the data
  # to create the training set to be passed to the Nimbus::Forest random
  # forest generator and the Nimbus::Tree classes in it.
  #
  class Configuration
    attr_accessor(
      :training_file,
      :testing_file,
      :forest_file,
      :classes,
      :config_file,
      :forest_size,
      :tree_SNP_sample_size,
      :tree_SNP_total_count,
      :tree_node_min_size,
      :loss_function_discrete,
      :loss_function_continuous,
      :do_training,
      :do_testing,
      :do_importances,
      :training_set,
      :output_forest_file,
      :output_training_file,
      :output_testing_file,
      :output_tree_errors_file,
      :output_snp_importances_file,
      :silent
    )

    DEFAULTS = {
      forest_size:          300,
      tree_SNP_sample_size: 60,
      tree_SNP_total_count: 200,
      tree_node_min_size:   5,

      loss_function_discrete:   'majority_class',
      loss_function_continuous: 'average',

      training_file: 'training.data',
      testing_file:  'testing.data',
      forest_file:   'forest.yml',
      config_file:   'config.yml',

      output_forest_file:   'random_forest.yml',
      output_training_file: 'training_file_predictions.txt',
      output_testing_file:  'testing_file_predictions.txt',
      output_tree_errors_file: 'generalization_errors.txt',
      output_snp_importances_file: 'snp_importances.txt',

      silent: false
    }

    # Initialize a Nimbus::Configuration object.
    #
    # Set all options to their default values.
    def initialize
      @do_training = false
      @do_testing  = false
      @do_importances = true

      @forest_size              = DEFAULTS[:forest_size]
      @tree_SNP_sample_size     = DEFAULTS[:tree_SNP_sample_size]
      @tree_SNP_total_count     = DEFAULTS[:tree_SNP_total_count]
      @tree_node_min_size       = DEFAULTS[:tree_node_min_size]
      @loss_function_discrete   = DEFAULTS[:loss_function_discrete]
      @loss_function_continuous = DEFAULTS[:loss_function_continuous]

      @output_forest_file   = File.expand_path(DEFAULTS[:output_forest_file], Dir.pwd)
      @output_training_file = File.expand_path(DEFAULTS[:output_training_file], Dir.pwd)
      @output_testing_file  = File.expand_path(DEFAULTS[:output_testing_file], Dir.pwd)
      @output_tree_errors_file  = File.expand_path(DEFAULTS[:output_tree_errors_file], Dir.pwd)
      @output_snp_importances_file = File.expand_path(DEFAULTS[:output_snp_importances_file], Dir.pwd)

      @silent = ENV['nimbus_test'] == 'running_nimbus_tests' ? true : DEFAULTS[:silent]
    end

    # Accessor method for the tree-related subset of options.
    def tree
      {
        snp_sample_size: @tree_SNP_sample_size,
        snp_total_count: @tree_SNP_total_count,
        tree_node_min_size: @tree_node_min_size,
        classes: @classes
      }
    end

    # This is the first method to be called on Configuration when a config.yml file
    # exists with user input options for the forest.
    #
    # * The method will read the config file and change the default value of the selected options.
    # * Then based on the options and the existence of training, testing and forest files, it will mark:
    #   - if training is needed,
    #   - if testing is needed,
    #   - which forest will be used for the testing.
    # * Finally it will run basic checks on the input data trying to prevent future program errors.
    #
    def load(config_file = DEFAULTS[:config_file])
      user_config_params = {}
      dirname = Dir.pwd
      if File.exist?(File.expand_path(config_file, Dir.pwd))
        begin
          config_file_path = File.expand_path config_file, Dir.pwd
          user_config_params = Psych.load(File.open(config_file_path))
          dirname = File.dirname config_file_path
        rescue ArgumentError => e
          raise Nimbus::WrongFormatFileError, "It was not posible to parse the config file (#{config_file}): \r\n#{e.message} "
        end
      end

      if user_config_params['input']
        @training_file = File.expand_path(user_config_params['input']['training'], dirname) if user_config_params['input']['training']
        @testing_file  = File.expand_path(user_config_params['input']['testing' ], dirname) if user_config_params['input']['testing']
        @forest_file   = File.expand_path(user_config_params['input']['forest'  ], dirname) if user_config_params['input']['forest']
        @classes       = user_config_params['input']['classes'] if user_config_params['input']['classes']
      else
        @training_file = File.expand_path(DEFAULTS[:training_file], Dir.pwd) if File.exist? File.expand_path(DEFAULTS[:training_file], Dir.pwd)
        @testing_file  = File.expand_path(DEFAULTS[:testing_file ], Dir.pwd) if File.exist? File.expand_path(DEFAULTS[:testing_file ], Dir.pwd)
        @forest_file   = File.expand_path(DEFAULTS[:forest_file  ], Dir.pwd) if File.exist? File.expand_path(DEFAULTS[:forest_file  ], Dir.pwd)
      end

      @do_training = true unless @training_file.nil?
      @do_testing  = true unless @testing_file.nil?
      @classes = @classes.map{|c| c.to_s.strip} if @classes

      if @do_testing && !@do_training && !@forest_file
        raise Nimbus::InputFileError, "There is not random forest data (training file not defined, and forest file not found)."
      end

      if user_config_params['forest']
        @forest_size          = user_config_params['forest']['forest_size'].to_i if user_config_params['forest']['forest_size']
        @tree_SNP_total_count = user_config_params['forest']['SNP_total_count'].to_i if user_config_params['forest']['SNP_total_count']
        @tree_SNP_sample_size = user_config_params['forest']['SNP_sample_size_mtry'].to_i  if user_config_params['forest']['SNP_sample_size_mtry']
        @tree_node_min_size   = user_config_params['forest']['node_min_size'].to_i if user_config_params['forest']['node_min_size']
        @do_importances       = user_config_params['forest']['var_importances'].to_s.strip.downcase
        @do_importances       = (@do_importances != 'no' && @do_importances != 'false')
      end

      check_configuration
      log_configuration
    end

    # The method reads the training file, and if the data is valid, creates a Nimbus::TrainingSet
    # containing every individual to be used as training sample for a random forest.
    def load_training_data
      File.open(@training_file) {|file|
        @training_set = Nimbus::TrainingSet.new({}, {})
        file.each do |line|
          next if line.strip == ''
          data_feno, data_id, *snp_list = line.strip.split
          raise Nimbus::InputFileError, "Individual ##{data_id} from training set has no value for all #{@tree_SNP_total_count} SNPs" unless snp_list.size == @tree_SNP_total_count
          raise Nimbus::InputFileError, "There are individuals with no ID, please check data in training file." unless (!data_id.nil? && data_id.strip != '')
          raise Nimbus::InputFileError, "Individual ##{data_id} has no fenotype value, please check data in training file." unless (!data_feno.nil? && data_feno.strip != '')
          raise Nimbus::InputFileError, "Individual ##{data_id} has invalid class (not in [#{classes*', '}]), please check data in training file." unless (@classes.nil? || @classes.include?(data_feno))

          data_feno = (@classes ? data_feno.to_s : data_feno.to_f)
          @training_set.individuals[data_id.to_i] = Nimbus::Individual.new(data_id.to_i, data_feno, snp_list.map{|snp| snp.to_i})
          @training_set.ids_fenotypes[data_id.to_i] = data_feno
        end
      }
    end

    # Reads the testing file, and if the data is valid, yields one Nimbus::Individual at a time.
    def read_testing_data
      File.open(@testing_file) {|file|
        file.each do |line|
          next if line.strip == ''
          data_id, *snp_list = line.strip.split
          raise Nimbus::InputFileError, "There are individuals with no ID, please check data in Testing file." unless (!data_id.nil? && data_id.strip != '')
          raise Nimbus::InputFileError, "Individual ##{data_id} from testing set has no value for all #{@tree_SNP_total_count} SNPs." unless snp_list.size == @tree_SNP_total_count
          individual_test = Nimbus::Individual.new(data_id.to_i, nil, snp_list.map{|snp| snp.to_i})
          yield individual_test
        end
      }
    end

    # Creates a Nimbus::Forest object from a user defined random forest data file.
    #
    # The format of the input file should be the same as the forest output data of a Nimbus Application.
    def load_forest
      trees = []
      if File.exist?(@forest_file)
        begin
          trees = Psych.load(File.open @forest_file)
        rescue ArgumentError => e
          raise Nimbus::WrongFormatFileError, "It was not posible to parse the random forest file (#{@forest_file}): \r\n#{e.message} "
        end
      else
        raise Nimbus::InputFileError, "Forest file not found (#{@forest_file})"
      end
      forest = Nimbus::Forest.new self
      forest.trees = trees
      forest
    end

    # Include tests to be passed by the info contained in the config file.
    #
    # If some of the configuration data provided by the user is invalid, an error is raised and execution stops.
    def check_configuration
      raise Nimbus::ConfigurationError, "The mtry sample size must be smaller than the total SNPs count." if @tree_SNP_sample_size > @tree_SNP_total_count
    end

    # Prints the information stored in the Nimbus::Configuration object
    #
    # It could include errors on the configuration input data, training related info and/or testing related info.
    def log_configuration
      return if @silent
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
      Nimbus.message "* Nimbus version #{::Nimbus::VERSION}"
      Nimbus.message "* configured with the following parameters: "
      Nimbus.message "*   Forest size: #{@forest_size} trees"
      Nimbus.message "*   Total SNP count: #{@tree_SNP_total_count}"
      Nimbus.message "*   SNPs sample size (mtry): #{@tree_SNP_sample_size}"
      Nimbus.message "*   Minimun node size in tree: #{@tree_node_min_size}"

      if @classes
        Nimbus.message "*   Mode: CLASSIFICATION"
        Nimbus.message "*     Classes: [#{@classes*', '}]"
      else
        Nimbus.message "*   Mode: REGRESSION"
      end
      Nimbus.message "*" * 50

      if @do_training
        Nimbus.message "* Training data:"
        Nimbus.message "*   Training file: #{@training_file}"
        Nimbus.message "*" * 50
      end

      if @do_testing
        Nimbus.message "* Data to be tested:"
        Nimbus.message "*   Testing file: #{@testing_file}"
        if @forest_file
          Nimbus.message "* using the structure of the random forest stored in:"
          Nimbus.message "*   Random forest file: #{@forest_file}"
        end
        Nimbus.message "*" * 50
      end
    end

  end
end