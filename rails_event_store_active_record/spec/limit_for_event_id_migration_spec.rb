require 'spec_helper'
require 'pathname'
require 'childprocess'
require 'active_record'
require 'logger'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

RSpec.describe "limit_for_event_id_migration" do
  include SchemaHelper

  MigrationRubyCode = File.read(File.expand_path('../../lib/rails_event_store_active_record/generators/templates/limit_for_event_id_template.rb', __FILE__) )
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
      compare_new_schema
    ensure
      drop_legacy_database
    end
  end

  private

  def repository
    @repository ||= RailsEventStoreActiveRecord::EventRepository.new
  end

  def mapper
    RubyEventStore::Mappers::NullMapper.new
  end

  def specification
    @specification ||= RubyEventStore::Specification.new(
      RubyEventStore::SpecificationReader.new(repository, mapper)
    )
  end

  def fill_data_using_older_gem
    pathname = Pathname.new(__FILE__).dirname
    cwd = pathname.join("before_limit_for_event_id")
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
    LimitForEventId.new.up
  end

  def reset_columns_information
    RailsEventStoreActiveRecord::Event.reset_column_information
    RailsEventStoreActiveRecord::EventInStream.reset_column_information
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
