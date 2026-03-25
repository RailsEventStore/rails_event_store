# frozen_string_literal: true

require "ruby_event_store"
require "active_record"
require_relative "support/fake_configuration"
require_relative "../../../support/helpers/migrator"

MIGRATIONS_PATH = File.expand_path(
  "../../../ruby_event_store-active_record/lib/ruby_event_store/active_record/generators/templates",
  __dir__
) unless defined?(MIGRATIONS_PATH)

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.after { RubyEventStore::CLI::EventStoreResolver.event_store = nil }
end

RSpec.shared_context "with AR database" do
  around do |example|
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Schema.verbose = false
    Migrator.new(MIGRATIONS_PATH).run_migration("create_event_store_events")
    example.run
  ensure
    ActiveRecord::Migration.drop_table("event_store_events_in_streams") rescue nil
    ActiveRecord::Migration.drop_table("event_store_events") rescue nil
  end

  def ar_event_store
    require "ruby_event_store/active_record"
    RubyEventStore::Client.new(
      repository: RubyEventStore::ActiveRecord::EventRepository.new(
        serializer: RubyEventStore::Serializers::YAML
      )
    )
  end
end
