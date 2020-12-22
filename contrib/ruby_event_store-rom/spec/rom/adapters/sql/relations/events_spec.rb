require 'spec_helper'
require 'ruby_event_store/rom/sql'
require 'ruby_event_store/spec/rom/relations/events_lint'

module RubyEventStore
  module ROM
  module SQL
  RSpec.describe Relations::Events do
    let(:rom_helper) { SpecHelper.new }

    it_behaves_like :events_relation, Relations::Events
  end
  end
  end
end
