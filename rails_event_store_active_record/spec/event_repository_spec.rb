require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'
require 'rails_event_store_active_record/event'

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

    it_behaves_like :event_repository, EventRepository

    specify "using preload()" do
      repository = EventRepository.new
      repository.append_to_stream([
        event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
        event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
      ], 'stream', :auto)
      c1 = count_queries{ repository.read_all_streams_forward(:head, 2) }
      expect(c1).to eq(1)

      c2 = count_queries{ repository.read_all_streams_backward(:head, 2) }
      expect(c2).to eq(1)

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
        event_type: TestDomainEvent.name,
      )
      e2 = Event.create!(
        id: u2 = SecureRandom.uuid,
        data: {},
        metadata: {},
        event_type: TestDomainEvent.name,
      )
      e3 = Event.create!(
        id: u3 = SecureRandom.uuid,
        data: {},
        metadata: {},
        event_type: TestDomainEvent.name,
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
    end

    specify "explicit sorting by position rather than accidental for all events" do
      e1 = Event.create!(
        id: u1 = SecureRandom.uuid,
        data: {},
        metadata: {},
        event_type: TestDomainEvent.name,
      )
      e2 = Event.create!(
        id: u2 = SecureRandom.uuid,
        data: {},
        metadata: {},
        event_type: TestDomainEvent.name,
      )
      e3 = Event.create!(
        id: u3 = SecureRandom.uuid,
        data: {},
        metadata: {},
        event_type: TestDomainEvent.name,
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
    end

    specify "explicit ORDER BY position" do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY position DESC LIMIT.*/) do
        repository = EventRepository.new
        repository.append_to_stream([
          TestDomainEvent.new(event_id: SecureRandom.uuid),
        ], 'stream', :auto)
      end
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
