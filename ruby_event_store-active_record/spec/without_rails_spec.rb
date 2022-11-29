require "spec_helper"
require "pathname"
require "fileutils"
require_relative "../../support/helpers/subprocess_helper"

RSpec.describe RubyEventStore::ActiveRecord, :integration do
  include SchemaHelper
  include SubprocessHelper

  # assume schema was properly generated
  # manually by a developer by looking at
  # our source file
  around(:each) do |example|
    begin
      establish_database_connection
      load_database_schema
      example.run
    ensure
      drop_database
    end
  end

  specify "can be used without rails", mutant: false do
    skip("in-memory sqlite cannot run this test") if ENV["DATABASE_URL"].include?(":memory:")

    run_in_subprocess(<<~EOF, env: ENV.to_h.slice("DATABASE_URL", "VERBOSE"))
      require 'bundler/inline'

      gemfile do
        source 'https://rubygems.org'
        gem 'ruby_event_store',                path: '../ruby_event_store'
        gem 'ruby_event_store-active_record',  path: '../ruby_event_store-active_record'
        gem 'activerecord', '7.0.3'
        gem 'pg',           '1.4.4'
        gem 'mysql2',       '0.5.4'
        gem 'sqlite3',      '1.5.3'
      end

      require 'active_record'
      require 'ruby_event_store/active_record'
      require 'ruby_event_store'
      require 'logger'

      $verbose = ENV.has_key?('VERBOSE') ? true : false

      ActiveRecord::Base.logger = Logger.new(STDOUT) if $verbose
      ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

      EventA1 = Class.new(RubyEventStore::Event)

      client = RubyEventStore::Client.new(repository: RubyEventStore::ActiveRecord::EventRepository.new(serializer: RubyEventStore::Serializers::YAML))
      client.append(
        EventA1.new(
          data: {
            a1: true,
            decimal: BigDecimal("20.00"),
          },
          event_id: "d39cb65f-bc3c-4fbb-9470-52bf5e322bba"
        ),
        stream_name: "Order-1",
      )
    EOF
  end
end
