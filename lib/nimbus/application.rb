module Nimbus
  
  #####################################################################
  # Nimbus main application object. When invoking +nimbus+ from the
  # command line, a Nimbus::Application object is created and run.
  #
  class Application
    attr_accessor :config
    
    # Initialize a Nimbus::Application object.
    # Check and load the configuration options.
    #
    def initialize
      nimbus_exception_handling do
        config.load
      end
    end
    
    # Run the Nimbus application. The run method performs the following
    # two steps:
    #
    # * Creates a Nimbus::Forest object.
    # * Writes results to output files.
    def run
      puts time
      nimbus_exception_handling do
        forest = ::Nimbus::Forest.new @config
        forest.grow if @config.do_training && @config.load_training_data
        output_random_forest_file(forest)
      end
    end

    # Createas an instance of Nimbus::Configuration if it does not exist.
    def config
      @config ||= ::Nimbus::Configuration.new
    end
    
    # Provide exception handling for the given block.
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
    
    # Display the error message that caused the exception.
    def display_error_message(ex)
      Nimbus.error_message "* Nimbus encountered an error! The random forest was not generated *"
      Nimbus.error_message "#{ex.class}: #{ex.message}"
      # if config.trace
          Nimbus.error_message ex.backtrace.join("\n")
      # else
      #   Nimbus.error_message "(See full error trace by running Nimbus with --trace)"
      # end
    end
    
    protected
    def output_random_forest_file(forest)
      File.open(@config.output_forest_file , 'w') {|f| f.write(forest.to_yaml) }
      Nimbus.message "* Resulting forest structure be saved to:"
      Nimbus.message "*   Output forest file: #{@config.output_forest_file}"
      Nimbus.message "*" * 50
      
    end
    
  end
  
end