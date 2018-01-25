RSpec.configure { |c| c.disable_monkey_patching! }

require 'ruby_event_store'
Dir["./spec/support/**/*.rb"].sort.each { |file| require file }
