ENV['RAILS_ENV'] = 'test'

require_relative '../lib/payments'

def arrange(stream, events, event_store: Payments.event_store)
  event_store.append(events, stream_name: stream)
end

def act(command, bus: Orders.command_bus)
  bus.call(command)
end

Configuration = Struct.new(:event_repository, :command_bus)
Payments.setup(Configuration.new(
  RubyEventStore::InMemoryRepository.new,
  Arkency::CommandBus.new,
))
