require 'spec_helper'

module RubyEventStore
  describe Facade do
    let(:repository) { InMemoryRepository.new }
    TestEvent = Class.new(RubyEventStore::Event)

    specify 'publish_event returns :ok when success' do
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect(facade.publish_event(TestEvent.new)).to eq(:ok)
    end
    specify 'append_to_stream returns :ok when success' do
      stream = SecureRandom.uuid
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect(facade.append_to_stream(stream, TestEvent.new)).to eq(:ok)
    end
    specify 'delete_stream returns :ok when success' do
      stream = SecureRandom.uuid
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect(facade.delete_stream(stream)).to eq(:ok)
    end

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
