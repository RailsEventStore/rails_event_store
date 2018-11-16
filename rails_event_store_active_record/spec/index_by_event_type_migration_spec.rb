require 'spec_helper'
require 'pathname'
require 'active_record'
require 'logger'
require 'ruby_event_store'
require 'tempfile'
require 'ruby_event_store/spec/event_repository_lint'
require_relative '../../lib/subprocess_helper'


RSpec.describe "index_by_event_type_migration" do
  include SchemaHelper
  include SubprocessHelper

  specify do
    script = Tempfile.new
    begin
      establish_database_connection
      script.write <<~EOF
        require 'rails/generators'
        require 'rails_event_store_active_record'
        require 'ruby_event_store'
        require 'logger'
        require '../../../lib/migrator'
        
        $verbose = ENV.has_key?('VERBOSE') ? true : false
        ActiveRecord::Schema.verbose = $verbose
        ActiveRecord::Base.logger    = Logger.new(STDOUT) if $verbose
        ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'].gsub("db.sqlite3", "../../db.sqlite3"))
        
        gem_path = $LOAD_PATH.find { |path| path.match(/rails_event_store_active_record/) }
        Migrator.new(File.expand_path('rails_event_store_active_record/generators/templates', gem_path))
          .run_migration('create_event_store_events', 'migration')
      EOF
      script.close

      run_subprocess(File.join(__dir__, "before_index_by_event_type"), script.path)

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
      script.unlink
    end
  end
end
