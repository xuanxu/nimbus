module Nimbus
  # Nimbus custom Error class.
  class Error < StandardError; end
  # Error when a non existent or invalid option is used.
  class InvalidOptionError < Error; end
  # Error in some of the input files.
  class InputFileError < Error; end
  # Error if data from some input file are incorrectly formatted.
  class WrongFormatFileError < Error; end
  # Error if configuration options are invalid.
  class ConfigurationError < Error; end
  # Error handling a random Forest.
  class ForestError < Error; end
  # Error handling a Tree object.
  class TreeError < Error; end
  # Error in the data of an Individual object.
  class IndividualError < Error; end
end