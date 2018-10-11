module RubyEventStore
  # @private
  class SRecord
    def self.new(
      event_id:   SecureRandom.uuid,
      data:       SecureRandom.uuid,
      metadata:   SecureRandom.uuid,
      event_type: SecureRandom.uuid
    )
      SerializedRecord.new(
        event_id:   event_id,
        data:       data,
        metadata:   metadata,
        event_type: event_type,
      )
    end
  end

  # @private
  Type1 = Class.new(RubyEventStore::Event)
  # @private
  Type2 = Class.new(RubyEventStore::Event)
  # @private
  Type3 = Class.new(RubyEventStore::Event)
end

module RubyEventStore
  RSpec.shared_examples :event_repository do |repository_class|
    let(:repository)    { subject || repository_class.new }
    let(:mapper)        { Mappers::NullMapper.new }
    let(:specification) { Specification.new(SpecificationReader.new(repository, mapper)) }
    let(:global_stream) { Stream.new(GLOBAL_STREAM) }
    let(:stream)        { Stream.new(SecureRandom.uuid) }
    let(:stream_flow)   { Stream.new('flow') }
    let(:stream_other)  { Stream.new('other') }
    let(:stream_test)   { Stream.new('test') }
    let(:version_none)  { ExpectedVersion.none }
    let(:version_auto)  { ExpectedVersion.auto }
    let(:version_any)   { ExpectedVersion.any }
    let(:version_0)     { ExpectedVersion.new(0) }
    let(:version_1)     { ExpectedVersion.new(1) }
    let(:version_2)     { ExpectedVersion.new(2) }
    let(:version_3)     { ExpectedVersion.new(3) }

    def read_stream_events_forward(repository, stream)
      repository.read(
        specification
          .stream(stream.name)
          .result
      ).to_a
    end

    def read_stream_events_backward(repository, stream)
      repository.read(
        specification
          .stream(stream.name)
          .backward
          .result
      ).to_a
    end

    def read_events_forward(repository, stream, start, count)
      repository.read(
        specification
          .stream(stream.name)
          .from(start)
          .limit(count)
          .result
      ).to_a
    end

    def read_events_backward(repository, stream, start, count)
      repository.read(
        specification
          .stream(stream.name)
          .from(start)
          .limit(count)
          .backward
          .result
      ).to_a
    end

    def read_all_streams_forward(repository, start, count)
      repository.read(
        specification
          .from(start)
          .limit(count)
          .result
      ).to_a
    end

    def read_all_streams_backward(repository, start, count)
      repository.read(
        specification
          .from(start)
          .limit(count)
          .backward
          .result
      ).to_a
    end

    it 'just created is empty' do
      expect(read_all_streams_forward(repository, :head, 1)).to be_empty
    end

    specify 'append_to_stream returns self' do
      repository.
        append_to_stream(event = SRecord.new, stream, version_none).
        append_to_stream(event = SRecord.new, stream, version_0)
    end

    specify 'link_to_stream returns self' do
      skip unless test_link_events_to_stream
      event0 = SRecord.new
      event1 = SRecord.new
      repository.
        append_to_stream([event0, event1], stream, version_none).
        link_to_stream(event0.event_id, stream_flow, version_none).
        link_to_stream(event1.event_id, stream_flow, version_0)
    end

    specify 'adds an initial event to a new stream' do
      repository.append_to_stream(event = SRecord.new, stream, version_none)
      expect(read_all_streams_forward(repository, :head, 1).first).to eq(event)
      expect(read_stream_events_forward(repository, stream).first).to eq(event)
      expect(read_stream_events_forward(repository, stream_other)).to be_empty
    end

    specify 'links an initial event to a new stream' do
      skip unless test_link_events_to_stream
      repository.
        append_to_stream(event = SRecord.new, stream, version_none).
        link_to_stream(event.event_id, stream_flow, version_none)

      expect(read_all_streams_forward(repository, :head, 1).first).to eq(event)
      expect(read_stream_events_forward(repository, stream).first).to eq(event)
      expect(read_stream_events_forward(repository, stream_flow)).to eq([event])
      expect(read_stream_events_forward(repository, stream_other)).to be_empty
    end

    specify 'adds multiple initial events to a new stream' do
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_none)
      expect(read_all_streams_forward(repository, :head, 2)).to eq([event0, event1])
      expect(read_stream_events_forward(repository, stream)).to eq([event0, event1])
    end

    specify 'links multiple initial events to a new stream' do
      skip unless test_link_events_to_stream
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_none).link_to_stream([
        event0.event_id,
        event1.event_id,
      ], stream_flow, version_none)
      expect(read_all_streams_forward(repository, :head, 2)).to eq([event0, event1])
      expect(read_stream_events_forward(repository, stream_flow)).to eq([event0, event1])
    end

    specify 'correct expected version on second write' do
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_none)
      repository.append_to_stream([
        event2 = SRecord.new,
        event3 = SRecord.new,
      ], stream, version_1)
      expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1, event2, event3])
      expect(read_stream_events_forward(repository, stream)).to eq([event0, event1, event2, event3])
    end

    specify 'correct expected version on second link' do
      skip unless test_link_events_to_stream
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_none).append_to_stream([
        event2 = SRecord.new,
        event3 = SRecord.new,
      ], stream_flow, version_none).link_to_stream([
        event0.event_id,
        event1.event_id,
      ], stream_flow, version_1)
      expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1, event2, event3])
      expect(read_stream_events_forward(repository, stream_flow)).to eq([event2, event3, event0, event1])
    end

    specify 'incorrect expected version on second write' do
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_none)
      expect do
        repository.append_to_stream([
          event2 = SRecord.new,
          event3 = SRecord.new,
        ], stream, version_0)
      end.to raise_error(WrongExpectedEventVersion)

      expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1])
      expect(read_stream_events_forward(repository, stream)).to eq([event0, event1])
    end

    specify 'incorrect expected version on second link' do
      skip unless test_link_events_to_stream
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_none)
      repository.append_to_stream([
        event2 = SRecord.new,
        event3 = SRecord.new,
      ], stream_other, version_none)
      expect do
        repository.link_to_stream([
          event2.event_id,
          event3.event_id,
        ], stream, version_0)
      end.to raise_error(WrongExpectedEventVersion)

      expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1, event2, event3])
      expect(read_stream_events_forward(repository, stream)).to eq([event0, event1])
    end

    specify ':none on first and subsequent write' do
      repository.append_to_stream([
        eventA = SRecord.new,
      ], stream, version_none)
      expect do
        repository.append_to_stream([
          eventB = SRecord.new,
        ], stream, version_none)
      end.to raise_error(WrongExpectedEventVersion)
      expect(read_all_streams_forward(repository, :head, 1)).to eq([eventA])
      expect(read_stream_events_forward(repository, stream)).to eq([eventA])
    end

    specify ':none on first and subsequent link' do
      skip unless test_link_events_to_stream
      repository.append_to_stream([
        eventA = SRecord.new,
        eventB = SRecord.new,
      ], stream, version_none)

      repository.link_to_stream([eventA.event_id], stream_flow, version_none)
      expect do
        repository.link_to_stream([eventB.event_id], stream_flow, version_none)
      end.to raise_error(WrongExpectedEventVersion)

      expect(read_all_streams_forward(repository, :head, 1)).to eq([eventA])
      expect(read_stream_events_forward(repository, stream_flow)).to eq([eventA])
    end

    specify ':any allows stream with best-effort order and no guarantee' do
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_any)
      repository.append_to_stream([
        event2 = SRecord.new,
        event3 = SRecord.new,
      ], stream, version_any)
      expect(read_all_streams_forward(repository, :head, 4).to_set).to eq(Set.new([event0, event1, event2, event3]))
      expect(read_stream_events_forward(repository, stream).to_set).to eq(Set.new([event0, event1, event2, event3]))
    end

    specify ':any allows linking in stream with best-effort order and no guarantee' do
      skip unless test_link_events_to_stream
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
        event2 = SRecord.new,
        event3 = SRecord.new,
      ], stream, version_any)

      repository.link_to_stream([
        event0.event_id, event1.event_id,
      ], stream_flow, version_any)
      repository.link_to_stream([
        event2.event_id, event3.event_id,
      ], stream_flow, version_any)

      expect(read_all_streams_forward(repository, :head, 4).to_set).to eq(Set.new([event0, event1, event2, event3]))
      expect(read_stream_events_forward(repository, stream_flow).to_set).to eq(Set.new([event0, event1, event2, event3]))
    end

    specify ':auto queries for last position in given stream' do
      skip unless test_expected_version_auto
      repository.append_to_stream([
        eventA = SRecord.new,
        eventB = SRecord.new,
        eventC = SRecord.new,
      ], stream_other, version_auto)
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_auto)
      repository.append_to_stream([
        event2 = SRecord.new,
        event3 = SRecord.new,
      ], stream, version_1)
    end

    specify ':auto queries for last position in given stream when linking' do
      skip unless test_expected_version_auto
      skip unless test_link_events_to_stream
      repository.append_to_stream([
        eventA = SRecord.new,
        eventB = SRecord.new,
        eventC = SRecord.new,
      ], stream_other, version_auto)
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_auto)
      repository.link_to_stream([
        eventA.event_id,
        eventB.event_id,
        eventC.event_id,
      ], stream, version_1)
    end

    specify ':auto starts from 0' do
      skip unless test_expected_version_auto
      repository.append_to_stream([
        event0 = SRecord.new,
      ], stream, version_auto)
      expect do
        repository.append_to_stream([
          event1 = SRecord.new,
        ], stream, version_none)
      end.to raise_error(WrongExpectedEventVersion)
    end

    specify ':auto linking starts from 0' do
      skip unless test_expected_version_auto
      skip unless test_link_events_to_stream
      repository.append_to_stream([
        event0 = SRecord.new,
      ], stream_other, version_auto)
      repository.link_to_stream([
        event0.event_id,
      ], stream, version_auto)
      expect do
        repository.append_to_stream([
          event1 = SRecord.new,
        ], stream, version_none)
      end.to raise_error(WrongExpectedEventVersion)
    end

    specify ':auto queries for last position and follows in incremental way' do
      skip unless test_expected_version_auto
      # It is expected that there is higher level lock
      # So this query is safe from race conditions
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_auto)
      repository.append_to_stream([
        event2 = SRecord.new,
        event3 = SRecord.new,
      ], stream, version_auto)
      expect(read_all_streams_forward(repository, :head, 4)).to eq([
        event0, event1,
        event2, event3
      ])
      expect(read_stream_events_forward(repository, stream)).to eq([event0, event1, event2, event3])
    end

    specify ':auto queries for last position and follows in incremental way when linking' do
      skip unless test_expected_version_auto
      skip unless test_link_events_to_stream
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
        event2 = SRecord.new,
        event3 = SRecord.new,
      ], stream, version_auto)
      repository.link_to_stream([
        event0.event_id, event1.event_id,
      ], stream_flow, version_auto)
      repository.link_to_stream([
        event2.event_id, event3.event_id,
      ], stream_flow, version_auto)
      expect(read_all_streams_forward(repository, :head, 4)).to eq([
        event0, event1,
        event2, event3
      ])
      expect(read_stream_events_forward(repository, stream_flow)).to eq([event0, event1, event2, event3])
    end

    specify ':auto is compatible with manual expectation' do
      skip unless test_expected_version_auto
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_auto)
      repository.append_to_stream([
        event2 = SRecord.new,
        event3 = SRecord.new,
      ], stream, version_1)
      expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1, event2, event3])
      expect(read_stream_events_forward(repository, stream)).to eq([event0, event1, event2, event3])
    end

    specify ':auto is compatible with manual expectation when linking' do
      skip unless test_expected_version_auto
      skip unless test_link_events_to_stream
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_auto)
      repository.link_to_stream([
        event0.event_id,
      ], stream_flow, version_auto)
      repository.link_to_stream([
        event1.event_id,
      ], stream_flow, version_0)
      expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1,])
      expect(read_stream_events_forward(repository, stream_flow)).to eq([event0, event1,])
    end

    specify 'manual is compatible with auto expectation' do
      skip unless test_expected_version_auto
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_none)
      repository.append_to_stream([
        event2 = SRecord.new,
        event3 = SRecord.new,
      ], stream, version_auto)
      expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1, event2, event3])
      expect(read_stream_events_forward(repository, stream)).to eq([event0, event1, event2, event3])
    end

    specify 'manual is compatible with auto expectation when linking' do
      skip unless test_expected_version_auto
      skip unless test_link_events_to_stream
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], stream, version_auto)
      repository.link_to_stream([
        event0.event_id,
      ], stream_flow, version_none)
      repository.link_to_stream([
        event1.event_id,
      ], stream_flow, version_auto)
      expect(read_all_streams_forward(repository, :head, 4)).to eq([event0, event1])
      expect(read_stream_events_forward(repository, stream_flow)).to eq([event0, event1])
    end

    specify 'unlimited concurrency for :any - everything should succeed', timeout: 10, mutant: false do
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
                  SRecord.new(event_id: eid),
                ], stream, version_any)
              end
            rescue WrongExpectedEventVersion
              fail_occurred = true
            end
          end
        end
        wait_for_it = false
        threads.each(&:join)
        expect(fail_occurred).to eq(false)
        expect(read_stream_events_forward(repository, stream).size).to eq(400)
        events_in_stream = read_stream_events_forward(repository, stream)
        expect(events_in_stream.size).to eq(400)
        events0 = events_in_stream.select do |ev|
          ev.event_id.start_with?("0-")
        end
        expect(events0).to eq(events0.sort_by{|ev| ev.event_id })
      ensure
        cleanup_concurrency_test
      end
    end

    specify 'unlimited concurrency for :any - everything should succeed when linking', timeout: 10, mutant: false do
      skip unless test_race_conditions_any
      skip unless test_link_events_to_stream
      verify_conncurency_assumptions
      begin
        concurrency_level = 4

        fail_occurred = false
        wait_for_it  = true

        concurrency_level.times.map do |i|
          100.times do |j|
            eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
            repository.append_to_stream([
              SRecord.new(event_id: eid),
            ], stream, version_any)
          end
        end

        threads = concurrency_level.times.map do |i|
          Thread.new do
            true while wait_for_it
            begin
              100.times do |j|
                eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
                repository.link_to_stream(eid, stream_flow, version_any)
              end
            rescue WrongExpectedEventVersion
              fail_occurred = true
            end
          end
        end
        wait_for_it = false
        threads.each(&:join)
        expect(fail_occurred).to eq(false)
        expect(read_stream_events_forward(repository, stream_flow).size).to eq(400)
        events_in_stream = read_stream_events_forward(repository, stream_flow)
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
                  SRecord.new(event_id: eid),
                ], stream, version_auto)
                sleep(rand(concurrency_level) / 1000.0)
              rescue WrongExpectedEventVersion
                fail_occurred +=1
              end
            end
          end
        end
        wait_for_it = false
        threads.each(&:join)
        expect(fail_occurred).to be > 0
        events_in_stream = read_stream_events_forward(repository, stream)
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

    specify 'limited concurrency for :auto - some operations will fail without outside lock, stream is ordered' do
      skip unless test_expected_version_auto
      skip unless test_race_conditions_auto
      skip unless test_link_events_to_stream

      verify_conncurency_assumptions
      begin
        concurrency_level = 4

        concurrency_level.times.map do |i|
          100.times do |j|
            eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
            repository.append_to_stream([
              SRecord.new(event_id: eid),
            ], stream_other, version_any)
          end
        end

        fail_occurred = 0
        wait_for_it  = true

        threads = concurrency_level.times.map do |i|
          Thread.new do
            true while wait_for_it
            100.times do |j|
              begin
                eid = "0000000#{i}-#{sprintf("%04d", j)}-0000-0000-000000000000"
                repository.link_to_stream(eid, stream, version_auto)
                sleep(rand(concurrency_level) / 1000.0)
              rescue WrongExpectedEventVersion
                fail_occurred +=1
              end
            end
          end
        end
        wait_for_it = false
        threads.each(&:join)
        expect(fail_occurred).to be > 0
        events_in_stream = read_stream_events_forward(repository, stream)
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
      expected_event = SRecord.new
      repository.append_to_stream(expected_event, stream, version_any)
      expect(read_all_streams_forward(repository, :head, 1).first).to eq(expected_event)
      expect(read_stream_events_forward(repository, stream).first).to eq(expected_event)
      expect(read_stream_events_forward(repository, stream_other)).to be_empty
    end

    it 'data attributes are retrieved' do
      event = SRecord.new(data: "{ order_id: 3 }")
      repository.append_to_stream(event, stream, version_any)
      retrieved_event = read_all_streams_forward(repository, :head, 1).first
      expect(retrieved_event.data).to eq("{ order_id: 3 }")
    end

    it 'metadata attributes are retrieved' do
      event = SRecord.new(metadata: "{ request_id: 3 }")
      repository.append_to_stream(event, stream, version_any)
      retrieved_event = read_all_streams_forward(repository, :head, 1).first
      expect(retrieved_event.metadata).to eq("{ request_id: 3 }")
    end

    it 'data and metadata attributes are retrieved when linking' do
      skip unless test_link_events_to_stream
      event = SRecord.new(
        data: "{ order_id: 3 }",
        metadata: "{ request_id: 4 }",
      )
      repository.
        append_to_stream(event, stream, version_any).
        link_to_stream(event.event_id, stream_flow, version_any)
      retrieved_event = read_stream_events_forward(repository, stream_flow).first
      expect(retrieved_event.metadata).to eq("{ request_id: 4 }")
      expect(retrieved_event.data).to eq("{ order_id: 3 }")
      expect(event).to eq(retrieved_event)
    end

    it 'does not have deleted streams' do
      repository.append_to_stream(e1 = SRecord.new, stream, version_none)
      repository.append_to_stream(e2 = SRecord.new, stream_other, version_none)

      repository.delete_stream(stream)
      expect(read_stream_events_forward(repository, stream)).to be_empty
      expect(read_stream_events_forward(repository, stream_other)).to eq([e2])
      expect(read_all_streams_forward(repository, :head, 10)).to eq([e1,e2])
    end

    it 'does not have deleted streams with linked events' do
      skip unless test_link_events_to_stream
      repository.
        append_to_stream(e1 = SRecord.new, stream, version_none).
        link_to_stream(e1.event_id, stream_flow, version_none)

      repository.delete_stream(stream_flow)
      expect(read_stream_events_forward(repository, stream_flow)).to be_empty
      expect(read_all_streams_forward(repository, :head, 10)).to eq([e1])
    end

    it 'has or has not domain event' do
      just_an_id = 'd5c134c2-db65-4e87-b6ea-d196f8f1a292'
      repository.append_to_stream(SRecord.new(event_id: just_an_id), stream, version_none)

      expect(repository.has_event?(just_an_id)).to be_truthy
      expect(repository.has_event?(just_an_id.clone)).to be_truthy
      expect(repository.has_event?('any other id')).to be_falsey

      repository.delete_stream(stream)
      expect(repository.has_event?(just_an_id)).to be_truthy
      expect(repository.has_event?(just_an_id.clone)).to be_truthy
    end

    it 'knows last event in stream' do
      repository.append_to_stream(a =SRecord.new(event_id: '00000000-0000-0000-0000-000000000001'), stream, version_none)
      repository.append_to_stream(b = SRecord.new(event_id: '00000000-0000-0000-0000-000000000002'), stream, version_0)

      expect(repository.last_stream_event(stream)).to eq(b)
      expect(repository.last_stream_event(stream_other)).to be_nil
    end

    it 'knows last event in stream when linked' do
      skip unless test_link_events_to_stream
      repository.append_to_stream([
          e0 = SRecord.new(event_id: '00000000-0000-0000-0000-000000000001'),
          e1 = SRecord.new(event_id: '00000000-0000-0000-0000-000000000002'),
        ],
        stream,
        version_none
      ).link_to_stream([e1.event_id, e0.event_id], stream_flow, version_none)
      expect(repository.last_stream_event(stream_flow)).to eq(e0)
    end

    it 'reads batch of events from stream forward & backward' do
      events = %w[
        96c920b1-cdd0-40f4-907c-861b9fff7d02
        56404f79-0ba0-4aa0-8524-dc3436368ca0
        6a54dd21-f9d8-4857-a195-f5588d9e406c
        0e50a9cd-f981-4e39-93d5-697fc7285b98
        d85589bc-b993-41d4-812f-fc631d9185d5
        96bdacda-77dd-4d7d-973d-cbdaa5842855
        94688199-e6b7-4180-bf8e-825b6808e6cc
        68fab040-741e-4bc2-9cca-5b8855b0ca19
        ab60114c-011d-4d58-ab31-7ba65d99975e
        868cac42-3d19-4b39-84e8-cd32d65c2445
      ].map { |id| SRecord.new(event_id: id) }
      repository.append_to_stream(SRecord.new, stream_other, version_none)
      events.each.with_index do |event, index|
        repository.append_to_stream(event, stream, ExpectedVersion.new(index - 1))
      end
      repository.append_to_stream(SRecord.new, stream_other, version_0)

      expect(read_events_forward(repository, stream, :head, 3)).to eq(events.first(3))
      expect(read_events_forward(repository, stream, :head, 100)).to eq(events)
      expect(repository.read(specification.stream(stream.name).from(events[4].event_id).result).to_a).to eq(events[5..9])
      expect(read_events_forward(repository, stream, events[4].event_id, 4)).to eq(events[5..8])
      expect(read_events_forward(repository, stream, events[4].event_id, 100)).to eq(events[5..9])

      expect(read_events_backward(repository, stream, :head, 3)).to eq(events.last(3).reverse)
      expect(read_events_backward(repository, stream, :head, 100)).to eq(events.reverse)
      expect(read_events_backward(repository, stream, events[4].event_id, 4)).to eq(events.first(4).reverse)
      expect(read_events_backward(repository, stream, events[4].event_id, 100)).to eq(events.first(4).reverse)
    end

    it 'reads batch of linked events from stream forward & backward' do
      skip unless test_link_events_to_stream
      events = %w[
        96c920b1-cdd0-40f4-907c-861b9fff7d02
        56404f79-0ba0-4aa0-8524-dc3436368ca0
        6a54dd21-f9d8-4857-a195-f5588d9e406c
        0e50a9cd-f981-4e39-93d5-697fc7285b98
        d85589bc-b993-41d4-812f-fc631d9185d5
        96bdacda-77dd-4d7d-973d-cbdaa5842855
        94688199-e6b7-4180-bf8e-825b6808e6cc
        68fab040-741e-4bc2-9cca-5b8855b0ca19
        ab60114c-011d-4d58-ab31-7ba65d99975e
        868cac42-3d19-4b39-84e8-cd32d65c2445
      ].map { |id| SRecord.new(event_id: id) }
      repository.append_to_stream(SRecord.new, stream_other, version_none)
      events.each.with_index do |event, index|
        repository.
          append_to_stream(event, stream, ExpectedVersion.new(index - 1)).
          link_to_stream(event.event_id, stream_flow, ExpectedVersion.new(index - 1))
      end
      repository.append_to_stream(SRecord.new, stream_other, version_0)

      expect(read_events_forward(repository, stream_flow, :head, 3)).to eq(events.first(3))
      expect(read_events_forward(repository, stream_flow, :head, 100)).to eq(events)
      expect(read_events_forward(repository, stream_flow, events[4].event_id, 4)).to eq(events[5..8])
      expect(read_events_forward(repository, stream_flow, events[4].event_id, 100)).to eq(events[5..9])

      expect(read_events_backward(repository, stream_flow, :head, 3)).to eq(events.last(3).reverse)
      expect(read_events_backward(repository, stream_flow, :head, 100)).to eq(events.reverse)
      expect(read_events_backward(repository, stream_flow, events[4].event_id, 4)).to eq(events.first(4).reverse)
      expect(read_events_backward(repository, stream_flow, events[4].event_id, 100)).to eq(events.first(4).reverse)
    end

    it 'reads all stream events forward & backward' do
      s1 = stream
      s2 = stream_other
      repository.
        append_to_stream(a = SRecord.new(event_id: '7010d298-ab69-4bb1-9251-f3466b5d1282'), s1, version_none).
        append_to_stream(b = SRecord.new(event_id: '34f88aca-aaba-4ca0-9256-8017b47528c5'), s2, version_none).
        append_to_stream(c = SRecord.new(event_id: '8e61c864-ceae-4684-8726-97c34eb8fc4f'), s1, version_0).
        append_to_stream(d = SRecord.new(event_id: '30963ed9-6349-450b-ac9b-8ea50115b3bd'), s2, version_0).
        append_to_stream(e = SRecord.new(event_id: '5bdc58b7-e8a7-4621-afd6-ccb828d72457'), s2, version_1)

      expect(read_stream_events_forward(repository, s1)).to eq [a,c]
      expect(read_stream_events_backward(repository, s1)).to eq [c,a]
    end

    it 'reads all stream linked events forward & backward' do
      skip unless test_link_events_to_stream
      s1, fs1, fs2 = stream, stream_flow, stream_other
      repository.
        append_to_stream(a = SRecord.new(event_id: '7010d298-ab69-4bb1-9251-f3466b5d1282'), s1, version_none).
        append_to_stream(b = SRecord.new(event_id: '34f88aca-aaba-4ca0-9256-8017b47528c5'), s1, version_0).
        append_to_stream(c = SRecord.new(event_id: '8e61c864-ceae-4684-8726-97c34eb8fc4f'), s1, version_1).
        append_to_stream(d = SRecord.new(event_id: '30963ed9-6349-450b-ac9b-8ea50115b3bd'), s1, version_2).
        append_to_stream(e = SRecord.new(event_id: '5bdc58b7-e8a7-4621-afd6-ccb828d72457'), s1, version_3).
        link_to_stream('7010d298-ab69-4bb1-9251-f3466b5d1282', fs1, version_none).
        link_to_stream('34f88aca-aaba-4ca0-9256-8017b47528c5', fs2, version_none).
        link_to_stream('8e61c864-ceae-4684-8726-97c34eb8fc4f', fs1, version_0).
        link_to_stream('30963ed9-6349-450b-ac9b-8ea50115b3bd', fs2, version_0).
        link_to_stream('5bdc58b7-e8a7-4621-afd6-ccb828d72457', fs2, version_1)

      expect(read_stream_events_forward(repository, fs1)).to eq [a,c]
      expect(read_stream_events_backward(repository, fs1)).to eq [c,a]
    end

    it 'reads batch of events from all streams forward & backward' do
      events = %w[
        96c920b1-cdd0-40f4-907c-861b9fff7d02
        56404f79-0ba0-4aa0-8524-dc3436368ca0
        6a54dd21-f9d8-4857-a195-f5588d9e406c
        0e50a9cd-f981-4e39-93d5-697fc7285b98
        d85589bc-b993-41d4-812f-fc631d9185d5
        96bdacda-77dd-4d7d-973d-cbdaa5842855
        94688199-e6b7-4180-bf8e-825b6808e6cc
        68fab040-741e-4bc2-9cca-5b8855b0ca19
        ab60114c-011d-4d58-ab31-7ba65d99975e
        868cac42-3d19-4b39-84e8-cd32d65c2445
      ].map { |id| SRecord.new(event_id: id) }
      events.each do |ev|
        repository.append_to_stream(ev, Stream.new(SecureRandom.uuid), version_none)
      end

      expect(read_all_streams_forward(repository, :head, 3)).to eq(events.first(3))
      expect(read_all_streams_forward(repository, :head, 100)).to eq(events)
      expect(read_all_streams_forward(repository, events[4].event_id, 4)).to eq(events[5..8])
      expect(read_all_streams_forward(repository, events[4].event_id, 100)).to eq(events[5..9])

      expect(read_all_streams_backward(repository, :head, 3)).to eq(events.last(3).reverse)
      expect(read_all_streams_backward(repository, :head, 100)).to eq(events.reverse)
      expect(read_all_streams_backward(repository, events[4].event_id, 4)).to eq(events.first(4).reverse)
      expect(read_all_streams_backward(repository, events[4].event_id, 100)).to eq(events.first(4).reverse)
    end

    it 'linked events do not affect reading from all streams - no duplicates' do
      skip unless test_link_events_to_stream
      events = %w[
        96c920b1-cdd0-40f4-907c-861b9fff7d02
        56404f79-0ba0-4aa0-8524-dc3436368ca0
        6a54dd21-f9d8-4857-a195-f5588d9e406c
        0e50a9cd-f981-4e39-93d5-697fc7285b98
        d85589bc-b993-41d4-812f-fc631d9185d5
        96bdacda-77dd-4d7d-973d-cbdaa5842855
        94688199-e6b7-4180-bf8e-825b6808e6cc
        68fab040-741e-4bc2-9cca-5b8855b0ca19
        ab60114c-011d-4d58-ab31-7ba65d99975e
        868cac42-3d19-4b39-84e8-cd32d65c2445
      ].map { |id| SRecord.new(event_id: id) }
      events.each do |ev|
        repository.
          append_to_stream(ev, Stream.new(SecureRandom.uuid), version_none).
          link_to_stream(ev.event_id, Stream.new(SecureRandom.uuid), version_none)
      end

      expect(read_all_streams_forward(repository, :head, 3)).to eq(events.first(3))
      expect(read_all_streams_forward(repository, :head, 100)).to eq(events)
      expect(read_all_streams_forward(repository, events[4].event_id, 4)).to eq(events[5..8])
      expect(read_all_streams_forward(repository, events[4].event_id, 100)).to eq(events[5..9])

      expect(read_all_streams_backward(repository, :head, 3)).to eq(events.last(3).reverse)
      expect(read_all_streams_backward(repository, :head, 100)).to eq(events.reverse)
      expect(read_all_streams_backward(repository, events[4].event_id, 4)).to eq(events.first(4).reverse)
      expect(read_all_streams_backward(repository, events[4].event_id, 100)).to eq(events.first(4).reverse)
    end

    it 'reads events different uuid object but same content' do
      events = %w[
        96c920b1-cdd0-40f4-907c-861b9fff7d02
        56404f79-0ba0-4aa0-8524-dc3436368ca0
      ].map{|id| SRecord.new(event_id: id) }
      repository.append_to_stream(events.first, stream, version_none)
      repository.append_to_stream(events.last,  stream,  version_0)

      expect(read_all_streams_forward(repository, "96c920b1-cdd0-40f4-907c-861b9fff7d02", 1)).to eq([events.last])
      expect(read_all_streams_backward(repository, "56404f79-0ba0-4aa0-8524-dc3436368ca0", 1)).to eq([events.first])

      expect(read_events_forward(repository, stream, "96c920b1-cdd0-40f4-907c-861b9fff7d02", 1)).to eq([events.last])
      expect(read_events_backward(repository, stream, "56404f79-0ba0-4aa0-8524-dc3436368ca0", 1)).to eq([events.first])
    end

    it 'does not allow same event twice in a stream' do
      repository.append_to_stream(
        SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
        stream,
        version_none
      )
      expect do
        repository.append_to_stream(
          SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
          stream,
          version_0
        )
      end.to raise_error(EventDuplicatedInStream)
    end

    it 'does not allow same event twice' do
      repository.append_to_stream(
        SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
        stream,
        version_none
      )
      expect do
        repository.append_to_stream(
          SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
          stream_other,
          version_none
        )
      end.to raise_error(EventDuplicatedInStream)
    end

    it 'does not allow linking same event twice in a stream' do
      skip unless test_link_events_to_stream
      repository.append_to_stream([
          SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
        ], stream,
        version_none
      ).link_to_stream("a1b49edb-7636-416f-874a-88f94b859bef", stream_flow, version_none)
      expect do
        repository.link_to_stream("a1b49edb-7636-416f-874a-88f94b859bef", stream_flow, version_0)
      end.to raise_error(EventDuplicatedInStream)
    end

    it 'allows appending to GLOBAL_STREAM explicitly' do
      event = SRecord.new(event_id: "df8b2ba3-4e2c-4888-8d14-4364855fa80e")
      repository.append_to_stream(event, global_stream, version_any)

      expect(read_all_streams_forward(repository, :head, 10)).to eq([event])
    end

    specify "events not persisted if append failed" do
      repository.append_to_stream([
        SRecord.new,
      ], stream, version_none)

      expect do
        repository.append_to_stream([
          SRecord.new(
            event_id: '9bedf448-e4d0-41a3-a8cd-f94aec7aa763'
          ),
        ], stream, version_none)
      end.to raise_error(WrongExpectedEventVersion)
      expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
    end

    specify 'linking non-existent event' do
      skip unless test_link_events_to_stream
      expect do
        repository.link_to_stream('72922e65-1b32-4e97-8023-03ae81dd3a27', stream_flow, version_none)
      end.to raise_error do |err|
        expect(err).to be_a(EventNotFound)
        expect(err.event_id).to eq('72922e65-1b32-4e97-8023-03ae81dd3a27')
        expect(err.message).to eq('Event not found: 72922e65-1b32-4e97-8023-03ae81dd3a27')
      end
    end

    specify 'read returns enumerator' do
      expect(repository.read(specification.result)).to be_kind_of(Enumerator)
    end

    specify 'can store arbitrary binary data' do
      skip unless test_binary
      migrate_to_binary
      binary = "\xB0"
      expect(binary.valid_encoding?).to eq(false)
      binary.force_encoding("binary")
      expect(binary.valid_encoding?).to eq(true)

      repository.append_to_stream(
        event = SRecord.new(data: binary, metadata: binary),
        stream,
        version_none
      )
    end

    specify do
      events = Array.new(400) { SRecord.new }
      repository.append_to_stream(
        events[200...400],
        Stream.new("Foo"),
        ExpectedVersion.none
      )
      repository.append_to_stream(
        events[0...200],
        Stream.new("Dummy"),
        ExpectedVersion.none
      )

      batches = repository.read(specification.stream("Dummy").in_batches.result).to_a
      expect(batches.size).to eq(2)
      expect(batches[0].size).to eq(100)
      expect(batches[0]).to eq(events[0..99])
    end

    specify do
      events = Array.new(200) { SRecord.new }
      repository.append_to_stream(
        events,
        Stream.new(GLOBAL_STREAM),
        ExpectedVersion.any
      )

      batches = repository.read(specification.in_batches.result).to_a
      expect(batches.size).to eq(2)
      expect(batches[0].size).to eq(100)
      expect(batches[0]).to eq(events[0..99])
    end

    specify do
      events = Array.new(200) { SRecord.new }
      repository.append_to_stream(
        events,
        Stream.new(GLOBAL_STREAM),
        ExpectedVersion.any
      )

      expect(repository.read(specification.in_batches(200).result).to_a.size).to eq(1)
    end

    specify do
      events = Array.new(200) { SRecord.new }
      repository.append_to_stream(
        events,
        Stream.new(GLOBAL_STREAM),
        ExpectedVersion.any
      )

      batches = repository.read(specification.limit(199).in_batches.result).to_a
      expect(batches.size).to eq(2)
      expect(batches[0].size).to eq(100)
      expect(batches[0]).to eq(events[0..99])
      expect(batches[1].size).to eq(99)
      expect(batches[1]).to eq(events[100..198])
    end

    specify do
      events = Array.new(200) { SRecord.new }
      repository.append_to_stream(
        events,
        Stream.new(GLOBAL_STREAM),
        ExpectedVersion.any
      )

      batches = repository.read(specification.limit(99).in_batches.result).to_a
      expect(batches.size).to eq(1)
      expect(batches[0].size).to eq(99)
      expect(batches[0]).to eq(events[0..98])
    end

    specify do
      events = Array.new(200) { SRecord.new }
      repository.append_to_stream(
        events,
        Stream.new(GLOBAL_STREAM),
        ExpectedVersion.any
      )

      batches = repository.read(specification.backward.limit(99).in_batches.result).to_a
      expect(batches.size).to eq(1)
      expect(batches[0].size).to eq(99)
      expect(batches[0]).to eq(events[101..-1].reverse)
    end

    specify do
      events = Array.new(200) { SRecord.new }
      repository.append_to_stream(
        events,
        Stream.new(GLOBAL_STREAM),
        ExpectedVersion.any
      )

      batches = repository.read(specification.from(events[100].event_id).limit(99).in_batches.result).to_a
      expect(batches.size).to eq(1)
      expect(batches[0].size).to eq(99)
      expect(batches[0]).to eq(events[101..199])
    end

    specify do
      expect(repository.read(specification.read_first.result)).to be_nil
      expect(repository.read(specification.read_last.result)).to be_nil

      events = Array.new(5) { SRecord.new }
      repository.append_to_stream(
        events,
        Stream.new(GLOBAL_STREAM),
        ExpectedVersion.any
      )

      expect(repository.read(specification.stream("Any").read_first.result)).to be_nil
      expect(repository.read(specification.stream("Any").read_last.result)).to be_nil

      expect(repository.read(specification.read_first.result)).to eq(events[0])
      expect(repository.read(specification.read_last.result)).to eq(events[4])

      expect(repository.read(specification.backward.read_first.result)).to eq(events[4])
      expect(repository.read(specification.backward.read_last.result)).to eq(events[0])

      expect(repository.read(specification.from(events[2].event_id).read_first.result)).to eq(events[3])
      expect(repository.read(specification.from(events[2].event_id).read_last.result)).to eq(events[4])

      expect(repository.read(specification.from(events[2].event_id).backward.read_first.result)).to eq(events[1])
      expect(repository.read(specification.from(events[2].event_id).backward.read_last.result)).to eq(events[0])

      expect(repository.read(specification.from(events[4].event_id).read_first.result)).to be_nil
      expect(repository.read(specification.from(events[4].event_id).read_last.result)).to be_nil

      expect(repository.read(specification.from(events[0].event_id).backward.read_first.result)).to be_nil
      expect(repository.read(specification.from(events[0].event_id).backward.read_last.result)).to be_nil
    end

    context "#update_messages" do
      specify "changes events" do
        skip unless test_change
        events = Array.new(5) { SRecord.new }
        repository.append_to_stream(
          events[0..2],
          Stream.new("whatever"),
          ExpectedVersion.any
        )
        repository.append_to_stream(
          events[3..4],
          Stream.new("elo"),
          ExpectedVersion.any
        )
        repository.update_messages([
          a = SRecord.new(event_id: events[0].event_id.clone, data: events[0].data, metadata: events[0].metadata, event_type: events[0].event_type),
          b = SRecord.new(event_id: events[1].event_id.dup,   data: "data1",        metadata: events[1].metadata, event_type: events[1].event_type),
          c = SRecord.new(event_id: events[2].event_id,       data: events[2].data, metadata: "metadata2",        event_type: events[2].event_type),
          d = SRecord.new(event_id: events[3].event_id.clone, data: events[3].data, metadata: events[3].metadata, event_type: "event_type3"),
          e = SRecord.new(event_id: events[4].event_id.dup,   data: "data4",        metadata: "metadata4",        event_type: "event_type4"),
        ])
        expect(repository.read(specification.result).to_a).to eq([a,b,c,d,e])
        expect(repository.read(specification.stream("whatever").result).to_a).to eq([a,b,c])
        expect(repository.read(specification.stream("elo").result).to_a).to eq([d,e])
      end

      specify "cannot change unexisting event" do
        skip unless test_change
        e = SRecord.new
        expect{ repository.update_messages([e]) }.to raise_error do |err|
          expect(err).to be_a(EventNotFound)
          expect(err.event_id).to eq(e.event_id)
          expect(err.message).to eq("Event not found: #{e.event_id}")
        end
      end
    end

    specify do
      skip unless test_link_events_to_stream
      event_1 = SRecord.new
      event_2 = SRecord.new
      event_3 = SRecord.new
      event_4 = SRecord.new
      stream_a = Stream.new('Stream A')
      stream_b = Stream.new('Stream B')
      stream_c = Stream.new('Stream C')
      repository.append_to_stream([event_1, event_2], stream_a, version_any)
      repository.append_to_stream([event_3], stream_b, version_any)
      repository.link_to_stream(event_1.event_id, stream_c, version_none)

      expect(repository.streams_of(event_1.event_id)).to eq [stream_a, stream_c]
      expect(repository.streams_of(event_2.event_id)).to eq [stream_a]
      expect(repository.streams_of(event_3.event_id)).to eq [stream_b]
      expect(repository.streams_of(event_4.event_id)).to eq []
    end

    specify do
      e1 = SRecord.new(event_id: '8a6f053e-3ce2-4c82-a55b-4d02c66ae6ea')
      e2 = SRecord.new(event_id: '8cee1139-4f96-483a-a175-2b947283c3c7')
      e3 = SRecord.new(event_id: 'd345f86d-b903-4d78-803f-38990c078d9e')
      stream = Stream.new('Stream A')
      repository.append_to_stream([e1, e2, e3], stream, version_any)

      expect(repository.read(specification.with_id([
        '8a6f053e-3ce2-4c82-a55b-4d02c66ae6ea'
      ]).read_first.result)).to eq(e1)
      expect(repository.read(specification.with_id([
        'd345f86d-b903-4d78-803f-38990c078d9e'
      ]).read_first.result)).to eq(e3)
      expect(repository.read(specification.with_id([
        'c31b327c-0da1-4178-a3cd-d2f6bb5d0688'
      ]).read_first.result)).to eq(nil)
      expect(repository.read(specification.with_id([
        '8a6f053e-3ce2-4c82-a55b-4d02c66ae6ea',
        'd345f86d-b903-4d78-803f-38990c078d9e'
      ]).in_batches.result).to_a[0]).to eq([e1,e3])
    end

    specify do
      e1 = SRecord.new(event_type: Type1.to_s)
      e2 = SRecord.new(event_type: Type2.to_s)
      e3 = SRecord.new(event_type: Type1.to_s)
      stream = Stream.new('Stream A')
      repository.append_to_stream([e1, e2, e3], stream, version_any)

      expect(repository.read(specification.of_type([Type1]).result).to_a).to eq([e1,e3])
      expect(repository.read(specification.of_type([Type2]).result).to_a).to eq([e2])
      expect(repository.read(specification.of_type([Type3]).result).to_a).to eq([])
      expect(repository.read(specification.of_type([Type1, Type2, Type3]).result).to_a).to eq([e1,e2,e3])
    end
  end
end
