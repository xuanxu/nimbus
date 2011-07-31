module Nimbus
  class Error < StandardError; end
  class InvalidOptionError < Error; end
  class InputFileError < Error; end
  class WrongFormattedFileError < Error; end
  class ConfigurationError < Error; end
  class ForestError < Error; end
  class TreeError < Error; end
  class IndividualError < Error; end
end