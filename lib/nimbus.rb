require 'yaml'
require 'optparse'
require 'nimbus/exceptions'
require 'nimbus/training_set'
require 'nimbus/configuration'
require 'nimbus/loss_functions'
require 'nimbus/individual'
require 'nimbus/tree'
require 'nimbus/forest'
require 'nimbus/application'

module Nimbus
  
  STDERR = $stderr
  STDOUT = $stdout
  
  # Nimbus module singleton methods.
  #
  class << self
    # Current Nimbus Application
    def application
      @application ||= ::Nimbus::Application.new
    end
    
    # Set the current Nimbus application object.
    def application=(app)
      @application = app
    end
    
    # Stops the execution of the Nimbus application.
    def stop(msg = "Error: Nimbus finished.")
      self.error_message msg
      exit(false)
    end
    
    # Writes message to the standard output
    def message(msg)
      STDOUT.puts msg
      STDOUT.flush
    end
    
    # Writes message to the error output
    def error_message(msg)
      STDERR.puts msg
      STDERR.flush
    end
    
    def write(str)
      STDOUT.write str
      STDOUT.flush
    end

    def clear_line!
      self.write "\r"
    end
    
  end
  
end