require 'spec_helper'
require 'pathname'
require 'childprocess'
require 'active_record'
require 'logger'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

RSpec.describe "binary_data_and_metadata_migration" do
  include SchemaHelper

  specify do
    begin
      establish_database_connection
      load_database_schema
      dump_current_schema
      drop_database
      fill_data_using_older_gem
      clear_connection_schema_cache
      run_migration('binary_data_and_metadata')
      reset_columns_information
      verify_event
      compare_new_schema
    ensure
      drop_database
    end
  end

  private

  def clear_connection_schema_cache
    RailsEventStoreActiveRecord::Event.connection.schema_cache.clear!
  end

  def mapper
    RubyEventStore::Mappers::NullMapper.new
  end

  def repository
    @repository ||= RailsEventStoreActiveRecord::EventRepository.new
  end

  def specification
    @specification ||= RubyEventStore::Specification.new(
      RubyEventStore::SpecificationReader.new(repository, mapper)
    )
  end

  def verify_event
    event = repository.read(specification.with_id("94b297a3-5a29-4942-9038-3efeceb4d905").result).first
    expect(YAML.load(event.data)).to eq({
      all: true,
      a: 1,
      text: "text",
    })
  end

  def reset_columns_information
    RailsEventStoreActiveRecord::Event.reset_column_information
    RailsEventStoreActiveRecord::EventInStream.reset_column_information
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

  def fill_data_using_older_gem
    pathname = Pathname.new(__FILE__).dirname
    cwd = pathname.join("before_binary_data_and_metadata")
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
