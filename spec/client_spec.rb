require 'spec_helper'

module RailsEventStore
  TestEvent = Class.new(RailsEventStore::Event)

  describe Client do

    specify 'initialize proper adapter type' do
      client = Client.new
      expect(client.__send__("repository")).to be_a RailsEventStoreActiveRecord::EventRepository
    end

    specify 'initialize proper event broker type' do
      client = Client.new
      expect(client.__send__("event_broker")).to be_a EventBroker
    end

    specify 'read events forward' do
      client = Client.new
      client.publish_event(TestEvent.new(event_id: '1'), 'stream')
      client.publish_event(TestEvent.new(event_id: '2'), 'stream')
      client.publish_event(TestEvent.new(event_id: '3'), 'stream')
      client.publish_event(TestEvent.new(event_id: '4'), 'other_stream')
      client.publish_event(TestEvent.new(event_id: '5'), 'stream')

      expect(client.read_events_forward('stream').map(&:event_id)).to eq(['1', '2', '3', '5'])
      expect(client.read_events_forward('stream', :head).map(&:event_id)).to eq(['1', '2', '3', '5'])
      expect(client.read_events_forward('stream', '1').map(&:event_id)).to eq(['2', '3', '5'])
      expect(client.read_events_forward('stream', '1', 2).map(&:event_id)).to eq(['2', '3'])
    end

    specify 'read events backward' do
      client = Client.new
      client.publish_event(TestEvent.new(event_id: '1'), 'stream')
      client.publish_event(TestEvent.new(event_id: '2'), 'stream')
      client.publish_event(TestEvent.new(event_id: '3'), 'stream')
      client.publish_event(TestEvent.new(event_id: '4'), 'other_stream')
      client.publish_event(TestEvent.new(event_id: '5'), 'stream')

      expect(client.read_events_backward('stream').map(&:event_id)).to eq(['5', '3', '2', '1'])
      expect(client.read_events_backward('stream', :head).map(&:event_id)).to eq(['5', '3', '2', '1'])
      expect(client.read_events_backward('stream', '3').map(&:event_id)).to eq(['2', '1'])
      expect(client.read_events_backward('stream', '3', 1).map(&:event_id)).to eq(['2'])
    end

    specify 'read all stream events forward' do
      client = Client.new
      client.publish_event(TestEvent.new(event_id: '1'), 'stream')
      client.publish_event(TestEvent.new(event_id: '2'), 'other_stream')
      client.publish_event(TestEvent.new(event_id: '3'), 'stream')

      expect(client.read_stream_events_forward('stream').map(&:event_id)).to eq(['1', '3'])
    end

    specify 'read all stream events backward' do
      client = Client.new
      client.publish_event(TestEvent.new(event_id: '1'), 'stream')
      client.publish_event(TestEvent.new(event_id: '2'), 'other_stream')
      client.publish_event(TestEvent.new(event_id: '3'), 'stream')

      expect(client.read_stream_events_backward('stream').map(&:event_id)).to eq(['3', '1'])
    end

    specify 'read all streams forward' do
      client = Client.new
      client.publish_event(TestEvent.new(event_id: '1'))
      client.publish_event(TestEvent.new(event_id: '2'), 'stream-1')
      client.publish_event(TestEvent.new(event_id: '3'), 'stream-2')
      client.publish_event(TestEvent.new(event_id: '4'), 'stream-2')

      expect(client.read_all_streams_forward.map(&:event_id)).to eq(['1', '2', '3', '4'])
      expect(client.read_all_streams_forward(:head, 3).map(&:event_id)).to eq(['1', '2', '3'])
      expect(client.read_all_streams_forward('2', 2).map(&:event_id)).to eq(['3', '4'])
    end

    specify 'read all streams backward' do
      client = Client.new
      client.publish_event(TestEvent.new(event_id: '1'))
      client.publish_event(TestEvent.new(event_id: '2'), 'stream-1')
      client.publish_event(TestEvent.new(event_id: '3'), 'stream-2')
      client.publish_event(TestEvent.new(event_id: '4'), 'stream-2')

      expect(client.read_all_streams_backward.map(&:event_id)).to eq(['4', '3', '2', '1'])
      expect(client.read_all_streams_backward(:head, 3).map(&:event_id)).to eq(['4', '3', '2'])
      expect(client.read_all_streams_backward('4', 2).map(&:event_id)).to eq(['3', '2'])
    end

    specify 'lambda is an output of global subscribe methods' do
      subscriber = ->(event) { handled_events << event }
      client = Client.new
      result = client.subscribe_to_all_events(subscriber)
      expect(result).to respond_to(:call)
    end

    specify 'lambda is an output of subscribe methods' do
      subscriber = ->(event) { handled_events << event }
      client = Client.new
      result = client.subscribe(subscriber, [TestEvent])
      expect(result).to respond_to(:call)
    end

    specify 'dynamic global subscription' do
      handled_events = []
      event_1 = TestEvent.new
      event_2 = TestEvent.new
      subscriber = ->(event) { handled_events << event }
      client = Client.new
      result = client.subscribe_to_all_events(subscriber) do
        client.publish_event(event_1)
      end
      client.publish_event(event_2)
      expect(handled_events).to eq [event_1]
      expect(result).to respond_to(:call)
      expect(client.read_all_streams_forward(:head, 10)).to eq([event_1, event_2])
    end

    specify 'dynamic subscription' do
      handled_events = []
      event_1 = TestEvent.new
      event_2 = TestEvent.new
      subscriber = ->(event) { handled_events << event }
      client = Client.new
      result = client.subscribe(subscriber, [TestEvent]) do
        client.publish_event(event_1)
      end
      client.publish_event(event_2)
      expect(handled_events).to eq [event_1]
      expect(result).to respond_to(:call)
      expect(client.read_all_streams_forward(:head, 10)).to eq([event_1, event_2])
    end
  end
end
