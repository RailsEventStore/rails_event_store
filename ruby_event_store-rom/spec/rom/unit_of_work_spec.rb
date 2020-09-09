require 'spec_helper'
require 'ruby_event_store/rom/sql'
require 'ruby_event_store/spec/rom/event_repository_lint'

module RubyEventStore
  module ROM
  RSpec.describe UnitOfWork do
    let(:rom_helper) { Memory::SpecHelper.new }

    it_behaves_like :unit_of_work, UnitOfWork
  end
  end
end
