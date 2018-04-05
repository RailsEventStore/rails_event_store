require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'
require_relative '../../ruby_event_store/spec/mappers/events_pb.rb'

module RubyEventStore::ROM
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

    # TODO: Port from AR to ROM
    xspecify "using preload()" do
      repository = EventRepository.new
      repository.append_to_stream([
        SRecord.new,
        SRecord.new,
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
      events = [
        SRecord.new(
          event_id: u1 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        ),
        SRecord.new(
          event_id: u2 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        ),
        SRecord.new(
          event_id: u3 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        )
      ]
      
      events_writer = Repositories::Events.new(rom).method(:create)
      event_streams_writer = Repositories::EventStreams.new(rom).method(:create)

      events.each do |event|
        events_writer.(event)
      end
      
      event_streams_writer.("stream", events[1].event_id, position: 1)
      event_streams_writer.("stream", events[0].event_id, position: 0)
      event_streams_writer.("stream", events[2].event_id, position: 2)
      
      # ActiveRecord::Schema.define do
      #   self.verbose = false
      #   remove_index :event_store_events_in_streams, [:stream, :position]
      # end
      repository = EventRepository.new
      expect(repository.read_events_forward('stream', :head, 3).map(&:event_id)).to eq([u1,u2,u3])
      expect(repository.read_stream_events_forward('stream').map(&:event_id)).to eq([u1,u2,u3])

      expect(repository.read_events_backward('stream', :head, 3).map(&:event_id)).to eq([u3,u2,u1])
      expect(repository.read_stream_events_backward('stream').map(&:event_id)).to eq([u3,u2,u1])
    end

    specify "explicit sorting by id rather than accidental for all events" do
      events = [
        SRecord.new(
          event_id: u1 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        ),
        SRecord.new(
          event_id: u2 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        ),
        SRecord.new(
          event_id: u3 = SecureRandom.uuid,
          data: YAML.dump({}),
          metadata: YAML.dump({}),
          event_type: "TestDomainEvent"
        )
      ]
      
      events_writer = Repositories::Events.new(rom).method(:create)
      event_streams_writer = Repositories::EventStreams.new(rom).method(:create)

      events.each do |event|
        events_writer.(event)
      end

      event_streams_writer.(RubyEventStore::GLOBAL_STREAM, events[0].event_id, position: 1)
      event_streams_writer.(RubyEventStore::GLOBAL_STREAM, events[1].event_id, position: 0)
      event_streams_writer.(RubyEventStore::GLOBAL_STREAM, events[2].event_id, position: 2)
      
      repository = EventRepository.new

      expect(repository.read_all_streams_forward(:head, 3).map(&:event_id)).to eq([u1,u2,u3])
      expect(repository.read_events_forward("all", :head, 3).map(&:event_id)).to eq([u1,u2,u3])
      expect(repository.read_stream_events_forward("all").map(&:event_id)).to eq([u1,u2,u3])

      expect(repository.read_all_streams_backward(:head, 3).map(&:event_id)).to eq([u3,u2,u1])
      expect(repository.read_events_backward("all", :head, 3).map(&:event_id)).to eq([u3,u2,u1])
      expect(repository.read_stream_events_backward("all").map(&:event_id)).to eq([u3,u2,u1])
    end

    # TODO: Port from AR to ROM
    xspecify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id ASC LIMIT.*/) do
        repository = EventRepository.new
        repository.read_all_streams_forward(:head, 3)
      end
    end

    # TODO: Port from AR to ROM
    xspecify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id ASC LIMIT.*/) do
        repository = EventRepository.new
        repository.read_events_forward("all", :head, 3)
      end
    end

    # TODO: Port from AR to ROM
    xspecify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id ASC.*/) do
        repository = EventRepository.new
        repository.read_stream_events_forward("all")
      end
    end

    # TODO: Port from AR to ROM
    xspecify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id DESC LIMIT.*/) do
        repository = EventRepository.new
        repository.read_all_streams_backward(:head, 3)
      end
    end

    # TODO: Port from AR to ROM
    xspecify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id DESC LIMIT.*/) do
        repository = EventRepository.new
        repository.read_events_backward("all", :head, 3)
      end
    end

    # TODO: Port from AR to ROM
    xspecify do
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*event_store_events_in_streams.*stream.*=.*ORDER BY id DESC.*/) do
        repository = EventRepository.new
        repository.read_stream_events_backward("all")
      end
    end

    # TODO: Port from AR to ROM
    xspecify "explicit ORDER BY position" do
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

      rom_db.transaction do
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

    # TODO: Port from AR to ROM
    xspecify "limited query when looking for unexisting events during linking" do
      repository = EventRepository.new
      expect_query(/SELECT.*event_store_events.*id.*FROM.*event_store_events.*WHERE.*event_store_events.*id.*=.*/) do
        expect do
          repository.link_to_stream('72922e65-1b32-4e97-8023-03ae81dd3a27', "flow", -1)
        end.to raise_error(RubyEventStore::EventNotFound)
      end
    end

    # TODO: Port from AR to ROM
    xspecify "explicit order when fetching list of streams" do
      repository = EventRepository.new
      expect_query(/SELECT.*FROM.*event_store_events_in_streams.*ORDER BY.*id.*ASC.*/) do
        repository.get_all_streams
      end
    end

    def cleanup_concurrency_test
      rom_db.connection.pool.disconnect
    end

    def verify_conncurency_assumptions
      expect(rom_db.connection.pool.size).to eq(5)
    end

    # TODO: Port from AR to ROM
    def additional_limited_concurrency_for_auto_check
      positions = rom_db.relations[:event_streams].
        where(stream: "stream").
        order("position ASC").
        map(&:position)
      expect(positions).to eq((0..positions.size-1).to_a)
    end

    private

    # TODO: Port from AR to ROM
    def count_queries(&block)
      count = 0
      counter_f = ->(_name, _started, _finished, _unique_id, payload) {
        unless %w[ CACHE SCHEMA ].include?(payload[:name])
          count += 1
        end
      }
      # ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
      count
    end

    # TODO: Port from AR to ROM
    def expect_query(match, &block)
      count = 0
      counter_f = ->(_name, _started, _finished, _unique_id, payload) {
        count += 1 if match === payload[:sql]
      }
      # ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
      expect(count).to eq(1)
    end
  end
end
