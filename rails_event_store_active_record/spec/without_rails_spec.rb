require 'spec_helper'
require 'pathname'
require 'fileutils'
require_relative '../../support/helpers/subprocess_helper'

RSpec.describe RailsEventStoreActiveRecord, :integration do
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
    skip("in-memory sqlite cannot run this test") if ENV['DATABASE_URL'].include?(":memory:")

    run_in_subprocess(<<~EOF, env: ENV.to_h.slice('DATABASE_URL', 'VERBOSE'))
      require 'bundler/inline'

      gemfile do
        gem 'ruby_event_store',                path: '../ruby_event_store'
        gem 'rails_event_store_active_record', path: '../rails_event_store_active_record'
        gem 'activerecord', '6.0.3.4'
        gem 'pg',           '1.2.3'
        gem 'mysql2',       '0.5.3'
        gem 'sqlite3',      '1.4.2'
      end

      require 'active_record'
      require 'rails_event_store_active_record'
      require 'ruby_event_store'
      require 'logger'

      $verbose = ENV.has_key?('VERBOSE') ? true : false

      ActiveRecord::Base.logger = Logger.new(STDOUT) if $verbose
      ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

      EventA1 = Class.new(RubyEventStore::Event)

      client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new(serializer: YAML))
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
