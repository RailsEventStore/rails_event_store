require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

module RailsEventStoreActiveRecord
  class EventRepository
    class SpecHelper < RubyEventStore::EventRepositoryHelper
      def supports_concurrent_auto?
        !ENV['DATABASE_URL'].include?("sqlite")
      end

      def supports_concurrent_any?
        !ENV['DATABASE_URL'].include?("sqlite")
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
    end
  end

  class Event < ::ActiveRecord::Base
    self.primary_key = :id
    self.table_name = 'event_store_events'
  end

  class EventInStream < ::ActiveRecord::Base
    self.primary_key = :id
    self.table_name = 'event_store_events_in_streams'
    belongs_to :event
  end

  class CustomApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
  end

  RSpec.describe EventRepository do
    include_examples :event_repository
    let(:repository) { EventRepository.new(serializer: YAML) }
    let(:helper) { EventRepository::SpecHelper.new }

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

    specify "all considered internal detail" do
      repository.append_to_stream(
        [RubyEventStore::SRecord.new],
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )

      expect do
        repository.read(specification.stream("all").result)
      end.to raise_error(RubyEventStore::ReservedInternalName)

      expect do
        repository.read(specification.stream("all").backward.result)
      end.to raise_error(RubyEventStore::ReservedInternalName)

      expect do
        repository.read(specification.stream("all").limit(5).result)
      end.to raise_error(RubyEventStore::ReservedInternalName)

      expect do
        repository.read(specification.stream("all").limit(5).backward.result)
      end.to raise_error(RubyEventStore::ReservedInternalName)

      expect do
        repository.count(specification.stream("all").result)
      end.to raise_error(RubyEventStore::ReservedInternalName)
    end

    specify "using preload()" do
      repository.append_to_stream([
        event0 = RubyEventStore::SRecord.new,
        event1 = RubyEventStore::SRecord.new,
      ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
      c1 = count_queries{ repository.read(specification.limit(2).result) }
      expect(c1).to eq(2)

      c2 = count_queries{ repository.read(specification.limit(2).backward.result) }
      expect(c2).to eq(2)

      c3 = count_queries{ repository.read(specification.stream("stream").result) }
      expect(c3).to eq(2)

      c4 = count_queries{ repository.read(specification.stream("stream").backward.result) }
      expect(c4).to eq(2)

      c5 = count_queries{ repository.read(specification.stream("stream").limit(2).result) }
      expect(c5).to eq(2)

      c6 = count_queries{ repository.read(specification.stream("stream").limit(2).backward.result) }
      expect(c6).to eq(2)
    end

    specify "explicit sorting by position rather than accidental" do
      e1 = Event.create!(
        id: u1 = SecureRandom.uuid,
        data: '{}',
        metadata: '{}',
        event_type: "TestDomainEvent",
      )
      e2 = Event.create!(
        id: u2 = SecureRandom.uuid,
        data: '{}',
        metadata: '{}',
        event_type: "TestDomainEvent",
      )
      e3 = Event.create!(
        id: u3 = SecureRandom.uuid,
        data: '{}',
        metadata: '{}',
        event_type: "TestDomainEvent",
      )
      EventInStream.create!(
        stream:   "stream",
        position: 1,
        event_id: e2.id,
      )
      EventInStream.create!(
        stream:   "stream",
        position: 0,
        event_id: e1.id,
      )
      EventInStream.create!(
        stream:   "stream",
        position: 2,
        event_id: e3.id,
      )
      ActiveRecord::Schema.define do
        self.verbose = false
        remove_index :event_store_events_in_streams, [:stream, :position]
      end

      expect(repository.read(specification.stream("stream").limit(3).result).map(&:event_id)).to eq([u1,u2,u3])
      expect(repository.read(specification.stream("stream").result).map(&:event_id)).to eq([u1,u2,u3])

      expect(repository.read(specification.stream("stream").backward.limit(3).result).map(&:event_id)).to eq([u3,u2,u1])
      expect(repository.read(specification.stream("stream").backward.result).map(&:event_id)).to eq([u3,u2,u1])
    end

    specify "explicit sorting by id rather than accidental for all events" do
      e1 = Event.create!(
        id: u1 = SecureRandom.uuid,
        data: '{}',
        metadata: '{}',
        event_type: "TestDomainEvent",
      )
      e2 = Event.create!(
        id: u2 = SecureRandom.uuid,
        data: '{}',
        metadata: '{}',
        event_type: "TestDomainEvent",
      )
      e3 = Event.create!(
        id: u3 = SecureRandom.uuid,
        data: '{}',
        metadata: '{}',
        event_type: "TestDomainEvent",
      )
      EventInStream.create!(
        stream:   "all",
        position: 1,
        event_id: e1.id,
      )
      EventInStream.create!(
        stream:   "all",
        position: 0,
        event_id: e2.id,
      )
      EventInStream.create!(
        stream:   "all",
        position: 2,
        event_id: e3.id,
      )

      expect(repository.read(specification.limit(3).result).map(&:event_id)).to eq([u1,u2,u3])
      expect(repository.read(specification.limit(3).backward.result).map(&:event_id)).to eq([u3,u2,u1])
    end

    specify do
      e1 = Event.create!(
        id: u1 = SecureRandom.uuid,
        data: '{}',
        metadata: '{}',
        event_type: "TestDomainEvent",
      )
      e2 = Event.create!(
        id: u2 = SecureRandom.uuid,
        data: '{}',
        metadata: '{}',
        event_type: "TestDomainEvent",
      )
      e3 = Event.create!(
        id: u3 = SecureRandom.uuid,
        data: '{}',
        metadata: '{}',
        event_type: "TestDomainEvent",
      )
      EventInStream.create!(
        stream:   "all",
        position: 1,
        event_id: e1.id,
      )
      EventInStream.create!(
        stream:   "all",
        position: 0,
        event_id: e2.id,
      )
      EventInStream.create!(
        stream:   "all",
        position: 2,
        event_id: e3.id,
      )

      expect(repository.read(specification.to(u3).limit(3).result).map(&:event_id)).to eq([u1,u2])
      expect(repository.read(specification.to(u1).limit(3).backward.result).map(&:event_id)).to eq([u3,u2])
    end

    specify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY .*event_store_events_in_streams.*id.* ASC LIMIT.*/) do
        repository.read(specification.limit(3).result)
      end
    end

    specify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY .*event_store_events_in_streams.*id.* DESC LIMIT.*/) do
        repository.read(specification.limit(3).backward.result)
      end
    end

    specify "explicit ORDER BY position" do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY position DESC LIMIT.*/) do
        repository.append_to_stream([
          RubyEventStore::SRecord.new,
        ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.auto)
      end
    end

    specify "nested transaction - events still not persisted if append failed" do
      repository.append_to_stream([
        event = RubyEventStore::SRecord.new(event_id: SecureRandom.uuid),
      ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)

      ActiveRecord::Base.transaction do
        expect do
          repository.append_to_stream([
            RubyEventStore::SRecord.new(
              event_id: '9bedf448-e4d0-41a3-a8cd-f94aec7aa763'
            ),
          ], RubyEventStore::Stream.new('stream'), RubyEventStore::ExpectedVersion.none)
        end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
        expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
        expect(repository.read(specification.limit(2).result).to_a).to eq([event])
      end
      expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
      expect(repository.read(specification.limit(2).result).to_a).to eq([event])
    end

    specify "limited query when looking for unexisting events during linking" do
      expect_query(/SELECT.*event_store_events.*id.*FROM.*event_store_events.*WHERE.*event_store_events.*id.*=.*/) do
        expect do
          repository.link_to_stream('72922e65-1b32-4e97-8023-03ae81dd3a27', "flow", RubyEventStore::ExpectedVersion.none)
        end.to raise_error(RubyEventStore::EventNotFound)
      end
    end

    class FillInRepository < EventRepository
      def fill_ids(in_stream)
        in_stream.each.with_index.map do |is, index|
          is[:id] = index + 987_654_321
          is[:id] += 3 if is[:stream] == "whoo"
        end
      end
    end

    specify 'fill_ids in append_to_stream' do
      repository = FillInRepository.new(serializer: YAML)
      repository.append_to_stream(
        [event = RubyEventStore::SRecord.new],
        RubyEventStore::Stream.new('stream'),
        RubyEventStore::ExpectedVersion.any
      )

      expect(EventInStream.find(987_654_321).stream).to eq("stream")
      expect(EventInStream.find(987_654_322).stream).to eq(EventRepository::SERIALIZED_GLOBAL_STREAM_NAME)
    end

    specify 'fill_ids in append_to_stream global' do
      repository = FillInRepository.new(serializer: YAML)
      repository.append_to_stream(
        [event = RubyEventStore::SRecord.new],
        RubyEventStore::Stream.new(RubyEventStore::GLOBAL_STREAM),
        RubyEventStore::ExpectedVersion.any
      )

      expect(EventInStream.find(987_654_321).stream).to eq(EventRepository::SERIALIZED_GLOBAL_STREAM_NAME)
    end

    specify 'fill_ids in link_to_stream' do
      repository = FillInRepository.new(serializer: YAML)
      repository.append_to_stream(
        [event = RubyEventStore::SRecord.new],
        RubyEventStore::Stream.new('stream'),
        RubyEventStore::ExpectedVersion.any
      )
      repository.link_to_stream(
        [event.event_id],
        RubyEventStore::Stream.new("whoo"),
        RubyEventStore::ExpectedVersion.any
      )

      expect(EventInStream.find(987_654_321).stream).to eq("stream")
      expect(EventInStream.find(987_654_322).stream).to eq(EventRepository::SERIALIZED_GLOBAL_STREAM_NAME)
      expect(EventInStream.find(987_654_324).stream).to eq("whoo")
    end

    specify 'read in batches forward' do
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

    specify 'read in batches backward' do
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

    specify 'allows custom base class' do
      repository = EventRepository.new(CustomApplicationRecord, serializer: YAML)
      expect(repository.instance_variable_get(:@event_klass).ancestors).to include(CustomApplicationRecord)
      expect(repository.instance_variable_get(:@stream_klass).ancestors).to include(CustomApplicationRecord)
    end

    specify 'reading/writting works with custom base class' do
      repository = EventRepository.new(CustomApplicationRecord, serializer: YAML)
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

    specify 'each repository must have different AR classes' do
      repository1 = EventRepository.new(CustomApplicationRecord, serializer: YAML)
      repository2 = EventRepository.new(CustomApplicationRecord, serializer: YAML)
      event_klass_1 = repository1.instance_variable_get(:@event_klass).name
      event_klass_2 = repository2.instance_variable_get(:@event_klass).name
      stream_klass_1 = repository1.instance_variable_get(:@stream_klass).name
      stream_klass_2 = repository2.instance_variable_get(:@stream_klass).name
      expect(event_klass_1).not_to eq(event_klass_2)
      expect(stream_klass_1).not_to eq(stream_klass_2)
    end

    specify 'Base for event repository models must be an abstract class' do
      NonAbstractClass = Class.new(ActiveRecord::Base)
      expect {
        EventRepository.new(NonAbstractClass, serializer: YAML)
      }.to raise_error(ArgumentError)
       .with_message('RailsEventStoreActiveRecord::NonAbstractClass must be an abstract class or ActiveRecord::Base')
    end

    def cleanup_concurrency_test
      ActiveRecord::Base.connection_pool.disconnect!
    end

    def verify_conncurency_assumptions
      expect(ActiveRecord::Base.connection.pool.size).to eq(5)
    end

    def additional_limited_concurrency_for_auto_check
      positions = RailsEventStoreActiveRecord::EventInStream
        .where(stream: "stream")
        .order("position ASC")
        .map(&:position)
      expect(positions).to eq((0..positions.size-1).to_a)
    end

    private

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

    def expect_query(match, &block)
      count = 0
      counter_f = ->(_name, _started, _finished, _unique_id, payload) {
        count +=1 if match === payload[:sql]
      }
      ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
      expect(count).to eq(1)
    end
  end
end
