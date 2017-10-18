require 'spec_helper'
require 'pathname'
require 'childprocess'
require 'active_record'
require 'logger'

RSpec.describe "v1_v2_migration" do
  MigrationRubyCode = File.read(File.expand_path('../../lib/rails_event_store_active_record/generators/templates/v1_v2_migration_template.rb', __FILE__) )
  migration_version = Gem::Version.new(ActiveRecord::VERSION::STRING) < Gem::Version.new("5.0.0") ? "" : "[4.2]"
  MigrationRubyCode.gsub!("<%= migration_version %>", migration_version)

  specify "try harder" do
    pathname = Pathname.new(__FILE__).dirname
    cwd = pathname.join("v1_v2_schema_migration")
    process = ChildProcess.build("bundle", "exec", "ruby", "fill_data.rb")
    process.environment['BUNDLE_GEMFILE'] = cwd.join('Gemfile')
    process.cwd = cwd
    process.start
    begin
      process.poll_for_exit(10)
    rescue ChildProcess::TimeoutError
      process.stop
    end
    expect(process.exit_code).to eq(0)
    eval(MigrationRubyCode)
    MigrateResSchemaV1ToV2.class_eval do
      def preserve_positions?(stream_name)
        stream_name == "Order-1"
      end
    end
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    MigrateResSchemaV1ToV2.new.up

  end
end