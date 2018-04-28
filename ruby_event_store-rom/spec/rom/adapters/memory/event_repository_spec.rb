require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/event_repository_lint'

module RubyEventStore::ROM
  RSpec.describe EventRepository do
    let(:rom_helper) { Memory::SpecHelper.new }

    it_behaves_like :rom_event_repository, EventRepository
  end
end
