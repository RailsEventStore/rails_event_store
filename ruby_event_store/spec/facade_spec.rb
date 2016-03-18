require 'spec_helper'

module RubyEventStore
  describe Facade do
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
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect(facade.event_broker).to be_a(RubyEventStore::PubSub::Broker)
    end

    specify 'setup event broker dependency' do
      broker = RubyEventStore::PubSub::Broker.new
      facade = RubyEventStore::Facade.new(InMemoryRepository.new, broker)
      expect(facade.event_broker).to eql(broker)
    end

    specify 'publish fail if expected version is nil' do
      stream = SecureRandom.uuid
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      expect{ facade.publish_event(TestEvent.new, stream, nil) }.to raise_error(InvalidExpectedVersion)
    end

    specify 'publish first event, expect any stream state' do
      stream = SecureRandom.uuid
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      first_event   = TestEvent.new
      expect(facade.publish_event(first_event, stream)).to eq(:ok)
      expect(facade.read_stream_events_forward(stream)).to eq([first_event])
    end

    specify 'publish next event, expect any stream state' do
      stream = SecureRandom.uuid
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      first_event   = TestEvent.new
      second_event  = TestEvent.new
      facade.append_to_stream(stream, first_event)
      expect(facade.publish_event(second_event, stream)).to eq(:ok)
      expect(facade.read_stream_events_forward(stream)).to eq([first_event, second_event])
    end

    specify 'publish first event, expect empty stream' do
      stream = SecureRandom.uuid
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      first_event   = TestEvent.new
      expect(facade.publish_event(first_event, stream, :none)).to eq(:ok)
      expect(facade.read_stream_events_forward(stream)).to eq([first_event])
    end

    specify 'publish first event, fail if not empty stream' do
      stream = SecureRandom.uuid
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      first_event   = TestEvent.new
      second_event  = TestEvent.new
      facade.append_to_stream(stream, first_event)
      expect{ facade.publish_event(second_event, stream, :none) }.to raise_error(WrongExpectedEventVersion)
      expect(facade.read_stream_events_forward(stream)).to eq([first_event])
    end

    specify 'publish event, expect last event to be the last read one' do
      stream = SecureRandom.uuid
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      first_event   = TestEvent.new
      second_event  = TestEvent.new
      facade.append_to_stream(stream, first_event)
      expect(facade.publish_event(second_event, stream, first_event.event_id)).to eq(:ok)
      expect(facade.read_stream_events_forward(stream)).to eq([first_event, second_event])
    end

    specify 'publish event, fail if last event is not the last read one' do
      stream = SecureRandom.uuid
      facade = RubyEventStore::Facade.new(InMemoryRepository.new)
      first_event   = TestEvent.new
      second_event  = TestEvent.new
      third_event   = TestEvent.new
      facade.append_to_stream(stream, first_event)
      facade.append_to_stream(stream, second_event)
      expect{ facade.publish_event(third_event, stream, first_event.event_id) }.to raise_error(WrongExpectedEventVersion)
      expect(facade.read_stream_events_forward(stream)).to eq([first_event, second_event])
    end
  end
end
