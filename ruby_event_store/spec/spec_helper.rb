if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ruby_event_store'
require 'in_memory/in_memory_repository'
require 'matchers/event_store_matcher'
require 'helpers/sample_event'
