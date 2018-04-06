require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'
require 'rails_event_store_active_record/event'
require_relative '../../ruby_event_store/spec/mappers/events_pb.rb'

module RailsEventStoreActiveRecord
  RSpec.describe EventRepository do
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

    let(:test_race_conditions_auto)  { !ENV['DATABASE_URL'].include?("sqlite") }
    let(:test_race_conditions_any)   { !ENV['DATABASE_URL'].include?("sqlite") }
    let(:test_expected_version_auto) { true }
    let(:test_link_events_to_stream) { true }
    let(:test_non_legacy_all_stream) { true }

    it_behaves_like :event_repository, EventRepository

    specify "using preload()" do
      repository = EventRepository.new
      repository.append_to_stream([
        event0 = SRecord.new,
        event1 = SRecord.new,
      ], 'stream', :auto)
      c1 = count_queries{ repository.read_all_streams_forward(:head, 2) }
      expect(c1).to eq(2)

      c2 = count_queries{ repository.read_all_streams_backward(:head, 2) }
      expect(c2).to eq(2)

      c3 = count_queries{ repository.read_stream_events_forward('stream') }
      expect(c3).to eq(2)

      c4 = count_queries{ repository.read_stream_events_backward('stream') }
      expect(c4).to eq(2)

      c5 = count_queries{ repository.read_events_forward('stream', :head, 2) }
      expect(c5).to eq(2)

      c6 = count_queries{ repository.read_events_backward('stream', :head, 2) }
      expect(c6).to eq(2)
    end

    specify "explicit sorting by position rather than accidental" do
      e1 = Event.create!(
        id: u1 = SecureRandom.uuid,
        data: {},
        metadata: {},
        event_type: "TestDomainEvent",
      )
      e2 = Event.create!(
        id: u2 = SecureRandom.uuid,
        data: {},
        metadata: {},
        event_type: "TestDomainEvent",
      )
      e3 = Event.create!(
        id: u3 = SecureRandom.uuid,
        data: {},
        metadata: {},
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
      repository = EventRepository.new
      expect(repository.read_events_forward('stream', :head, 3).map(&:event_id)).to eq([u1,u2,u3])
      expect(repository.read_stream_events_forward('stream').map(&:event_id)).to eq([u1,u2,u3])

      expect(repository.read_events_backward('stream', :head, 3).map(&:event_id)).to eq([u3,u2,u1])
      expect(repository.read_stream_events_backward('stream').map(&:event_id)).to eq([u3,u2,u1])
    end

    specify "explicit sorting by id rather than accidental for all events" do
      e1 = Event.create!(
        id: u1 = SecureRandom.uuid,
        data: {},
        metadata: {},
        event_type: "TestDomainEvent",
      )
      e2 = Event.create!(
        id: u2 = SecureRandom.uuid,
        data: {},
        metadata: {},
        event_type: "TestDomainEvent",
      )
      e3 = Event.create!(
        id: u3 = SecureRandom.uuid,
        data: {},
        metadata: {},
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
      repository = EventRepository.new

      expect(repository.read_all_streams_forward(:head, 3).map(&:event_id)).to eq([u1,u2,u3])
      expect(repository.read_events_forward("all", :head, 3).map(&:event_id)).to eq([u1,u2,u3])
      expect(repository.read_stream_events_forward("all").map(&:event_id)).to eq([u1,u2,u3])

      expect(repository.read_all_streams_backward(:head, 3).map(&:event_id)).to eq([u3,u2,u1])
      expect(repository.read_events_backward("all", :head, 3).map(&:event_id)).to eq([u3,u2,u1])
      expect(repository.read_stream_events_backward("all").map(&:event_id)).to eq([u3,u2,u1])
    end

    specify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id ASC LIMIT.*/) do
        repository = EventRepository.new
        repository.read_all_streams_forward(:head, 3)
      end
    end

    specify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id ASC LIMIT.*/) do
        repository = EventRepository.new
        repository.read_events_forward("all", :head, 3)
      end
    end

    specify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id ASC.*/) do
        repository = EventRepository.new
        repository.read_stream_events_forward("all")
      end
    end

    specify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id DESC LIMIT.*/) do
        repository = EventRepository.new
        repository.read_all_streams_backward(:head, 3)
      end
    end

    specify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id DESC LIMIT.*/) do
        repository = EventRepository.new
        repository.read_events_backward("all", :head, 3)
      end
    end

    specify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id DESC.*/) do
        repository = EventRepository.new
        repository.read_stream_events_backward("all")
      end
    end

    specify "explicit ORDER BY position" do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY position DESC LIMIT.*/) do
        repository = EventRepository.new
        repository.append_to_stream([
          SRecord.new,
        ], 'stream', :auto)
      end
    end

    specify "nested transaction - events still not persisted if append failed" do
      repository = EventRepository.new
      repository.append_to_stream([
        event = SRecord.new(event_id: SecureRandom.uuid),
      ], 'stream', :none)

      ActiveRecord::Base.transaction do
        expect do
          repository.append_to_stream([
            SRecord.new(
              event_id: '9bedf448-e4d0-41a3-a8cd-f94aec7aa763'
            ),
          ], 'stream', :none)
        end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
        expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
        expect(repository.read_all_streams_forward(:head, 2)).to eq([event])
      end
      expect(repository.has_event?('9bedf448-e4d0-41a3-a8cd-f94aec7aa763')).to be_falsey
      expect(repository.read_all_streams_forward(:head, 2)).to eq([event])
    end

    specify "limited query when looking for unexisting events during linking" do
      repository = EventRepository.new
      expect_query(/SELECT.*event_store_events.*id.*FROM.*event_store_events.*WHERE.*event_store_events.*id.*=.*/) do
        expect do
          repository.link_to_stream('72922e65-1b32-4e97-8023-03ae81dd3a27', "flow", -1)
        end.to raise_error(RubyEventStore::EventNotFound)
      end
    end

    specify "explicit order when fetching list of streams" do
      repository = EventRepository.new
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*ORDER BY.*id.*ASC.*/) do
        repository.get_all_streams
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
      event = SRecord.new
      repository = FillInRepository.new
      repository.append_to_stream([event], "stream", :any)

      expect(EventInStream.find(987_654_321).stream).to eq("stream")
      expect(EventInStream.find(987_654_322).stream).to eq(RubyEventStore::GLOBAL_STREAM)
    end

    specify 'fill_ids in append_to_stream global' do
      event = SRecord.new
      repository = FillInRepository.new
      repository.append_to_stream([event], RubyEventStore::GLOBAL_STREAM, :any)

      expect(EventInStream.find(987_654_321).stream).to eq(RubyEventStore::GLOBAL_STREAM)
    end

    specify 'fill_ids in link_to_stream' do
      event = SRecord.new
      repository = FillInRepository.new
      repository.append_to_stream([event], "stream", :any)
      repository.link_to_stream([event.event_id], "whoo", :any)

      expect(EventInStream.find(987_654_321).stream).to eq("stream")
      expect(EventInStream.find(987_654_322).stream).to eq(RubyEventStore::GLOBAL_STREAM)
      expect(EventInStream.find(987_654_324).stream).to eq("whoo")
    end

    def cleanup_concurrency_test
      ActiveRecord::Base.connection_pool.disconnect!
    end

    def verify_conncurency_assumptions
      expect(ActiveRecord::Base.connection.pool.size).to eq(5)
    end

    def additional_limited_concurrency_for_auto_check
      positions = RailsEventStoreActiveRecord::EventInStream.
        where(stream: "stream").
        order("position ASC").
        map(&:position)
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
