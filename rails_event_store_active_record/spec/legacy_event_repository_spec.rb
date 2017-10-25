require 'spec_helper'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

module RailsEventStoreActiveRecord
  describe LegacyEventRepository do
    before do
      ActiveRecord::Migration.drop_table "event_store_events_in_streams"
      ActiveRecord::Migration.drop_table "event_store_events"
      ActiveRecord::Schema.define do
        self.verbose = false
        create_table(:event_store_events, force: false) do |t|
          t.string      :stream,      null: false
          t.string      :event_type,  null: false
          t.string      :event_id,    null: false
          t.text        :metadata
          t.text        :data,        null: false
          t.datetime    :created_at,  null: false
        end
        add_index :event_store_events, :stream
        add_index :event_store_events, :created_at
        add_index :event_store_events, :event_type
        add_index :event_store_events, :event_id, unique: true
      end
    end

    let(:test_race_conditions_auto) { !ENV['DATABASE_URL'].include?("sqlite") }
    let(:test_race_conditions_any)  { !ENV['DATABASE_URL'].include?("sqlite") }

    it_behaves_like :event_repository, LegacyEventRepository

    def cleanup_concurrency_test
      ActiveRecord::Base.connection_pool.disconnect!
    end

    def verify_conncurency_assumptions
      expect(ActiveRecord::Base.connection.pool.size).to eq(5)
    end
  end
end
