require 'spec_helper'
require 'ruby_event_store/rom/sql'
require 'ruby_event_store/spec/rom/unit_of_work_lint'

module RubyEventStore::ROM::SQL
  RSpec.describe UnitOfWork do
    let(:rom_helper) { SpecHelper.new }

    it_behaves_like :unit_of_work, UnitOfWork
  end
end
