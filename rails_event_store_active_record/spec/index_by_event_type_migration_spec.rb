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
      load_database_schema
      current_schema = dump_schema
      drop_database
      close_database_connection
      build_schema('Gemfile.0_33_0')
      establish_database_connection
      run_migration('limit_for_event_id')
      run_migration('index_by_event_type')
      run_migration('binary_data_and_metadata')
      expect(dump_schema).to eq(current_schema)
    ensure
      drop_database
    end
  end
end
