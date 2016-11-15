if ENV['CODECLIMATE_REPO_TOKEN']
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ruby_event_store'
Dir["./spec/support/**/*.rb"].sort.each { |file| require file }
