module Nimbus
  
  #####################################################################
  # Nimbus main application object. 
  # 
  # When invoking +nimbus+ from the command line, 
  # a Nimbus::Application object is created and run.
  #
  class Application
    attr_accessor :config
    
    # Initialize a Nimbus::Application object.
    # Check and load the configuration options.
    def initialize(c = nil)
      @config = c unless c.nil?
      nimbus_exception_handling do
        config.load
        @forest = nil
      end
    end
    
    # Run the Nimbus application. The run method performs the following
    # three steps:
    #
    # * Create a Nimbus::Forest object.
    # * Decide action to take: training a random forest and/or use the forest to predict values for a testing set
    # * Write results to output files.
    def run
      nimbus_exception_handling do
        
        if @config.do_training && @config.load_training_data
          @forest = ::Nimbus::Forest.new @config
          @forest.grow
          output_random_forest_file(@forest)
          output_tree_errors_file(@forest)
          output_training_file_predictions(@forest)
          output_snp_importances_file(@forest)
        end
        
        if @config.do_testing
          @forest = @config.load_forest if @config.forest_file
          @forest.traverse
          output_testing_set_predictions(@forest)          
        end
        
      end
    end

    # Creates an instance of Nimbus::Configuration if it does not exist.
    # This config object contains every option to be used for the random forest
    # including the user input set through the config.yml file.
    def config
      @config ||= ::Nimbus::Configuration.new
    end
    
    # Provides the default exception handling for the given block.
    def nimbus_exception_handling
      begin
        yield
      rescue SystemExit => ex
        raise
      rescue OptionParser::InvalidOption => ex
        display_error_message(Nimbus::InvalidOptionError ex.message)
        Nimbus.stop
      rescue Nimbus::Error => ex
        display_error_message(ex)
        Nimbus.stop
      rescue Exception => ex
        display_error_message(ex)
        Nimbus.stop
      end
    end
    
    # Display an error message that caused a exception.
    def display_error_message(ex)
      Nimbus.error_message "* Nimbus encountered an error! The random forest was not generated *"
      Nimbus.error_message "#{ex.class}: #{ex.message}"
      # if config.trace
      #   Nimbus.error_message ex.backtrace.join("\n")
      # else
      #   Nimbus.error_message "(See full error trace by running Nimbus with --trace)"
      # end
    end
    
    protected
    def output_random_forest_file(forest)
      File.open(@config.output_forest_file , 'w') {|f| f.write(forest.to_yaml) }
      Nimbus.message "* Random forest structure saved to:"
      Nimbus.message "*   Output forest file: #{@config.output_forest_file}"
      Nimbus.message "*" * 50
    end
    
    def output_tree_errors_file(forest)
      File.open(@config.output_tree_errors_file , 'w') {|f| 
        1.upto(forest.tree_errors.size) do |te|
          f.write("generalization error for tree ##{te}: #{forest.tree_errors[te-1].round(5)}\n")
        end
      }
      Nimbus.message "* Generalization errors for every tree saved to:"
      Nimbus.message "*   Output tree errors file: #{@config.output_tree_errors_file}"
      Nimbus.message "*" * 50
    end
    
    def output_training_file_predictions(forest)
      File.open(@config.output_training_file , 'w') {|f|
        forest.predictions.sort.each{|p|
          f.write("#{p[0]} #{p[1]}\n")
        }
      }
      Nimbus.message "* Predictions for the training sample saved to:"
      Nimbus.message "*   Output from training file: #{@config.output_training_file}"
      Nimbus.message "*" * 50
    end
    
    def output_testing_set_predictions(forest)
      File.open(@config.output_testing_file , 'w') {|f|
        forest.predictions.sort.each{|p|
          f.write("#{p[0]} #{p[1]}\n")
        }
      }
      Nimbus.message "* Predictions for the testing set saved to:"
      Nimbus.message "*   Output from testing file: #{@config.output_testing_file}"
      Nimbus.message "*" * 50
    end
    
    def output_snp_importances_file(forest)
      File.open(@config.output_snp_importances_file , 'w') {|f|
        forest.snp_importances.sort.each{|p|
          f.write("SNP ##{p[0]}: #{p[1].round(5)}\n")
        }
      }
      Nimbus.message "* SNP importances for the forest saved to:"
      Nimbus.message "*   Output snp importance file: #{@config.output_snp_importances_file}"
      Nimbus.message "*" * 50
    end
    
  end
  
end