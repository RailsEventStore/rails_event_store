require 'spec_helper'
require 'ruby_event_store/rom/sql'
require 'ruby_event_store/spec/rom/relations/events_lint'

module RubyEventStore::ROM::SQL
  RSpec.describe Relations::Events do
    let(:rom_helper) { SpecHelper.new }

    around(:each) do |example|
      rom_helper.run_lifecycle { example.run }
    end

    it_behaves_like :events_relation, Relations::Events
  end
end
