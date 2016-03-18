require 'spec_helper'

module RubyEventStore
  describe Facade do
    let(:repository) { InMemoryRepository.new }

    specify 'PubSub::Broker is a default event broker' do
      facade = RubyEventStore::Facade.new(repository)
      expect(facade.event_broker).to be_a(RubyEventStore::PubSub::Broker)
    end

    specify 'setup event broker dependency' do
      broker = RubyEventStore::PubSub::Broker.new
      facade = RubyEventStore::Facade.new(repository, broker)
      expect(facade.event_broker).to eql(broker)
    end
  end
end
