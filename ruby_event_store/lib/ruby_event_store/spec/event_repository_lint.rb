RSpec.shared_examples :event_repository do |repository_class|
  TestDomainEvent = Class.new(RubyEventStore::Event)
  let(:repository) { subject || repository_class.new }

  it 'just created is empty' do
    expect(repository.read_all_streams_forward(:head, 1)).to be_empty
  end

  specify 'append_to_stream fail if expected version is nil' do
    expect do
      repository.append_to_stream(event = TestDomainEvent.new, 'stream', nil)
    end.to raise_error(RubyEventStore::InvalidExpectedVersion)
  end

  specify 'link_to_stream fail if expected version is nil' do
    skip unless test_link_events_to_stream
    repository.append_to_stream(event = TestDomainEvent.new, 'stream', :any)
    expect do
      repository.link_to_stream(event.event_id, 'stream', nil)
    end.to raise_error(RubyEventStore::InvalidExpectedVersion)
  end

  specify 'append_to_stream returns self' do
    repository.
      append_to_stream(event = TestDomainEvent.new, 'stream', -1).
      append_to_stream(event = TestDomainEvent.new, 'stream', 0)
  end

  specify 'link_to_stream returns self' do
    skip unless test_link_events_to_stream
    event0 = TestDomainEvent.new
    event1 = TestDomainEvent.new
    repository.
      append_to_stream([event0, event1], 'stream0', -1).
      link_to_stream(event0.event_id, 'flow', -1).
      link_to_stream(event1.event_id, 'flow', 0)
  end

  specify 'adds an initial event to a new stream' do
    repository.append_to_stream(event = TestDomainEvent.new, 'stream', :none)
    expect(repository.read_all_streams_forward(:head, 1).first).to eq(event)
    expect(repository.read_stream_events_forward('stream').first).to eq(event)
    expect(repository.read_stream_events_forward('other_stream')).to be_empty
  end

  specify 'links an initial event to a new stream' do
    skip unless test_link_events_to_stream
    repository.
      append_to_stream(event = TestDomainEvent.new, 'stream', :none).
      link_to_stream(event.event_id, 'flow', :none)

    expect(repository.read_all_streams_forward(:head, 1).first).to eq(event)
    expect(repository.read_stream_events_forward('stream').first).to eq(event)
    expect(repository.read_stream_events_forward('flow')).to eq([event])
    expect(repository.read_stream_events_forward('other')).to be_empty
  end

  specify 'adds multiple initial events to a new stream' do
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :none)
    expect(repository.read_all_streams_forward(:head, 2)).to eq([event0, event1])
    expect(repository.read_stream_events_forward('stream')).to eq([event0, event1])
  end

  specify 'links multiple initial events to a new stream' do
    skip unless test_link_events_to_stream
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :none).link_to_stream([
      event0.event_id,
      event1.event_id,
    ], 'flow', :none)
    expect(repository.read_all_streams_forward(:head, 2)).to eq([event0, event1])
    expect(repository.read_stream_events_forward('flow')).to eq([event0, event1])
  end

  specify 'correct expected version on second write' do
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :none)
    repository.append_to_stream([
      event2 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event3 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', 1)
    expect(repository.read_all_streams_forward(:head, 4)).to eq([event0, event1, event2, event3])
    expect(repository.read_stream_events_forward('stream')).to eq([event0, event1, event2, event3])
  end

  specify 'correct expected version on second link' do
    skip unless test_link_events_to_stream
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :none).append_to_stream([
      event2 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event3 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'flow', :none).link_to_stream([
      event0.event_id,
      event1.event_id,
    ], 'flow', 1)
    expect(repository.read_all_streams_forward(:head, 4)).to eq([event0, event1, event2, event3])
    expect(repository.read_stream_events_forward('flow')).to eq([event2, event3, event0, event1])
  end

  specify 'incorrect expected version on second write' do
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :none)
    expect do
      repository.append_to_stream([
        event2 = TestDomainEvent.new(event_id: SecureRandom.uuid),
        event3 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      ], 'stream', 0)
    end.to raise_error(RubyEventStore::WrongExpectedEventVersion)

    expect(repository.read_all_streams_forward(:head, 4)).to eq([event0, event1])
    expect(repository.read_stream_events_forward('stream')).to eq([event0, event1])
  end

  specify 'incorrect expected version on second link' do
    skip unless test_link_events_to_stream
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :none)
    repository.append_to_stream([
      event2 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event3 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'other', 0)
    expect do
      repository.link_to_stream([
        event2.event_id,
        event3.event_id,
      ], 'stream', 0)
    end.to raise_error(RubyEventStore::WrongExpectedEventVersion)

    expect(repository.read_all_streams_forward(:head, 4)).to eq([event0, event1, event2, event3])
    expect(repository.read_stream_events_forward('stream')).to eq([event0, event1])
  end

  specify ':none on first and subsequent write' do
    repository.append_to_stream([
      eventA = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :none)
    expect do
      repository.append_to_stream([
        eventB = TestDomainEvent.new(event_id: SecureRandom.uuid),
      ], 'stream', :none)
    end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
    expect(repository.read_all_streams_forward(:head, 1)).to eq([eventA])
    expect(repository.read_stream_events_forward('stream')).to eq([eventA])
  end

  specify ':none on first and subsequent link' do
    skip unless test_link_events_to_stream
    repository.append_to_stream([
      eventA = TestDomainEvent.new(event_id: SecureRandom.uuid),
      eventB = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :none)

    repository.link_to_stream([eventA.event_id], 'flow', :none)
    expect do
      repository.link_to_stream([eventB.event_id], 'flow', :none)
    end.to raise_error(RubyEventStore::WrongExpectedEventVersion)

    expect(repository.read_all_streams_forward(:head, 1)).to eq([eventA])
    expect(repository.read_stream_events_forward('flow')).to eq([eventA])
  end

  specify ':any allows stream with best-effort order and no guarantee' do
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :any)
    repository.append_to_stream([
      event2 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event3 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :any)
    expect(repository.read_all_streams_forward(:head, 4).to_set).to eq(Set.new([event0, event1, event2, event3]))
    expect(repository.read_stream_events_forward('stream').to_set).to eq(Set.new([event0, event1, event2, event3]))
  end

  specify ':any allows linking in stream with best-effort order and no guarantee' do
    skip unless test_link_events_to_stream
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event2 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event3 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :any)

    repository.link_to_stream([
      event0.event_id, event1.event_id,
    ], 'flow', :any)
    repository.link_to_stream([
      event2.event_id, event3.event_id,
    ], 'flow', :any)

    expect(repository.read_all_streams_forward(:head, 4).to_set).to eq(Set.new([event0, event1, event2, event3]))
    expect(repository.read_stream_events_forward('flow').to_set).to eq(Set.new([event0, event1, event2, event3]))
  end

  specify ':auto queries for last position in given stream' do
    skip unless test_expected_version_auto
    repository.append_to_stream([
      eventA = TestDomainEvent.new(event_id: SecureRandom.uuid),
      eventB = TestDomainEvent.new(event_id: SecureRandom.uuid),
      eventC = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'another', :auto)
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :auto)
    repository.append_to_stream([
      event2 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event3 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', 1)
  end

  specify ':auto queries for last position in given stream when linking' do
    skip unless test_expected_version_auto
    skip unless test_link_events_to_stream
    repository.append_to_stream([
      eventA = TestDomainEvent.new(event_id: SecureRandom.uuid),
      eventB = TestDomainEvent.new(event_id: SecureRandom.uuid),
      eventC = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'another', :auto)
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :auto)
    repository.link_to_stream([
      eventA.event_id,
      eventB.event_id,
      eventC.event_id,
    ], 'stream', 1)
  end

  specify ':auto starts from 0' do
    skip unless test_expected_version_auto
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :auto)
    expect do
      repository.append_to_stream([
        event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      ], 'stream', -1)
    end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
  end

  specify ':auto linking starts from 0' do
    skip unless test_expected_version_auto
    skip unless test_link_events_to_stream
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'whatever', :auto)
    repository.link_to_stream([
      event0.event_id,
    ], 'stream', :auto)
    expect do
      repository.append_to_stream([
        event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      ], 'stream', -1)
    end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
  end

  specify ':auto queries for last position and follows in incremental way' do
    skip unless test_expected_version_auto
    # It is expected that there is higher level lock
    # So this query is safe from race conditions
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :auto)
    repository.append_to_stream([
      event2 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event3 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :auto)
    expect(repository.read_all_streams_forward(:head, 4)).to eq([
      event0, event1,
      event2, event3
    ])
    expect(repository.read_stream_events_forward('stream')).to eq([event0, event1, event2, event3])
  end

  specify ':auto is compatible with manual expectation' do
    skip unless test_expected_version_auto
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :auto)
    repository.append_to_stream([
      event2 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event3 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', 1)
    expect(repository.read_all_streams_forward(:head, 4)).to eq([event0, event1, event2, event3])
    expect(repository.read_stream_events_forward('stream')).to eq([event0, event1, event2, event3])
  end

  specify 'manual is compatible with auto expectation' do
    skip unless test_expected_version_auto
    repository.append_to_stream([
      event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :none)
    repository.append_to_stream([
      event2 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      event3 = TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :auto)
    expect(repository.read_all_streams_forward(:head, 4)).to eq([event0, event1, event2, event3])
    expect(repository.read_stream_events_forward('stream')).to eq([event0, event1, event2, event3])
  end

  specify 'unlimited concurrency for :any - everything should succeed' do
    skip unless test_race_conditions_any
    verify_conncurency_assumptions
    begin
      concurrency_level = 4

      fail_occurred = false
      wait_for_it  = true

      threads = concurrency_level.times.map do |i|
        Thread.new do
          true while wait_for_it
          begin
            100.times do |j|
              eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
              repository.append_to_stream([
                TestDomainEvent.new(event_id: eid),
              ], 'stream', :any)
            end
          rescue RubyEventStore::WrongExpectedEventVersion
            fail_occurred = true
          end
        end
      end
      wait_for_it = false
      threads.each(&:join)
      expect(fail_occurred).to eq(false)
      expect(repository.read_stream_events_forward('stream').size).to eq(400)
      events_in_stream = repository.read_stream_events_forward('stream')
      expect(events_in_stream.size).to eq(400)
      events0 = events_in_stream.select do |ev|
        ev.event_id.start_with?("0-")
      end
      expect(events0).to eq(events0.sort_by{|ev| ev.event_id })
    ensure
      cleanup_concurrency_test
    end
  end

  specify 'limited concurrency for :auto - some operations will fail without outside lock, stream is ordered' do
    skip unless test_expected_version_auto
    skip unless test_race_conditions_auto
    verify_conncurency_assumptions
    begin
      concurrency_level = 4

      fail_occurred = 0
      wait_for_it  = true

      threads = concurrency_level.times.map do |i|
        Thread.new do
          true while wait_for_it
          100.times do |j|
            begin
              eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
              repository.append_to_stream([
                TestDomainEvent.new(event_id: eid),
              ], 'stream', :auto)
              sleep(rand(concurrency_level) / 1000.0)
            rescue RubyEventStore::WrongExpectedEventVersion
              fail_occurred +=1
            end
          end
        end
      end
      wait_for_it = false
      threads.each(&:join)
      expect(fail_occurred).to be > 0
      events_in_stream = repository.read_stream_events_forward('stream')
      expect(events_in_stream.size).to be < 400
      expect(events_in_stream.size).to be >= 100
      events0 = events_in_stream.select do |ev|
        ev.event_id.start_with?("0-")
      end
      expect(events0).to eq(events0.sort_by{|ev| ev.event_id })
      additional_limited_concurrency_for_auto_check
    ensure
      cleanup_concurrency_test
    end
  end

  it 'appended event is stored in given stream' do
    expected_event = TestDomainEvent.new(data: {})
    repository.append_to_stream(expected_event, 'stream', :any)
    expect(repository.read_all_streams_forward(:head, 1).first).to eq(expected_event)
    expect(repository.read_stream_events_forward('stream').first).to eq(expected_event)
    expect(repository.read_stream_events_forward('other_stream')).to be_empty
  end

  it 'data attributes are retrieved' do
    event = TestDomainEvent.new(data: { order_id: 3 })
    repository.append_to_stream(event, 'stream', :any)
    retrieved_event = repository.read_all_streams_forward(:head, 1).first
    expect(retrieved_event.data[:order_id]).to eq(3)
  end

  it 'metadata attributes are retrieved' do
    event = TestDomainEvent.new(metadata: { request_id: 3 })
    repository.append_to_stream(event, 'stream', :any)
    retrieved_event = repository.read_all_streams_forward(:head, 1).first
    expect(retrieved_event.metadata[:request_id]).to eq(3)
  end

  it 'does not have deleted streams' do
    repository.append_to_stream(e1 = TestDomainEvent.new, 'stream', -1)
    repository.append_to_stream(e2 = TestDomainEvent.new, 'other_stream', -1)

    repository.delete_stream('stream')
    expect(repository.read_stream_events_forward('stream')).to be_empty
    expect(repository.read_stream_events_forward('other_stream')).to eq([e2])
    expect(repository.read_all_streams_forward(:head, 10)).to eq([e1,e2])
  end

  it 'has or has not domain event' do
    just_an_id = 'd5c134c2-db65-4e87-b6ea-d196f8f1a292'
    repository.append_to_stream(TestDomainEvent.new(event_id: just_an_id), 'stream', -1)

    expect(repository.has_event?(just_an_id)).to be_truthy
    expect(repository.has_event?(just_an_id.clone)).to be_truthy
    expect(repository.has_event?('any other id')).to be_falsey
  end

  it 'knows last event in stream' do
    repository.append_to_stream(TestDomainEvent.new(event_id: '00000000-0000-0000-0000-000000000001'), 'stream', -1)
    repository.append_to_stream(TestDomainEvent.new(event_id: '00000000-0000-0000-0000-000000000002'), 'stream', 0)

    expect(repository.last_stream_event('stream')).to eq(TestDomainEvent.new(event_id: '00000000-0000-0000-0000-000000000002'))
    expect(repository.last_stream_event('other_stream')).to be_nil
  end

  it 'reads batch of events from stream forward & backward' do
    event_ids = ["96c920b1-cdd0-40f4-907c-861b9fff7d02", "56404f79-0ba0-4aa0-8524-dc3436368ca0", "6a54dd21-f9d8-4857-a195-f5588d9e406c", "0e50a9cd-f981-4e39-93d5-697fc7285b98", "d85589bc-b993-41d4-812f-fc631d9185d5", "96bdacda-77dd-4d7d-973d-cbdaa5842855", "94688199-e6b7-4180-bf8e-825b6808e6cc", "68fab040-741e-4bc2-9cca-5b8855b0ca19", "ab60114c-011d-4d58-ab31-7ba65d99975e", "868cac42-3d19-4b39-84e8-cd32d65c2445"]
    events = event_ids.map{|id| TestDomainEvent.new(event_id: id) }
    repository.append_to_stream(TestDomainEvent.new, 'other_stream', -1)
    events.each.with_index do |event, index|
      repository.append_to_stream(event, 'stream', index - 1)
    end
    repository.append_to_stream(TestDomainEvent.new, 'other_stream', 0)

    expect(repository.read_events_forward('stream', :head, 3)).to eq(events.first(3))
    expect(repository.read_events_forward('stream', :head, 100)).to eq(events)
    expect(repository.read_events_forward('stream', events[4].event_id, 4)).to eq(events[5..8])
    expect(repository.read_events_forward('stream', events[4].event_id, 100)).to eq(events[5..9])

    expect(repository.read_events_backward('stream', :head, 3)).to eq(events.last(3).reverse)
    expect(repository.read_events_backward('stream', :head, 100)).to eq(events.reverse)
    expect(repository.read_events_backward('stream', events[4].event_id, 4)).to eq(events.first(4).reverse)
    expect(repository.read_events_backward('stream', events[4].event_id, 100)).to eq(events.first(4).reverse)
  end


  it 'reads all stream events forward & backward' do
    s1 = 'stream'
    s2 = 'other_stream'
    repository.append_to_stream(a = TestDomainEvent.new(event_id: '7010d298-ab69-4bb1-9251-f3466b5d1282'), s1, -1)
    repository.append_to_stream(b = TestDomainEvent.new(event_id: '34f88aca-aaba-4ca0-9256-8017b47528c5'), s2, -1)
    repository.append_to_stream(c = TestDomainEvent.new(event_id: '8e61c864-ceae-4684-8726-97c34eb8fc4f'), s1, 0)
    repository.append_to_stream(d = TestDomainEvent.new(event_id: '30963ed9-6349-450b-ac9b-8ea50115b3bd'), s2, 0)
    repository.append_to_stream(e = TestDomainEvent.new(event_id: '5bdc58b7-e8a7-4621-afd6-ccb828d72457'), s2, 1)

    expect(repository.read_stream_events_forward(s1)).to eq [a,c]
    expect(repository.read_stream_events_backward(s1)).to eq [c,a]
  end

  it 'reads batch of events from all streams forward & backward' do
    event_ids = ["96c920b1-cdd0-40f4-907c-861b9fff7d02", "56404f79-0ba0-4aa0-8524-dc3436368ca0", "6a54dd21-f9d8-4857-a195-f5588d9e406c", "0e50a9cd-f981-4e39-93d5-697fc7285b98", "d85589bc-b993-41d4-812f-fc631d9185d5", "96bdacda-77dd-4d7d-973d-cbdaa5842855", "94688199-e6b7-4180-bf8e-825b6808e6cc", "68fab040-741e-4bc2-9cca-5b8855b0ca19", "ab60114c-011d-4d58-ab31-7ba65d99975e", "868cac42-3d19-4b39-84e8-cd32d65c2445"]
    events = event_ids.map{|id| TestDomainEvent.new(event_id: id) }
    events.each do |ev|
      repository.append_to_stream(ev, SecureRandom.uuid, -1)
    end

    expect(repository.read_all_streams_forward(:head, 3)).to eq(events.first(3))
    expect(repository.read_all_streams_forward(:head, 100)).to eq(events)
    expect(repository.read_all_streams_forward(events[4].event_id, 4)).to eq(events[5..8])
    expect(repository.read_all_streams_forward(events[4].event_id, 100)).to eq(events[5..9])

    expect(repository.read_all_streams_backward(:head, 3)).to eq(events.last(3).reverse)
    expect(repository.read_all_streams_backward(:head, 100)).to eq(events.reverse)
    expect(repository.read_all_streams_backward(events[4].event_id, 4)).to eq(events.first(4).reverse)
    expect(repository.read_all_streams_backward(events[4].event_id, 100)).to eq(events.first(4).reverse)
  end

  it 'reads events different uuid object but same content' do
    event_ids = [
      "96c920b1-cdd0-40f4-907c-861b9fff7d02",
      "56404f79-0ba0-4aa0-8524-dc3436368ca0"
    ]
    events = event_ids.map{|id| TestDomainEvent.new(event_id: id) }
    repository.append_to_stream(events.first, 'stream', -1)
    repository.append_to_stream(events.last,  'stream',  0)

    expect(repository.read_all_streams_forward("96c920b1-cdd0-40f4-907c-861b9fff7d02", 1)).to eq([events.last])
    expect(repository.read_all_streams_backward("56404f79-0ba0-4aa0-8524-dc3436368ca0", 1)).to eq([events.first])

    expect(repository.read_events_forward('stream', "96c920b1-cdd0-40f4-907c-861b9fff7d02", 1)).to eq([events.last])
    expect(repository.read_events_backward('stream', "56404f79-0ba0-4aa0-8524-dc3436368ca0", 1)).to eq([events.first])
  end

  it 'does not allow same event twice in a stream' do
    repository.append_to_stream(
      TestDomainEvent.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
      'stream',
      -1
    )
    expect do
      repository.append_to_stream(
        TestDomainEvent.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
        'stream',
        0
      )
    end.to raise_error(RubyEventStore::EventDuplicatedInStream)
  end

  it 'allows appending to GLOBAL_STREAM explicitly' do
    event = TestDomainEvent.new(event_id: "df8b2ba3-4e2c-4888-8d14-4364855fa80e")
    repository.append_to_stream(event, "all", :any)

    expect(repository.read_all_streams_forward(:head, 10)).to eq([event])
  end

  specify 'GLOBAL_STREAM is unordered, one cannot expect specific version number to work' do
    expect {
      event = TestDomainEvent.new(event_id: "df8b2ba3-4e2c-4888-8d14-4364855fa80e")
      repository.append_to_stream(event, "all", 42)
    }.to raise_error(RubyEventStore::InvalidExpectedVersion)
  end

  specify 'GLOBAL_STREAM is unordered, one cannot expect :none to work' do
    expect {
      event = TestDomainEvent.new(event_id: "df8b2ba3-4e2c-4888-8d14-4364855fa80e")
      repository.append_to_stream(event, "all", :none)
    }.to raise_error(RubyEventStore::InvalidExpectedVersion)
  end

  specify 'GLOBAL_STREAM is unordered, one cannot expect :auto to work' do
    expect {
      event = TestDomainEvent.new(event_id: "df8b2ba3-4e2c-4888-8d14-4364855fa80e")
      repository.append_to_stream(event, "all", :auto)
    }.to raise_error(RubyEventStore::InvalidExpectedVersion)
  end

  specify "only :none, :any, :auto and Integer allowed as expected_version" do
    [Object.new, SecureRandom.uuid, :foo].each do |invalid_expected_version|
      expect {
        repository.append_to_stream(
          TestDomainEvent.new(event_id: SecureRandom.uuid),
          'some_stream',
          invalid_expected_version
        )
      }.to raise_error(RubyEventStore::InvalidExpectedVersion)
    end
  end

  specify "events not persisted if append failed" do
    repository.append_to_stream([
      TestDomainEvent.new(event_id: SecureRandom.uuid),
    ], 'stream', :none)

    expect do
      repository.append_to_stream([
        TestDomainEvent.new(
          event_id: '9bedf448-e4d0-41a3-a8cd-f94aec7aa763'
        ),
      ], 'stream', :none)
    end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
    expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
  end

  specify "all stream always present" do
    expect(repository.get_all_streams).to match_array([RubyEventStore::Stream.new("all")])
  end

  specify "reading all existing stream names" do
    repository.append_to_stream(TestDomainEvent.new, "test", -1)
    repository.append_to_stream(TestDomainEvent.new, "test",  0)
    expect(repository.get_all_streams).to match_array([RubyEventStore::Stream.new("all"), RubyEventStore::Stream.new("test")])
  end

  specify 'reading particular event' do
    test_event = TestDomainEvent.new
    repository.append_to_stream(TestDomainEvent.new, "test", -1)
    repository.append_to_stream(test_event, "test", 0)

    expect(repository.read_event(test_event.event_id)).to eq(test_event)
  end

  specify 'reading non-existent event' do
    expect{repository.read_event('72922e65-1b32-4e97-8023-03ae81dd3a27')}.to raise_error(RubyEventStore::EventNotFound)
  end
end
