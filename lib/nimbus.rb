require 'yaml'
module Nimbus
  def initialize
    load_config_params('./config.yml')
  end
  
  def load_config_params(config_file)
    config = config_file || './config.yml'
    @config_params = YAML.load_file(config) rescue {}
  end
  
  def config_params
    @config_params
  end
  
end