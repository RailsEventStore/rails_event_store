require 'active_record'

ENV['RAILS_ENV'] ||= 'test'
if ActiveRecord::Base.configurations.empty?
  configuration = YAML::load(File.open('../config/database.yml'))
  ActiveRecord::Base.configurations = configuration
  ActiveRecord::Base.establish_connection(configuration[ENV['RAILS_ENV']]["payments"])
  begin
    ActiveRecord::Migration.maintain_test_schema!
  rescue ActiveRecord::PendingMigrationError => e
    puts e.to_s.strip
    exit 1
  end
  require 'arkency/command_bus'
  require 'rails_event_store'
  require 'aggregate_root'
end

require_relative '../lib/payments'

module Payments
  def self.arrange(stream, events, event_store: Payments.event_store)
    event_store.append(events, stream_name: stream)
  end

  def self.act(command, bus: Payments.command_bus)
    bus.call(command)
  end
end

unless Payments.setup?
  Configuration = Struct.new(:event_repository, :command_bus)
  Payments.setup(Configuration.new(
    RubyEventStore::InMemoryRepository.new,
    Arkency::CommandBus.new,
  ))
end
