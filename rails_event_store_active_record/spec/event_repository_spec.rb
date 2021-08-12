require "spec_helper"
require "ruby_event_store"
require "ruby_event_store/spec/event_repository_lint"

module RailsEventStoreActiveRecord
  class EventRepository
    class SpecHelper
      def supports_concurrent_auto?
        !ENV["DATABASE_URL"].include?("sqlite")
      end

      def supports_concurrent_any?
        !ENV["DATABASE_URL"].include?("sqlite")
      end

      def supports_binary?
        true
      end

      def supports_upsert?
        true
      end

      def has_connection_pooling?
        true
      end

      def connection_pool_size
        ActiveRecord::Base.connection.pool.size
      end

      def cleanup_concurrency_test
        ActiveRecord::Base.connection_pool.disconnect!
      end

      def supports_position_queries?
        true
      end
    end
  end

  RSpec.describe EventRepository do
    helper = EventRepository::SpecHelper.new
    mk_repository = ->{ EventRepository.new(serializer: YAML) }

    it_behaves_like :event_repository, mk_repository, helper

    let(:time) { Time.now.utc }
    let(:repository) { mk_repository.call }

    include SchemaHelper
    around(:each) do |example|
      begin
        establish_database_connection
        load_database_schema
        example.run
      ensure
        drop_database
      end
    end

    let(:specification) do
      RubyEventStore::Specification.new(
        RubyEventStore::SpecificationReader.new(
          repository,
          RubyEventStore::Mappers::NullMapper.new
        )
      )
    end

    specify "nested transaction - events still not persisted if append failed" do
      repository.append_to_stream([
        event = RubyEventStore::SRecord.new(event_id: SecureRandom.uuid),
      ], RubyEventStore::Stream.new("stream"), RubyEventStore::ExpectedVersion.none)

      ActiveRecord::Base.transaction do
        expect do
          repository.append_to_stream([
            RubyEventStore::SRecord.new(
              event_id: "9bedf448-e4d0-41a3-a8cd-f94aec7aa763"
            ),
          ], RubyEventStore::Stream.new("stream"), RubyEventStore::ExpectedVersion.none)
        end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
        expect(repository.has_event?("9bedf448-e4d0-41a3-a8cd-f94aec7aa763")).to be_falsey
        expect(repository.read(specification.limit(2).result).to_a).to eq([event])
      end
      expect(repository.has_event?("9bedf448-e4d0-41a3-a8cd-f94aec7aa763")).to be_falsey
      expect(repository.read(specification.limit(2).result).to_a).to eq([event])
    end

    specify "avoid N+1" do
      repository.append_to_stream(
        [RubyEventStore::SRecord.new, RubyEventStore::SRecord.new],
        RubyEventStore::Stream.new("stream"),
        RubyEventStore::ExpectedVersion.auto
      )

      expect{ repository.read(specification.limit(2).result) }.to                           match_query_count_of(1)
      expect{ repository.read(specification.limit(2).backward.result) }.to                  match_query_count_of(1)
      expect{ repository.read(specification.stream("stream").result) }.to                   match_query_count_of(2)
      expect{ repository.read(specification.stream("stream").backward.result) }.to          match_query_count_of(2)
      expect{ repository.read(specification.stream("stream").limit(2).result) }.to          match_query_count_of(2)
      expect{ repository.read(specification.stream("stream").limit(2).backward.result) }.to match_query_count_of(2)
    end

    specify "limited query when looking for unexisting events during linking" do
      expect_query(/SELECT.*event_store_events.*id.*FROM.*event_store_events.*WHERE.*event_store_events.*id.*=.*/) do
        expect do
          repository.link_to_stream(["72922e65-1b32-4e97-8023-03ae81dd3a27"], RubyEventStore::Stream.new("flow"), RubyEventStore::ExpectedVersion.none)
        end.to raise_error(RubyEventStore::EventNotFound)
      end
    end

    specify "read in batches forward" do
      events = Array.new(200) { RubyEventStore::SRecord.new }
      repository.append_to_stream(
        events,
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )

      batches = repository.read(specification.forward.limit(101).in_batches.result).to_a
      expect(batches.size).to eq(2)
      expect(batches[0].size).to eq(100)
      expect(batches[1].size).to eq(1)
      expect(batches[0]).to eq(events[0..99])
      expect(batches[1]).to eq([events[100]])
    end

    specify "read in batches backward" do
      events = Array.new(200) { RubyEventStore::SRecord.new }
      repository.append_to_stream(
        events,
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )

      batches = repository.read(specification.backward.limit(101).in_batches.result).to_a
      expect(batches.size).to eq(2)
      expect(batches[0].size).to eq(100)
      expect(batches[1].size).to eq(1)
      expect(batches[0]).to eq(events[100..-1].reverse)
      expect(batches[1]).to eq([events[99]])
    end

    specify "read in batches forward from named stream" do
      all_events = Array.new(400) { RubyEventStore::SRecord.new }
      all_events.each_slice(2) do |(first, second)|
        repository.append_to_stream(
          [first],
          RubyEventStore::Stream.new("bazinga"),
          RubyEventStore::ExpectedVersion.any
        )
        repository.append_to_stream(
          [second],
          RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
          RubyEventStore::ExpectedVersion.any
        )
      end
      stream_events = all_events.each_with_index.select { |event, idx| event if idx % 2 == 0 }.map { |event, idx| event }
      batches = repository.read(specification.stream("bazinga").forward.limit(101).in_batches.result).to_a
      expect(batches.size).to eq(2)
      expect(batches[0].size).to eq(100)
      expect(batches[1].size).to eq(1)
      expect(batches[0]).to eq(stream_events[0..99])
      expect(batches[1]).to eq([stream_events[100]])
    end

    specify "use default models" do
      repository = EventRepository.new(serializer: YAML)
      expect(repository.instance_variable_get(:@event_klass)).to be(Event)
      expect(repository.instance_variable_get(:@stream_klass)).to be(EventInStream)
    end

    specify "allows custom base class" do
      repository = EventRepository.new(model_factory: WithAbstractBaseClass.new(CustomApplicationRecord), serializer: YAML)
      expect(repository.instance_variable_get(:@event_klass).ancestors).to include(CustomApplicationRecord)
      expect(repository.instance_variable_get(:@stream_klass).ancestors).to include(CustomApplicationRecord)
    end

    specify "reading/writting works with custom base class" do
      repository = EventRepository.new(model_factory: WithAbstractBaseClass.new(CustomApplicationRecord), serializer: YAML)
      repository.append_to_stream(
        [event = RubyEventStore::SRecord.new],
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )
      reader = RubyEventStore::SpecificationReader.new(repository, RubyEventStore::Mappers::NullMapper.new)
      specification = RubyEventStore::Specification.new(reader)
      read_event = repository.read(specification.result).first
      expect(read_event).to eq(event)
    end

    specify "timestamps not overwritten by activerecord-import" do
      repository.append_to_stream(
        [event = RubyEventStore::SRecord.new(timestamp: time = Time.at(0))],
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )
      event_ = repository.read(specification.result).first
      expect(event_.timestamp).to eq(time)
    end

    specify "with post-valid-at appended record" do
      Event.create!(
        event_id: id = SecureRandom.uuid,
        data: "{}",
        metadata: "{}",
        event_type: "TestDomainEvent",
        created_at: t1 = with_precision(Time.now.utc),
        valid_at:   t2 = with_precision(Time.at(0)),
      )
      EventInStream.create!(
        stream:   "stream",
        position: 1,
        event_id: id,
        created_at: t1,
      )

      record = repository.read(specification.result).first
      expect(record.timestamp).to eq(t1)
      expect(record.valid_at).to  eq(t2)
    end

    specify "with pre-valid-at appended record" do
      Event.create!(
        event_id: id = SecureRandom.uuid,
        data: "{}",
        metadata: "{}",
        event_type: "TestDomainEvent",
        created_at: t = with_precision(Time.now.utc),
        valid_at: nil,
      )
      EventInStream.create!(
        stream:   "stream",
        position: 1,
        event_id: id,
        created_at: t,
      )

      record = repository.read(specification.result).first
      expect(record.timestamp).to eq(t)
      expect(record.valid_at).to  eq(t)
    end

    specify "valid-at storage optimization when same as created-at" do
      repository.append_to_stream(
        [RubyEventStore::SRecord.new(timestamp: time = with_precision(Time.at(0)))],
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )
      record = repository.read(specification.result).first
      expect(record.timestamp).to eq(time)
      expect(record.valid_at).to  eq(time)

      event_record = Event.find_by(event_id: record.event_id)
      expect(event_record.created_at).to eq(time)
      expect(event_record.valid_at).to   be_nil
    end

    specify "no valid-at storage optimization when different from created-at" do
      repository.append_to_stream(
        [RubyEventStore::SRecord.new(
          timestamp: t1 = with_precision(Time.at(0)),
          valid_at:  t2 = with_precision(Time.at(1))
        )],
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )
      record = repository.read(specification.result).first
      expect(record.timestamp).to eq(t1)
      expect(record.valid_at).to  eq(t2)

      event_record = Event.find_by(event_id: record.event_id)
      expect(event_record.created_at).to eq(t1)
      expect(event_record.valid_at).to   eq(t2)
    end

    specify "with batches and bi-temporal queries use offset + limit" do
      repository.append_to_stream([
        RubyEventStore::SRecord.new(event_id: e1 = SecureRandom.uuid, timestamp: Time.new(2020,1,1), valid_at: Time.new(2020,1,9)),
        RubyEventStore::SRecord.new(event_id: e2 = SecureRandom.uuid, timestamp: Time.new(2020,1,3), valid_at: Time.new(2020,1,6)),
        RubyEventStore::SRecord.new(event_id: e3 = SecureRandom.uuid, timestamp: Time.new(2020,1,2), valid_at: Time.new(2020,1,3)),
      ],
        RubyEventStore::Stream.new("Dummy"),
        RubyEventStore::ExpectedVersion.any
      )

      expect_query(/SELECT.*FROM.*event_store_events.*ORDER BY .*event_store_events.*created_at.*,.*event_store_events.*id.* ASC LIMIT.*.OFFSET.*/, 2) do
        repository.read(specification.in_batches.as_at.result).to_a
      end
      expect_query(/SELECT.*FROM.*event_store_events.*ORDER BY .*event_store_events.*valid_at.*,.*event_store_events.*id.* ASC LIMIT.*.OFFSET.*/, 2) do
        repository.read(specification.in_batches.as_of.result).to_a
      end
    end

    specify "with batches and non-bi-temporal queries use monotnic ids" do
      repository.append_to_stream([
        RubyEventStore::SRecord.new(event_id: e1 = SecureRandom.uuid, timestamp: Time.new(2020,1,1), valid_at: Time.new(2020,1,9)),
        RubyEventStore::SRecord.new(event_id: e2 = SecureRandom.uuid, timestamp: Time.new(2020,1,3), valid_at: Time.new(2020,1,6)),
        RubyEventStore::SRecord.new(event_id: e3 = SecureRandom.uuid, timestamp: Time.new(2020,1,2), valid_at: Time.new(2020,1,3)),
      ],
        RubyEventStore::Stream.new("Dummy"),
        RubyEventStore::ExpectedVersion.any
      )

      expect_query(/SELECT.*FROM.*event_store_events.*WHERE.*event_store_events.id >*.*ORDER BY .*event_store_events.*id.* ASC LIMIT.*/) do
        repository.read(specification.in_batches.result).to_a
      end
    end

    specify do
      events = Array.new(200) { RubyEventStore::SRecord.new }
      repository.append_to_stream(
        events,
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )

      batches = repository.read(specification.as_at.forward.limit(101).in_batches.result).to_a
      expect(batches.size).to eq(2)
      expect(batches[0].size).to eq(100)
      expect(batches[1].size).to eq(1)
      expect(batches[0]).to eq(events[0..99])
      expect(batches[1]).to eq([events[100]])
    end

    specify do
      repository.append_to_stream([
        event0 = RubyEventStore::SRecord.new,
        event1 = RubyEventStore::SRecord.new,
      ], stream = RubyEventStore::Stream.new("stream"), RubyEventStore::ExpectedVersion.auto)

      expect_query(/SELECT\s+.event_store_events_in_streams.\..position. FROM .event_store_events_in_streams.*/) do
        repository.position_in_stream(event0.event_id, stream)
      end
    end

    specify do
      repository.append_to_stream(
        [event = RubyEventStore::SRecord.new],
        RubyEventStore::Stream.new("stream"),
        RubyEventStore::ExpectedVersion.any
      )
      expect_query(/SELECT\s+.event_store_events.\..id. FROM .event_store_events.*/) do
        repository.global_position(event.event_id)
      end
    end

    private

    def additional_limited_concurrency_for_auto_check
      positions = RailsEventStoreActiveRecord::EventInStream
        .where(stream: "stream")
        .order("position ASC")
        .map(&:position)
      expect(positions).to eq((0..positions.size-1).to_a)
    end

    def with_precision(time)
      time.round(RubyEventStore::TIMESTAMP_PRECISION)
    end

    def count_queries(&block)
      count = 0
      counter_f = ->(_name, _started, _finished, _unique_id, payload) {
        unless %w[ CACHE SCHEMA ].include?(payload[:name])
          count += 1
        end
      }
      ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
      count
    end

    def expect_query(match, times = 1, &block)
      count = 0
      counter_f = ->(_name, _started, _finished, _unique_id, payload) {
        count +=1 if match === payload[:sql]
      }
      ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
      expect(count).to eq(times)
    end
  end
end
