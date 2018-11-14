require 'spec_helper'
require 'pathname'
require 'childprocess'
require 'active_record'
require 'logger'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

RSpec.describe "index_by_event_type_migration" do
  include SchemaHelper

  specify do
    begin
      establish_database_connection
      fill_data_using_older_gem
      before =
        ActiveRecord::Base.connection.indexes('event_store_events')
          .find { |c| c.name == 'index_event_store_events_on_event_type' }
      expect(before).to eq(nil)

      run_migration('index_by_event_type')

      after =
        ActiveRecord::Base.connection.indexes('event_store_events')
          .find { |c| c.name == 'index_event_store_events_on_event_type' }
      expect(after.columns).to eq(['event_type'])
      expect(after.unique).to eq(false)
    ensure
      drop_database
    end
  end

  private

  def fill_data_using_older_gem
    pathname = Pathname.new(__FILE__).dirname
    cwd = pathname.join("before_index_by_event_type")
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
