require 'spec_helper'

RSpec.describe "test migration from v0.33.0" do
  include SchemaHelper

  specify do
    validate_migration('Gemfile.0_33_0') do
      run_migration('index_by_event_type')
      run_migration('limit_for_event_id')
      run_migration('binary_data_and_metadata')
    end
  end
end
