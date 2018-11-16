require 'spec_helper'
require 'pathname'
require 'active_record'
require 'logger'
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
      ActiveRecord::Schema.verbose = $verbose
      run_subprocess(File.join(__dir__, "schema"), "fill_data.rb")
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
