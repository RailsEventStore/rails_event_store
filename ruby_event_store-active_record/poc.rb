require "bundler/inline"

gemfile do
  source "https://rubygems.org"
  gem "ruby_event_store", path: ".."
  gem "ruby_event_store-active_record", path: "."
  gem "pg"
  gem "childprocess"
  gem "benchmark-ips"
end

require "ruby_event_store"
require "ruby_event_store/active_record"

require_relative "../support/helpers/migrator"
require_relative "../support/helpers/schema_helper"

include SchemaHelper
establish_database_connection
drop_database
load_database_schema

event_store =
  RubyEventStore::Client.new(
    repository:
      RubyEventStore::ActiveRecord::EventRepository.new(
        serializer: RubyEventStore::NULL
      )
  )

mk_event =
  lambda { RubyEventStore::Event.new(metadata: { event_type: "whatever" }) }

logged_keywords = %w[COMMIT BEGIN SAVEPOINT RELEASE].freeze

log_transaction =
  lambda do |name, started, finished, unique_id, payload|
    if logged_keywords.any? { |keyword| payload[:sql].start_with? keyword }
      puts payload[:sql]
    end
  end

ActiveSupport::Notifications.subscribed(log_transaction, /sql/) do
  ActiveRecord::Base.transaction do
    100.times { event_store.append(mk_event.call) }
  end
end
