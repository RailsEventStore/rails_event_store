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
  end
end
