require 'spec_helper'

RSpec.describe "database schema migrations" do
  include SchemaHelper

  specify "migrate from v0.33.0 to v0.34.0" do
    validate_migration('Gemfile.0_33_0', 'Gemfile.0_34_0',
                       source_template_name: 'migration') do
      run_migration('index_by_event_type')
      run_migration('limit_for_event_id')
    end
  end
end
