require 'spec_helper'
require 'active_record'
require 'ruby_event_store'
require_relative '../../lib/subprocess_helper'

DummyEvent = Class.new(RubyEventStore::Event)

RSpec.describe "binary_data_and_metadata_migration" do
  include SchemaHelper
  include SubprocessHelper

  specify do
    begin
      establish_database_connection
      load_database_schema
      current_schema = dump_schema
      drop_database
      close_database_connection
      run_in_subprocess(<<~EOF, gemfile: 'Gemfile.0_34_0')
        require 'rails/generators'
        require 'rails_event_store_active_record'
        require 'ruby_event_store'
        require 'logger'
        require '../lib/migrator'

        $verbose = ENV.has_key?('VERBOSE') ? true : false
        ActiveRecord::Schema.verbose = $verbose
        ActiveRecord::Base.logger    = Logger.new(STDOUT) if $verbose
        ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

        gem_path = $LOAD_PATH.find { |path| path.match(/rails_event_store_active_record/) }
        Migrator.new(File.expand_path('rails_event_store_active_record/generators/templates', gem_path))
          .run_migration('create_event_store_events')

        DummyEvent = Class.new(RubyEventStore::Event)

        client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new)
        client.append(
          DummyEvent.new(
            event_id: "94b297a3-5a29-4942-9038-3efeceb4d905",
            data: {
              all: true,
              a: 1,
              text: "text",
            }
          )
        )
      EOF
      establish_database_connection
      run_migration('binary_data_and_metadata')
      verify_event
      expect(dump_schema).to eq(current_schema)
    ensure
      drop_database
    end
  end

  private

  def verify_event
    client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new)
    event  = client.read.event("94b297a3-5a29-4942-9038-3efeceb4d905")
    expect(event.data).to eq({
      all: true,
      a: 1,
      text: "text",
    })
  end
end
