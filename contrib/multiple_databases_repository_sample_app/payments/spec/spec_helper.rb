ENV['RAILS_ENV'] = 'test'

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
