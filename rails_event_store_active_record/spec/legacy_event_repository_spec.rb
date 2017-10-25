require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

module RailsEventStoreActiveRecord
  RSpec.describe LegacyEventRepository do
    include SchemaHelper

    around(:each) do |example|
      begin
        establish_database_connection
        load_legacy_database_schema
        example.run
      ensure
        drop_legacy_database
      end
    end

    let(:test_race_conditions_auto) { false }
    let(:test_race_conditions_any)  { !ENV['DATABASE_URL'].include?("sqlite") }

    it_behaves_like :event_repository, LegacyEventRepository

    def cleanup_concurrency_test
      ActiveRecord::Base.connection_pool.disconnect!
    end

    def verify_conncurency_assumptions
      expect(ActiveRecord::Base.connection.pool.size).to eq(5)
    end

    specify "read_stream_events_forward explicit ORDER BY id" do
      expect_query(/SELECT.*FROM.*event_store_events.*WHERE.*event_store_events.*stream.*=.*ORDER BY id ASC.*/) do
        repository = LegacyEventRepository.new
        repository.read_stream_events_forward('stream')
      end
    end

    specify "read_events_forward explicit ORDER BY id" do
      expect_query(/SELECT.*FROM.*event_store_events.*WHERE.*event_store_events.*stream.*=.*ORDER BY id ASC LIMIT.*/) do
        repository = LegacyEventRepository.new
        repository.read_events_forward('stream', :head, 1)
      end
    end

    specify "read_all_streams_forward explicit ORDER BY id" do
      expect_query(/SELECT.*FROM.*event_store_events.*ORDER BY id ASC LIMIT.*/) do
        repository = LegacyEventRepository.new
        repository.read_all_streams_forward(:head, 1)
      end
    end

    specify do
      repository = LegacyEventRepository.new
      expect{
        repository.append_to_stream(TestDomainEvent.new(event_id: SecureRandom.uuid), 'stream_1', :none)
        repository.append_to_stream(TestDomainEvent.new(event_id: SecureRandom.uuid), 'stream_2', :none)
      }.to_not raise_error
    end

    private

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
