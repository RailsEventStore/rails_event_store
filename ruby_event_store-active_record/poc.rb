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
require "benchmark/ips"

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

perform_100_appends_in_outer_transaction =
  lambda do
    ActiveRecord::Base.transaction do
      100.times { event_store.append(mk_event.call) }
    end
  end

ActiveSupport::Notifications.subscribed(log_transaction, /sql/) do
  $use_savepoint = true
  perform_100_appends_in_outer_transaction.call

  $use_savepoint = false
  perform_100_appends_in_outer_transaction.call
end

Benchmark.ips do |x|
  x.report("with_savepoint") do
    $use_savepoint = true
    perform_100_appends_in_outer_transaction
  end

  x.report("without_savepoint") do
    $use_savepoint = false
    perform_100_appends_in_outer_transaction
  end
end
