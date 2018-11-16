require 'spec_helper'
require 'pathname'
require 'active_record'
require 'logger'
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'
require_relative '../../lib/subprocess_helper'


RSpec.describe "index_by_event_type_migration" do
  include SchemaHelper
  include SubprocessHelper

  specify do
    begin
      establish_database_connection
      pathname = Pathname.new(__FILE__).dirname
      run_subprocess(pathname.join("before_index_by_event_type"), "fill_data.rb")
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
