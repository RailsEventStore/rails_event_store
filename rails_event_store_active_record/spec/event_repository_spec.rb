require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

module RailsEventStoreActiveRecord
  describe EventRepository do
    before do
      # ActiveRecord::Base.logger = Logger.new(STDOUT)
    end
    let(:test_race_conditions_auto) { !ENV['DATABASE_URL'].include?("sqlite") }
    let(:test_race_conditions_any)  { !ENV['DATABASE_URL'].include?("sqlite") }
    it_behaves_like :event_repository, EventRepository

    specify "using preload()" do
      repository = EventRepository.new
      repository.append_to_stream([
        event0 = TestDomainEvent.new(event_id: SecureRandom.uuid),
        event1 = TestDomainEvent.new(event_id: SecureRandom.uuid),
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

    def count_queries &block
      count = 0

      counter_f = ->(name, started, finished, unique_id, payload) {
        unless %w[ CACHE SCHEMA ].include?(payload[:name])
          count += 1
        end
      }

      ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)

      count
    end

  end
end