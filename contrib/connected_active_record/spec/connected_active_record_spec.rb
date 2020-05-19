require "spec_helper"
require 'ruby_event_store'
require 'ruby_event_store/spec/event_repository_lint'

module ConnectedActiveRecord
  RSpec.describe Repository do
    include SchemaHelper

    around(:each) do |example|
      begin
        establish_database_connection
        load_database_schema
        example.run
      ensure
        drop_database
      end
    end

    let(:test_race_conditions_any)   { false }
    let(:test_race_conditions_auto)  { false }
    let(:test_binary) { false }
    let(:test_change) { false }

    it_behaves_like :event_repository, Repository
  end
end