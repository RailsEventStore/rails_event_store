require "bundler/setup"
require "rails_event_store"
require "rails_event_store/rspec"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

FooEvent = Class.new(RailsEventStore::Event)
BarEvent = Class.new(RailsEventStore::Event)
BazEvent = Class.new(RailsEventStore::Event)

