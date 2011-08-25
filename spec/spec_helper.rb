# encoding: UTF-8
require File.dirname(__FILE__) + '/../lib/nimbus'
$fixtures_path = File.dirname(__FILE__) + '/fixtures'
ENV['nimbus_test'] = 'running_nimbus_tests'

def fixture_file(filename) #:nodoc:
  return "#{$fixtures_path}/#{filename}"
end