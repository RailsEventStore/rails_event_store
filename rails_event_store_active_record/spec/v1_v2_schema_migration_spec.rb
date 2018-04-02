require 'spec_helper'
require 'pathname'
require 'childprocess'
require 'active_record'
require 'logger'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

class EventA2 < RubyEventStore::Event
end

RSpec.describe "v1_v2_migration" do
  include SchemaHelper

  MigrationRubyCode = File.read(File.expand_path('../../lib/rails_event_store_active_record/generators/templates/v1_v2_migration_template.rb', __FILE__) )
  migration_version = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0") ? "" : "[4.2]"
  MigrationRubyCode.gsub!("<%= migration_version %>", migration_version)

  specify do
    begin
      establish_database_connection
      load_database_schema
      skip("in-memory sqlite cannot run this test") if ENV['DATABASE_URL'].include?(":memory:")
      dump_current_schema
      drop_existing_tables_to_clean_state
      fill_data_using_older_gem
      run_the_migration
      reset_columns_information
      verify_all_events_stream
      verify_event_sourced_stream
      verify_technical_stream
      compare_new_schema
    ensure
      drop_legacy_database
    end
  end

  private

  def repository
    @repository ||= RailsEventStoreActiveRecord::EventRepository.new
  end

  def fill_data_using_older_gem
    pathname = Pathname.new(__FILE__).dirname
    cwd = pathname.join("v1_v2_schema_migration")
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

  def run_the_migration
    eval(MigrationRubyCode)
    MigrateResSchemaV1ToV2.class_eval do
      def preserve_positions?(stream_name)
        stream_name == "Order-1"
      end
    end
    MigrateResSchemaV1ToV2.new.up
  end

  def reset_columns_information
    RailsEventStoreActiveRecord::Event.reset_column_information
    RailsEventStoreActiveRecord::EventInStream.reset_column_information
  end

  def verify_all_events_stream
    events = repository.read_all_streams_forward(:head, 100)
    expect(events.size).to eq(9)
    expect(events.map(&:event_id)).to eq(%w(
      94b297a3-5a29-4942-9038-3efeceb4d905
      6a31b594-7d8f-428b-916f-496f6da05bfd
      011cc5c4-d638-4785-9aa0-7d6a2d3e2a58
      d39cb65f-bc3c-4fbb-9470-52bf5e322bba
      f2cecc51-adb1-4d83-b3ca-483d26311f03
      600e1e1b-7fdf-44e2-a406-8b612c67c881
      9009df88-6044-4a62-b7ae-098c42a9c5e1
      cefdd213-0c92-46f6-bbdf-3ea9542d969a
      36775fcd-c5d8-49c9-bf70-f460ba12d7c2
    ))
    positions = RailsEventStoreActiveRecord::EventInStream.
      where(stream: "all").
      order("position ASC").
      to_a.
      map(&:position).uniq
    expect(positions).to eq([nil])
  end

  def verify_event_sourced_stream
    events = repository.read_stream_events_forward("Order-1")
    expect(events.map(&:event_id)).to eq(%w(
      d39cb65f-bc3c-4fbb-9470-52bf5e322bba
      f2cecc51-adb1-4d83-b3ca-483d26311f03
      600e1e1b-7fdf-44e2-a406-8b612c67c881
    ))
    positions = RailsEventStoreActiveRecord::EventInStream.
      where(stream: "Order-1").
      order("position ASC").
      to_a.
      map(&:position)
    expect(positions).to eq([0, 1, 2])
    expect do
      repository.append_to_stream(SRecord.new(event_id: "7c485b58-2d6a-4017-a174-8ab41ea4a4dd"),
        "Order-1",
        1
      )
    end.to raise_error(RubyEventStore::WrongExpectedEventVersion)
    repository.append_to_stream(SRecord.new(event_id: "3cf767d5-16ad-43a7-8d65-bb5575b301f2"),
      "Order-1",
      2
    )
  end

  def verify_technical_stream
    events = repository.read_stream_events_forward("WroclawBuyers")
    expect(events.map(&:event_id)).to eq(%w(
      9009df88-6044-4a62-b7ae-098c42a9c5e1
      cefdd213-0c92-46f6-bbdf-3ea9542d969a
      36775fcd-c5d8-49c9-bf70-f460ba12d7c2
    ))
    positions = RailsEventStoreActiveRecord::EventInStream.
      where(stream: "WroclawBuyers").
      order("position ASC").
      to_a.
      map(&:position).
      uniq
    expect(positions).to eq([nil])
  end

  def drop_existing_tables_to_clean_state
    drop_database
  end

  def dump_current_schema
    @schema = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, @schema)
    @schema.rewind
    @schema = @schema.read
  end

  def compare_new_schema
    schema = StringIO.new
    ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, schema)
    schema.rewind
    schema = schema.read
    expect(schema).to eq(@schema)
  end
end
