require 'spec_helper'
require 'ruby_event_store/rom/sql'
require 'ruby_event_store/spec/rom/relations/stream_entries_lint'

module RubyEventStore
  module ROM
  module SQL
  RSpec.describe Relations::StreamEntries do
    let(:rom_helper) { SpecHelper.new }

    it_behaves_like :stream_entries_relation, Relations::StreamEntries
  end
  end
  end
end
