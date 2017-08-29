RSpec.configure { |c| c.disable_monkey_patching! }

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ruby_event_store'
Dir["./spec/support/**/*.rb"].sort.each { |file| require file }
