require 'spec_helper'
require 'pathname'
require 'childprocess'
require 'active_record'
require 'logger'
require 'ruby_event_store'


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

  def silence_stderr
    $stderr = StringIO.new
    yield
    $stderr = STDERR
  end

  around(:each) do |example|
    begin
      ActiveRecord::Schema.verbose = $verbose
      fill_data_using_older_gem
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

  def fill_data_using_older_gem
    pathname = Pathname.new(__FILE__).dirname
    cwd = pathname.join("schema")
    FileUtils.rm(cwd.join("Gemfile.lock")) if File.exists?(cwd.join("Gemfile.lock"))
    process = ChildProcess.build("bundle", "exec", "ruby", "fill_data.rb")
    process.environment['BUNDLE_GEMFILE'] = cwd.join('Gemfile')
    process.environment['DATABASE_URL']   = ENV['DATABASE_URL']
    process.environment['RAILS_VERSION']  = ENV['RAILS_VERSION']
    process.cwd = cwd
    process.io.stdout = $stdout
    process.io.stderr = $stderr
    process.start
    begin
      process.poll_for_exit(10)
    rescue ChildProcess::TimeoutError
      process.stop
    end
    expect(process.exit_code).to eq(0)
  end
end
