require 'spec_helper'
require 'pathname'
require 'fileutils'
require_relative '../../lib/subprocess_helper'

RSpec.describe RailsEventStoreActiveRecord do
  include SchemaHelper
  include SubprocessHelper

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
    run_subprocess(File.join(__dir__, 'without_rails'), 'runme.rb')
  end
end