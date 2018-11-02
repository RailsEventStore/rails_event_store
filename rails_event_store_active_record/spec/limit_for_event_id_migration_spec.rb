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
  migration_version = rails_dependent("", "[4.2]")
  MigrationRubyCode.gsub!("<%= migration_version %>", migration_version)

  specify do
    begin
      establish_database_connection
      fill_data_using_older_gem
      before = RailsEventStoreActiveRecord::EventInStream.columns
        .select{|c| c.name == 'event_id'}.first
      expect(before .limit).to eq(nil)

      run_the_migration
      reset_columns_information
      after = RailsEventStoreActiveRecord::EventInStream.columns
        .select{|c| c.name == 'event_id'}.first
      expect(after.limit).to eq(36)
    ensure
      drop_database
    end
  end

  private


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
end
