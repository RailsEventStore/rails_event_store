require 'spec_helper'
require 'time'
require_relative 'mappers/events_pb.rb'

module RubyEventStore
  RSpec.describe Client do
    specify 'deprecates using metadata_proc' do
      deprecation_warning = "`RubyEventStore::Client#metadata_proc` has been deprecated. Use `RubyEventStore::Client#with_metadata` instead.\n"
      expect {
        RubyEventStore::Client.new(repository: InMemoryRepository.new, metadata_proc: ->{ {} })
      }.to output(deprecation_warning).to_stderr
    end

    specify 'publish_event returns :ok when success' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect(client.publish_event(TestEvent.new)).to eq(:ok)
    end

    specify 'append_to_stream returns :ok when success' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect(client.append_to_stream(TestEvent.new, stream_name: stream)).to eq(:ok)
    end

    specify 'append to default stream when not specified' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      expect(client.append_to_stream(test_event)).to eq(:ok)
      expect(client.read.limit(100).each.to_a).to eq([test_event])
    end

    specify 'publish to default stream when not specified' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      expect(client.publish_events([test_event])).to eq(:ok)
      expect(client.read.limit(100).each.to_a).to eq([test_event])
    end

    specify 'delete_stream returns :ok when success' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect(client.delete_stream(stream)).to eq(:ok)
    end

    specify 'publish to default stream when not specified' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      expect(client.publish_event(test_event)).to eq(:ok)
      expect(client.read.limit(100).each.to_a).to eq([test_event])
    end

    specify 'publish first event, expect any stream state' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event = TestEvent.new
      expect(client.publish_event(first_event, stream_name: stream)).to eq(:ok)
      expect(client.read.stream(stream).each.to_a).to eq([first_event])
    end

    specify 'publish next event, expect any stream state' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event = TestEvent.new
      second_event = TestEvent.new
      client.append_to_stream(first_event, stream_name: stream)
      expect(client.publish_event(second_event, stream_name: stream)).to eq(:ok)
      expect(client.read.stream(stream).each.to_a).to eq([first_event, second_event])
    end

    specify 'publish first event, expect empty stream' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event = TestEvent.new
      expect(client.publish_event(first_event, stream_name: stream, expected_version: :none)).to eq(:ok)
      expect(client.read.stream(stream).each.to_a).to eq([first_event])
    end

    specify 'publish first event, fail if not empty stream' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event = TestEvent.new
      second_event = TestEvent.new
      client.append_to_stream(first_event, stream_name: stream)
      expect { client.publish_event(second_event, stream_name: stream, expected_version: :none) }.to raise_error(WrongExpectedEventVersion)
      expect(client.read.stream(stream).each.to_a).to eq([first_event])
    end

    specify 'publish event, expect last event to be the last read one' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event = TestEvent.new
      second_event = TestEvent.new
      client.append_to_stream(first_event, stream_name: stream)
      expect(client.publish_event(second_event, stream_name: stream, expected_version: 0)).to eq(:ok)
      expect(client.read.stream(stream).each.to_a).to eq([first_event, second_event])
    end

    specify 'publish event, fail if last event is not the last read one' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event = TestEvent.new
      second_event = TestEvent.new
      third_event = TestEvent.new
      client.append_to_stream(first_event, stream_name: stream)
      client.append_to_stream(second_event, stream_name: stream)
      expect { client.publish_event(third_event, stream_name: stream, expected_version: 0) }.to raise_error(WrongExpectedEventVersion)
      expect(client.read.stream(stream).each.to_a).to eq([first_event, second_event])
    end

    specify 'append many events' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event = TestEvent.new
      second_event = TestEvent.new
      client.append_to_stream([first_event, second_event], stream_name: stream, expected_version: -1)
      expect(client.read.stream(stream).each.to_a).to eq([first_event, second_event])
    end

    specify 'read only up to page size from stream' do
      stream = SecureRandom.uuid
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      (1..102).each { client.append_to_stream(TestEvent.new, stream_name: stream) }
      expect(client.read.stream(stream).limit(10).each.to_a.size).to eq(10)
      expect(client.read.backward.stream(stream).limit(10).each.to_a.size).to eq(10)
      expect(client.read.stream(stream).limit(100).each.to_a.size).to eq(PAGE_SIZE)
      expect(client.read.backward.stream(stream).limit(100).each.to_a.size).to eq(PAGE_SIZE)

      expect(client.read.limit(10).each.to_a.size).to eq(10)
      expect(client.read.backward.limit(10).each.to_a.size).to eq(10)
      expect(client.read.limit(100).each.to_a.size).to eq(PAGE_SIZE)
      expect(client.read.backward.limit(100).each.to_a.size).to eq(PAGE_SIZE)
    end

    specify 'published event metadata will be enriched by proc execution' do
      client = silence_warnings { RubyEventStore::Client.new(repository: InMemoryRepository.new, metadata_proc: ->{ {request_id: '127.0.0.1'} }) }
      event = TestEvent.new
      client.append_to_stream(event)
      published = client.read.limit(100).each.to_a
      expect(published.size).to eq(1)
      expect(published.first.metadata[:request_id]).to eq('127.0.0.1')
      expect(published.first.metadata[:timestamp]).to be_a Time
    end

    specify 'published event metadata will be enriched by metadata provided in with_metadata when executed inside a block' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = TestEvent.new
      client.with_metadata(request_ip: '127.0.0.1') do
        client.publish_event(event)
      end
      published = client.read.limit(100).each.to_a
      expect(published.size).to eq(1)
      expect(published.first.metadata[:request_ip]).to eq('127.0.0.1')
      expect(published.first.metadata[:timestamp]).to be_a Time
    end

    specify 'published event metadata will not be enriched by metadata provided in with_metadata when published outside a block' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = TestEvent.new
      client.with_metadata(request_ip: '127.0.0.1')
      client.publish_event(event)
      published = client.read.limit(100).each.to_a
      expect(published.size).to eq(1)
      expect(published.first.metadata[:request_ip]).to be_nil
      expect(published.first.metadata[:timestamp]).to be_a Time
    end

    specify 'published event metadata will be enriched by nested metadata provided in with_metadata' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client.with_metadata(request_ip: '127.0.0.1') do
        client.publish_event(TestEvent.new)
        client.with_metadata(request_ip: '1.2.3.4', nested: true) do
          client.publish_event(TestEvent.new)
          client.with_metadata(deeply_nested: true) do
            client.publish_event(TestEvent.new)
          end
        end
        client.publish_event(TestEvent.new)
      end
      client.publish_event(TestEvent.new)
      published = client.read.limit(100).each.to_a
      expect(published.size).to eq(5)
      expect(published[0].metadata.keys).to match_array([:timestamp, :request_ip])
      expect(published[0].metadata[:request_ip]).to eq('127.0.0.1')
      expect(published[0].metadata[:timestamp]).to be_a Time
      expect(published[1].metadata.keys).to match_array([:timestamp, :request_ip, :nested])
      expect(published[1].metadata[:request_ip]).to eq('1.2.3.4')
      expect(published[1].metadata[:nested]).to eq true
      expect(published[1].metadata[:timestamp]).to be_a Time
      expect(published[2].metadata.keys).to match_array([:timestamp, :request_ip, :nested, :deeply_nested])
      expect(published[2].metadata[:request_ip]).to eq('1.2.3.4')
      expect(published[2].metadata[:nested]).to eq true
      expect(published[2].metadata[:deeply_nested]).to eq true
      expect(published[2].metadata[:timestamp]).to be_a Time
      expect(published[3].metadata.keys).to match_array([:timestamp, :request_ip])
      expect(published[3].metadata[:request_ip]).to eq('127.0.0.1')
      expect(published[3].metadata[:timestamp]).to be_a Time
      expect(published[4].metadata.keys).to match_array([:timestamp])
      expect(published[4].metadata[:timestamp]).to be_a Time
    end

    specify 'with_metadata is merged when nested' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client.with_metadata(remote_ip: '127.0.0.1') do
        client.publish_event(TestEvent.new)
          client.with_metadata(remote_ip: '192.168.0.1', request_id: '1234567890') do
              client.publish_event(TestEvent.new)
          end
        client.publish_event(TestEvent.new)
      end
      published = client.read.limit(100).each.to_a
      expect(published.size).to eq(3)
      expect(published[0].metadata.keys).to match_array([:timestamp, :remote_ip])
      expect(published[0].metadata[:remote_ip]).to eq('127.0.0.1')
      expect(published[0].metadata[:timestamp]).to be_a Time
      expect(published[1].metadata.keys).to match_array([:timestamp, :remote_ip, :request_id])
      expect(published[1].metadata[:timestamp]).to be_a Time
      expect(published[1].metadata[:remote_ip]).to eq('192.168.0.1')
      expect(published[1].metadata[:request_id]).to eq('1234567890')
      expect(published[2].metadata.keys).to match_array([:timestamp, :remote_ip])
      expect(published[2].metadata[:remote_ip]).to eq('127.0.0.1')
      expect(published[2].metadata[:timestamp]).to be_a Time
    end

    specify 'when both metadata_proc & with_metadata block are used, the event\'s metadata will be enriched first from the proc and then from with_metadata argument' do
      client = silence_warnings { RubyEventStore::Client.new(repository: InMemoryRepository.new, metadata_proc: ->{ {proc: true, request_ip: '127.0.0.1'} }) }
      event = TestEvent.new
      client.with_metadata(request_ip: '1.2.3.4', meta: true) do
        client.append_to_stream(event)
      end
      published = client.read.limit(100).each.to_a
      expect(published.size).to eq(1)
      expect(published.first.metadata[:request_ip]).to eq('1.2.3.4')
      expect(published.first.metadata[:proc]).to eq(true)
      expect(published.first.metadata[:meta]).to eq(true)
      expect(published.first.metadata[:timestamp]).to be_a Time
    end

    specify 'metadata is bound to the current instance and does not leak to others' do
      client_a = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client_b = RubyEventStore::Client.new(repository: InMemoryRepository.new)

      client_a.with_metadata(client: 'a') do
        client_b.with_metadata(client: 'b') do
          client_a.publish_event(TestEvent.new)
          client_b.publish_event(TestEvent.new)
        end
      end

      published_a = client_a.read.limit(100).each.to_a
      published_b = client_b.read.limit(100).each.to_a
      expect(published_a.size).to eq(1)
      expect(published_b.size).to eq(1)
      expect(published_a.last.metadata[:client]).to eq('a')
      expect(published_b.last.metadata[:client]).to eq('b')
    end

    specify 'timestamp can be overwritten by using with_metadata' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = TestEvent.new
      client.with_metadata(timestamp: '2018-01-01T00:00:00Z') do
        client.append_to_stream(event)
      end
      published = client.read.limit(100).each.to_a
      expect(published.size).to eq(1)
      expect(published.first.metadata.to_h.keys).to eq([:timestamp])
      expect(published.first.metadata[:timestamp]).to eq('2018-01-01T00:00:00Z')
    end

    specify 'only timestamp set inn metadata when event stored in stream if metadata proc return nil' do
      client = silence_warnings { RubyEventStore::Client.new(repository: InMemoryRepository.new, metadata_proc: ->{ nil }) }
      event = TestEvent.new
      client.append_to_stream(event)
      published = client.read.limit(100).each.to_a
      expect(published.size).to eq(1)
      expect(published.first.metadata.to_h.keys).to eq([:timestamp])
      expect(published.first.metadata[:timestamp]).to be_a Time
    end

    specify 'timestamp is utc time' do
      now = Time.parse('2015-05-04 15:17:11 +0200')
      utc = Time.parse('2015-05-04 13:17:23 UTC')
      allow(Time).to receive(:now).and_return(now)
      allow_any_instance_of(Time).to receive(:utc).and_return(utc)
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = TestEvent.new
      client.publish_event(event)
      published = client.read.limit(100).each.to_a
      expect(published.size).to eq(1)
      expect(published.first.metadata[:timestamp]).to eq(utc)
    end

    specify 'throws exception if subscriber is not defined' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.subscribe(nil, to: []) }.to raise_error(SubscriberNotExist)
      expect { client.subscribe_to_all_events(nil) }.to raise_error(SubscriberNotExist)
    end

    specify 'reading particular event' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      client.publish_event(test_event, stream_name: 'test')

      expect(client.read_event(test_event.event_id)).to eq(test_event)
    end

    specify 'reading non-existent event' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_event('72922e65-1b32-4e97-8023-03ae81dd3a27') }.to raise_error(EventNotFound)
    end

    specify 'link events' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      first_event = TestEvent.new
      second_event = TestEvent.new
      client.subscribe_to_all_events(subscriber = Subscribers::ValidHandler.new)
      client.append_to_stream([first_event, second_event], stream_name: 'stream')
      client.link_to_stream(
        [first_event.event_id, second_event.event_id],
        stream_name: 'flow',
        expected_version: -1
      ).link_to_stream(
        [first_event.event_id],
        stream_name: 'cars',
      )
      expect(client.read.stream("flow").each.to_a).to eq([first_event, second_event])
      expect(client.read.stream("cars").each.to_a).to eq([first_event])
      expect(subscriber.handled_events).to be_empty
    end

    specify 'can handle protobuf event class instead of RubyEventStore::Event' do
      client = RubyEventStore::Client.new(
        mapper: RubyEventStore::Mappers::Protobuf.new,
        repository: InMemoryRepository.new
      )
      event = RubyEventStore::Proto.new(
        event_id: "f90b8848-e478-47fe-9b4a-9f2a1d53622b",
        data: ResTesting::OrderCreated.new(
          customer_id: 123,
          order_id: "K3THNX9",
        )
      )
      client.publish_event(event, stream_name: 'test')
      expect(client.read_event(event.event_id)).to eq(event)
      expect(client.read.stream("test").each.to_a).to eq([event])
    end

    specify 'raise exception if stream name is incorrect' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read.stream(nil).limit(100).each.to_a }.to raise_error(IncorrectStreamData)
      expect { client.read.stream("").limit(100).each.to_a }.to raise_error(IncorrectStreamData)
      expect { client.read.backward.stream(nil).limit(100).each.to_a }.to raise_error(IncorrectStreamData)
      expect { client.read.backward.stream("").limit(100).each.to_a }.to raise_error(IncorrectStreamData)
    end

    specify 'raise exception if event_id does not exist' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read.stream("stream_name").from("0").limit(100).each.to_a }.to raise_error(EventNotFound, /Event not found: 0/)
      expect { client.read.backward.stream("stream_name").from("0").limit(100).each.to_a }.to raise_error(EventNotFound, /0/)
    end

    specify 'raise exception if event_id is not given or invalid' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read.stream("stream_name").from(nil).limit(100).each.to_a }.to raise_error(InvalidPageStart)
      expect { client.read.backward.stream("stream_name").from(:invalid).limit(100).each.to_a }.to raise_error(InvalidPageStart)
    end

    specify 'fails when page size is invalid' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read.stream("stream_name").limit(0).each.to_a }.to raise_error(InvalidPageSize)
      expect { client.read.backward.stream("stream_name").limit(0).each.to_a }.to raise_error(InvalidPageSize)
      expect { client.read.stream("stream_name").limit(-1).each.to_a }.to raise_error(InvalidPageSize)
      expect { client.read.backward.stream("stream_name").limit(-1).each.to_a }.to raise_error(InvalidPageSize)
    end

    specify 'return all events ordered forward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      4.times do |index|
        event = OrderCreated.new(event_id: index.to_s)
        client.publish_event(event, stream_name: 'stream_name')
      end
      events = client.read.stream("stream_name").from("1").limit(3).each.to_a
      expect(events[0]).to eq(OrderCreated.new(event_id: '2'))
      expect(events[1]).to eq(OrderCreated.new(event_id: '3'))
    end

    specify 'return specified number of events ordered forward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      4.times do |index|
        event = OrderCreated.new(event_id: index.to_s)
        client.publish_event(event, stream_name: 'stream_name')
      end
      events = client.read.stream("stream_name").from("1").limit(1).each.to_a
      expect(events[0]).to eq(OrderCreated.new(event_id: '2'))
    end

    specify 'return all events ordered backward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      4.times do |index|
        event = OrderCreated.new(event_id: index)
        client.publish_event(event, stream_name: 'stream_name')
      end
      events = client.read.backward.stream("stream_name").from("2").limit(3).each.to_a
      expect(events[0]).to eq(OrderCreated.new(event_id: '1'))
      expect(events[1]).to eq(OrderCreated.new(event_id: '0'))
    end

    specify 'return specified number of events ordered backward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      4.times do |index|
        event = OrderCreated.new(event_id: index)
        client.publish_event(event, stream_name: 'stream_name')
      end
      events = client.read.backward.stream("stream_name").from("3").limit(2).each.to_a
      expect(events[0]).to eq(OrderCreated.new(event_id: '2'))
      expect(events[1]).to eq(OrderCreated.new(event_id: '1'))
    end

    specify 'fails when starting event not exists' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      4.times do |index|
        event = OrderCreated.new(event_id: index)
        client.publish_event(event, stream_name: 'stream_name')
      end
      expect { client.read.stream("stream_name").from(SecureRandom.uuid).limit(100).each.to_a }.to raise_error(EventNotFound)
      expect { client.read.backward.stream("stream_name").from(SecureRandom.uuid).limit(100).each.to_a }.to raise_error(EventNotFound)
    end

    specify 'raise exception if stream name is incorrect' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.delete_stream(nil) }.to raise_error(IncorrectStreamData)
      expect { client.delete_stream('') }.to raise_error(IncorrectStreamData)
    end

    specify 'successfully delete streams of events' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      4.times do |index|
        client.publish_event(OrderCreated.new, stream_name: 'test_1')
      end
      4.times do |index|
        client.publish_event(OrderCreated.new, stream_name: 'test_2')
      end
      all_events = client.read.limit(100).each.to_a
      expect(all_events.length).to eq 8
      client.delete_stream('test_2')
      all_events = client.read.limit(100).each.to_a
      expect(all_events.length).to eq 8
      expect(client.read.stream("test_2").each.to_a).to eq []
    end

    specify 'raise exception if stream name is incorrect' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read.stream(nil).each.to_a }.to raise_error(IncorrectStreamData)
      expect { client.read.stream("").each.to_a }.to raise_error(IncorrectStreamData)
      expect { client.read.backward.stream(nil).each.to_a }.to raise_error(IncorrectStreamData)
      expect { client.read.backward.stream("").each.to_a }.to raise_error(IncorrectStreamData)
    end

    specify 'raise exception if stream name is incorrect' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.append_to_stream(OrderCreated.new, stream_name: nil) }.to raise_error(IncorrectStreamData)
      expect { client.append_to_stream(OrderCreated.new, stream_name: '') }.to raise_error(IncorrectStreamData)
    end

    specify 'raise exception if stream name is incorrect' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.publish_event(OrderCreated.new, stream_name: nil) }.to raise_error(IncorrectStreamData)
      expect { client.publish_event(OrderCreated.new, stream_name: '') }.to raise_error(IncorrectStreamData)
      expect { client.publish_events([OrderCreated.new], stream_name: nil) }.to raise_error(IncorrectStreamData)
      expect { client.publish_events([OrderCreated.new], stream_name: '') }.to raise_error(IncorrectStreamData)
    end

    specify 'raise exception if stream name is incorrect' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.append_to_stream(OrderCreated.new, stream_name: nil) }.to raise_error(IncorrectStreamData)
      expect { client.append_to_stream(OrderCreated.new, stream_name: '') }.to raise_error(IncorrectStreamData)
    end

    specify 'raise exception if stream name is incorrect' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.append_to_stream(OrderCreated.new, stream_name: nil, expected_version: -1) }.to raise_error(IncorrectStreamData)
      expect { client.append_to_stream(OrderCreated.new, stream_name: '', expected_version: -1) }.to raise_error(IncorrectStreamData)
    end

    specify 'return all events ordered forward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      4.times do |index|
        event = OrderCreated.new(event_id: index.to_s)
        client.publish_event(event, stream_name: 'stream_name')
      end
      events = client.read.stream("stream_name").each.to_a
      expect(events[0]).to eq(OrderCreated.new(event_id: '0'))
      expect(events[1]).to eq(OrderCreated.new(event_id: '1'))
      expect(events[2]).to eq(OrderCreated.new(event_id: '2'))
      expect(events[3]).to eq(OrderCreated.new(event_id: '3'))
    end

    specify 'return all events ordered backward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      4.times do |index|
        event = OrderCreated.new(event_id: index.to_s)
        client.publish_event(event, stream_name: 'stream_name')
      end
      events = client.read.backward.stream("stream_name").each.to_a
      expect(events[0]).to eq(OrderCreated.new(event_id: '3'))
      expect(events[1]).to eq(OrderCreated.new(event_id: '2'))
      expect(events[2]).to eq(OrderCreated.new(event_id: '1'))
      expect(events[3]).to eq(OrderCreated.new(event_id: '0'))
    end

    specify 'return all events ordered forward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client.publish_event(OrderCreated.new(data: {order_id: 123}), stream_name: 'order_1')
      client.publish_event(OrderCreated.new(data: {order_id: 234}), stream_name: 'order_2')
      response = client.read.limit(100).each.to_a
      expect(response.length).to eq 2
      expect(response[0].data[:order_id]).to eq 123
      expect(response[1].data[:order_id]).to eq 234
    end

    specify 'return batch of events from the beginging ordered forward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client.publish_event(OrderCreated.new(data: {order_id: 123}), stream_name: 'order_1')
      client.publish_event(OrderCreated.new(data: {order_id: 234}), stream_name: 'order_2')
      client.publish_event(OrderCreated.new(data: {order_id: 345}), stream_name: 'order_3')
      response = client.read.from(:head).limit(2).each.to_a
      expect(response.length).to eq 2
      expect(response[0].data[:order_id]).to eq 123
      expect(response[1].data[:order_id]).to eq 234
    end

    specify 'return batch of events from given event ordered forward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      uid = SecureRandom.uuid
      client.publish_event(OrderCreated.new(event_id: uid, data: {order_id: 123}), stream_name: 'order_1')
      client.publish_event(OrderCreated.new(data: {order_id: 234}), stream_name: 'order_2')
      client.publish_event(OrderCreated.new(data: {order_id: 345}), stream_name: 'order_3')
      response = client.read.from(uid).limit(1).each.to_a
      expect(response.length).to eq 1
      expect(response[0].data[:order_id]).to eq 234
    end

    specify 'return all events ordered backward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client.publish_event(OrderCreated.new(data: {order_id: 123}), stream_name: 'order_1')
      client.publish_event(OrderCreated.new(data: {order_id: 234}), stream_name: 'order_1')
      response = client.read.backward.limit(100).each.to_a
      expect(response.length).to eq 2
      expect(response[0].data[:order_id]).to eq 234
      expect(response[1].data[:order_id]).to eq 123
    end

    specify 'return batch of events from the end ordered backward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client.publish_event(OrderCreated.new(data: {order_id: 123}), stream_name: 'order_1')
      client.publish_event(OrderCreated.new(data: {order_id: 234}), stream_name: 'order_2')
      client.publish_event(OrderCreated.new(data: {order_id: 345}), stream_name: 'order_3')
      response = client.read.backward.from(:head).limit(2).each.to_a
      expect(response.length).to eq 2
      expect(response[0].data[:order_id]).to eq 345
      expect(response[1].data[:order_id]).to eq 234
    end

    specify 'return batch of events from given event ordered backward' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      uid = SecureRandom.uuid
      client.publish_event(OrderCreated.new(data: {order_id: 123}), stream_name: 'order_1')
      client.publish_event(OrderCreated.new(event_id: uid, data: {order_id: 234}), stream_name: 'order_2')
      client.publish_event(OrderCreated.new(data: {order_id: 345}), stream_name: 'order_3')
      response = client.read.backward.from(uid).limit(1).each.to_a
      expect(response.length).to eq 1
      expect(response[0].data[:order_id]).to eq 123
    end

    specify 'fails when starting event not exists' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client.publish_event(OrderCreated.new(data: {order_id: 123}), stream_name: 'order_1')
      expect { client.read.from(SecureRandom.uuid).limit(100).each.to_a }.to raise_error(EventNotFound)
      expect { client.read.backward.from(SecureRandom.uuid).limit(100).each.to_a }.to raise_error(EventNotFound)
    end

    specify 'fails when page size is invalid' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client.publish_event(OrderCreated.new(data: {order_id: 123}), stream_name: 'order_1')
      expect { client.read.limit(0).each.to_a }.to raise_error(InvalidPageSize)
      expect { client.read.backward.limit(0).each.to_a }.to raise_error(InvalidPageSize)
      expect { client.read.limit(-1).each.to_a }.to raise_error(InvalidPageSize)
      expect { client.read.backward.limit(-1).each.to_a }.to raise_error(InvalidPageSize)
    end

    specify 'create successfully event' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = OrderCreated.new(event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd')
      client.append_to_stream(event, stream_name: 'stream_name')
      saved_events = client.read.stream("stream_name").each.to_a
      expect(saved_events[0]).to eq(event)
    end

    specify 'generate guid and create successfully event' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = OrderCreated.new
      client.append_to_stream(event, stream_name: 'stream_name')
      saved_events = client.read.stream("stream_name").each.to_a
      expect(saved_events[0]).to eq(event)
    end

    specify 'raise exception if expected version incorrect' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = OrderCreated.new
      client.append_to_stream(event, stream_name: 'stream_name')
      expect { client.publish_event(event, stream_name: 'stream_name', expected_version: 100) }.to raise_error(WrongExpectedEventVersion)
    end

    specify 'create event with optimistic locking' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = OrderCreated.new(event_id: 'b2d506fd-409d-4ec7-b02f-c6d2295c7edd')
      client.append_to_stream(event, stream_name: 'stream_name')

      event = OrderCreated.new(event_id: '724dd49d-6e20-40e6-bc32-ed75258f886b')
      client.append_to_stream(event, stream_name: 'stream_name', expected_version: 0)
    end

    specify 'expect no event handler is called' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      handler = double(:event_handler)
      expect(handler).not_to receive(:call)
      event = OrderCreated.new
      client.subscribe_to_all_events(handler)
      client.append_to_stream(event, stream_name: 'stream_name')
      saved_events = client.read.stream("stream_name").each.to_a
      expect(saved_events[0]).to eq(event)
    end

    specify 'expect publish to call event handlers' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      handler = double(:event_handler)
      expect(handler).to receive(:call)
      event = OrderCreated.new
      client.subscribe_to_all_events(handler)
      client.publish_event(event, stream_name: 'stream_name')
      saved_events = client.read.stream("stream_name").each.to_a
      expect(saved_events[0]).to eq(event)
    end

    specify 'create global event without stream name' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      event = OrderCreated.new
      client.publish_event(event)
      saved_events = client.read.limit(100).each.to_a
      expect(saved_events[0]).to eq(event)
    end

    specify 'append_to_stream fail if expected version is nil' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)

      expect do
        client.append_to_stream(event = OrderCreated.new, stream_name: 'stream', expected_version: nil)
      end.to raise_error(RubyEventStore::InvalidExpectedVersion)
    end

    specify 'link_to_stream fail if expected version is nil' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      client.append_to_stream(event = OrderCreated.new, stream_name: 'stream', expected_version: :any)

      expect do
        client.link_to_stream(event.event_id, stream_name: 'stream', expected_version: nil)
      end.to raise_error(RubyEventStore::InvalidExpectedVersion)
    end

    specify 'GLOBAL_STREAM is unordered, one cannot expect specific version number to work' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect do
        client.append_to_stream(OrderCreated.new, expected_version: 42)
      end.to raise_error(RubyEventStore::InvalidExpectedVersion)
    end

    specify 'GLOBAL_STREAM is unordered, one cannot expect :none to work' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect do
        client.append_to_stream(OrderCreated.new, expected_version: :none)
      end.to raise_error(RubyEventStore::InvalidExpectedVersion)
    end

    specify 'GLOBAL_STREAM is unordered, one cannot expect :auto to work' do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect do
        client.append_to_stream(OrderCreated.new, expected_version: :auto)
      end.to raise_error(RubyEventStore::InvalidExpectedVersion)
    end

    specify "only :none, :any, :auto and Integer allowed as expected_version" do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)

      [Object.new, SecureRandom.uuid, :foo].each do |invalid_expected_version|
        expect do
          client.append_to_stream(
            OrderCreated.new(event_id: SecureRandom.uuid),
            stream_name: "some_stream",
            expected_version: invalid_expected_version
          )
        end.to raise_error(RubyEventStore::InvalidExpectedVersion)
      end
    end

    specify "only :none, :any, :auto and Integer allowed as expected_version when linking" do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)

      [Object.new, SecureRandom.uuid, :foo].each do |invalid_expected_version|
        client.append_to_stream(
          OrderCreated.new(event_id: evid = SecureRandom.uuid),
          stream_name: SecureRandom.uuid,
          expected_version: :none
        )
        expect do
          client.link_to_stream(evid, stream_name: SecureRandom.uuid, expected_version: invalid_expected_version)
        end.to raise_error(RubyEventStore::InvalidExpectedVersion)
      end
    end

    specify "public read" do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)

      expect(client).to respond_to(:read)
      expect(client.read.each.to_a).to eq([])
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_all_streams_forward }.to output(<<~EOS).to_stderr
        RubyEventStore::Client#read_all_streams_forward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.limit(count).from(start).each.to_a
      EOS
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      silence_warnings { expect(client.read_all_streams_forward).to be_kind_of(Array) }
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_all_streams_backward }.to output(<<~EOS).to_stderr
        RubyEventStore::Client#read_all_streams_backward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.limit(count).from(start).backward.each.to_a
      EOS
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      silence_warnings { expect(client.read_all_streams_backward).to be_kind_of(Array) }
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_stream_events_forward('some_stream') }.to output(<<~EOS).to_stderr
        RubyEventStore::Client#read_stream_events_forward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).each.to_a
      EOS
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      silence_warnings { expect(client.read_stream_events_forward('some_stream')).to be_kind_of(Array) }
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_stream_events_backward('some_stream') }.to output(<<~EOS).to_stderr
        RubyEventStore::Client#read_stream_events_backward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).backward.each.to_a
      EOS
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      silence_warnings { expect(client.read_stream_events_backward('some_stream')).to be_kind_of(Array) }
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_events_forward('some_stream') }.to output(<<~EOS).to_stderr
        RubyEventStore::Client#read_events_forward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).limit(count).from(start).each.to_a
      EOS
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      silence_warnings { expect(client.read_events_forward('some_stream')).to be_kind_of(Array) }
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      expect { client.read_events_backward('some_stream') }.to output(<<~EOS).to_stderr
        RubyEventStore::Client#read_events_backward has been deprecated.

        Use following fluent API to receive exact results:
        client.read.stream(stream_name).limit(count).from(start).backward.each.to_a
      EOS
    end

    specify do
      client = RubyEventStore::Client.new(repository: InMemoryRepository.new)
      silence_warnings { expect(client.read_events_backward('some_stream')).to be_kind_of(Array) }
    end
  end
end
