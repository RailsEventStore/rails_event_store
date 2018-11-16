require 'spec_helper'
require 'active_record'
require 'ruby_event_store'
require_relative '../../lib/subprocess_helper'


RSpec.describe "index_by_event_type_migration" do
  include SchemaHelper
  include SubprocessHelper

  specify do
    begin
      establish_database_connection
      run_in_subprocess(<<~EOF, gemfile: 'Gemfile.0_33_0')
        require 'rails/generators'
        require 'rails_event_store_active_record'
        require 'ruby_event_store'
        require 'logger'
        require '../lib/migrator'

        $verbose = ENV.has_key?('VERBOSE') ? true : false
        ActiveRecord::Schema.verbose = $verbose
        ActiveRecord::Base.logger    = Logger.new(STDOUT) if $verbose
        ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

        gem_path = $LOAD_PATH.find { |path| path.match(/rails_event_store_active_record/) }
        Migrator.new(File.expand_path('rails_event_store_active_record/generators/templates', gem_path))
          .run_migration('create_event_store_events', 'migration')
      EOF

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
end
