require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/event_repository_lint'

module RubyEventStore
  module ROM
    RSpec.describe EventRepository do
      include_examples :rom_event_repository
      let(:rom_helper) { Memory::SpecHelper.new }
    end
  end
end