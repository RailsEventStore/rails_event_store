# frozen_string_literal: true

require "spec_helper"
require_relative "../../support/helpers/subprocess_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe "Skip ActiveRecord serialization when the host application eager loads", mutant: false do
      include SubprocessHelper

      helper = SpecHelper.new
      around(:each) { |example| helper.run_lifecycle { example.run } }

      mysql = ENV["DATABASE_URL"].to_s.include?("mysql2")
      postgres = ENV["DATABASE_URL"].to_s.include?("postgres")
      json_column = %w[json jsonb].include?(ENV["DATA_TYPE"])

      # MySQL addresses JSON through a path expression and has no :: cast.
      extract = mysql ? "data ->> '$.foo'" : "data ->> 'foo'"
      as_text = mysql ? "CAST(data AS CHAR)" : "data::text"

      # Needs its own process: run_lifecycle resets column information before
      # each example, which hides the memoised attribute types this is about.
      specify do
        run_in_subprocess(<<~RUBY, env: { "DATABASE_URL" => ENV["DATABASE_URL"], "RAILS_ENV" => "test" }, stderr: $stderr)
          require "rails"
          require "active_record/railtie"
          require "ruby_event_store"
          require "ruby_event_store/active_record"

          Class.new(Rails::Application) do
            config.root = __dir__
            config.eager_load = true
            config.secret_key_base = "i_am_a_secret"
            config.active_record.maintain_test_schema = false
            config.logger = Logger.new(IO::NULL)

            initializer(:repository) do
              config.repository = RubyEventStore::ActiveRecord::EventRepository.new(serializer: JSON)
            end
          end.initialize!

          require "rails/test_help"

          record = RubyEventStore::Record.new(
            event_id: SecureRandom.uuid,
            data: { "foo" => "bar" },
            metadata: {},
            event_type: "Dummy",
            timestamp: Time.now.utc,
            valid_at: Time.now.utc
          )
          Rails.application.config.repository.append_to_stream(
            [record], RubyEventStore::Stream.new("stream"), RubyEventStore::ExpectedVersion.auto
          )

          foo = ::ActiveRecord::Base.connection.select_value(
            "SELECT #{extract} FROM event_store_events WHERE event_id = '\#{record.event_id}'"
          )
          exit 0 if foo == "bar"

          raw = ::ActiveRecord::Base.connection.select_value(
            "SELECT #{as_text} FROM event_store_events WHERE event_id = '\#{record.event_id}'"
          )
          warn "#{extract} returned \#{foo.inspect}; the column holds \#{raw.inspect}"
          exit 1
        RUBY
      end if (postgres || mysql) && json_column
    end
  end
end
