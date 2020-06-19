ENV['RAILS_ENV'] ||= 'test'

require_relative '../lib/shipping'

module Shipping
  def self.arrange(stream, events, event_store: Shipping.event_store)
    event_store.append(events, stream_name: stream)
  end

  def self.act(command, bus: Shipping.command_bus)
    bus.call(command)
  end
end

unless Shipping.setup?
  Configuration = Struct.new(:event_repository, :command_bus)
  Shipping.setup(Configuration.new(
    RubyEventStore::InMemoryRepository.new,
    Arkency::CommandBus.new,
  ))
end
