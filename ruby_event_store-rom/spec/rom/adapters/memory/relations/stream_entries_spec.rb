require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/relations/stream_entries_lint'

module RubyEventStore::ROM::Memory
  RSpec.describe Relations::StreamEntries do
    let(:rom_helper) { SpecHelper.new }

    around(:each) do |example|
      rom_helper.run_lifecycle { example.run }
    end

    it_behaves_like :stream_entries_relation, Relations::StreamEntries
  end
end
