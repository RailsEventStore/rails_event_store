require 'spec_helper'
require 'pathname'
require 'childprocess'
require 'fileutils'

RSpec.describe RailsEventStoreActiveRecord do
  include SchemaHelper

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
    pathname = Pathname.new(__FILE__).dirname
    cwd = pathname.join("without_rails")
    FileUtils.rm(cwd.join("Gemfile.lock")) if File.exists?(cwd.join("Gemfile.lock"))
    process = ChildProcess.build("bundle", "exec", "ruby", "runme.rb")
    process.environment['BUNDLE_GEMFILE'] = cwd.join('Gemfile')
    process.environment['DATABASE_URL']   = ENV['DATABASE_URL']
    process.environment['RAILS_VERSION']  = ENV['RAILS_VERSION']
    process.environment['VERBOSE'] = 'true'
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