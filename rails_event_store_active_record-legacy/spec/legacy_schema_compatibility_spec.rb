require 'spec_helper'
require 'active_record'
require 'ruby_event_store'
require_relative '../../lib/subprocess_helper'

class EventAll < RubyEventStore::Event
end
class EventA1 < RubyEventStore::Event
end
class EventA2 < RubyEventStore::Event
end
class EventB1 < RubyEventStore::Event
end
class EventB2 < RubyEventStore::Event
end

RSpec.describe "legacy schema compatibility" do
  include SchemaHelper
  include SubprocessHelper

  def silence_stderr
    $stderr = StringIO.new
    yield
    $stderr = STDERR
  end

  around(:each) do |example|
    begin
      run_in_subprocess(<<~EOF, gemfile: 'Gemfile.0_18_2')
        require 'rails/generators'
        require 'rails_event_store_active_record'
        require 'ruby_event_store'
        require 'logger'
        require '../lib/migrator'

        $verbose = ENV.has_key?('VERBOSE') ? true : false
        ActiveRecord::Schema.verbose = $verbose
        ActiveRecord::Base.logger = Logger.new(STDOUT) if $verbose
        ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

        gem_path = $LOAD_PATH.find { |path| path.match(/rails_event_store_active_record/) }
        Migrator.new(File.expand_path('rails_event_store_active_record/generators/templates', gem_path))
          .run_migration('create_event_store_events', 'migration')

        EventAll = Class.new(RubyEventStore::Event)
        
        client = RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new)
        client.append_to_stream(
          EventAll.new(
            data: {
              all: true,
              a: 1,
              text: "text",
            }, 
            event_id: "94b297a3-5a29-4942-9038-3efeceb4d905"
          )
        )
      EOF
      establish_database_connection
      silence_stderr { example.run }
    ensure
      drop_legacy_database
    end
  end

  specify "reading events" do
    skip("in-memory sqlite cannot run this test") if ENV['DATABASE_URL'].include?(":memory:")

    event = client.read.first
    expect(event.metadata[:timestamp]).to be_kind_of(Time)
  end

  specify "writing events" do
    skip("in-memory sqlite cannot run this test") if ENV['DATABASE_URL'].include?(":memory:")
    client.append(
      write_event = EventAll.new(metadata: { foo: 13 }),
      stream_name: 'foo',
      expected_version: -1
    )

    read_event = client.read.stream('foo').first
    expect(read_event).to eq(write_event)
    expect(read_event.metadata[:foo]).to eq(13)
    expect(read_event.metadata[:timestamp]).to be_kind_of(Time)
  end
  
  private

  let(:client) { RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::Legacy::EventRepository.new) }
end
