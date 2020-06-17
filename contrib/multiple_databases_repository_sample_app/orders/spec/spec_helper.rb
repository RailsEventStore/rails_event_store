ENV['RAILS_ENV'] = 'test'

require_relative '../lib/orders'

module Orders
  def self.arrange(stream, events, event_store: Orders.event_store)
    event_store.append(events, stream_name: stream)
  end

  def self.act(command, bus: Orders.command_bus)
    bus.call(command)
  end
end

unless Orders.setup?
  Configuration = Struct.new(:event_repository, :command_bus, :number_generator_factory)
  Orders.setup(Configuration.new(
    RubyEventStore::InMemoryRepository.new,
    Arkency::CommandBus.new,
    ->{ Orders::FakeNumberGenerator.new },
  ))
end
