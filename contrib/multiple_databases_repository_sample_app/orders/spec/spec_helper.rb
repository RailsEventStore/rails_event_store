ENV['RAILS_ENV'] = 'test'

require_relative '../lib/orders'

def arrange(stream, events, event_store: Orders.event_store)
  event_store.append(events, stream_name: stream)
end

def act(command, bus: Orders.command_bus)
  bus.call(command)
end

Configuration = Struct.new(:event_store, :command_bus, :number_generator)
Orders.setup(Configuration.new(
  RailsEventStore::Client.new,
  Arkency::CommandBus.new,
  Orders::FakeNumberGenerator.new,
))
