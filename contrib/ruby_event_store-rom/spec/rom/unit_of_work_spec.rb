require 'spec_helper'
require 'ruby_event_store/spec/rom/unit_of_work_lint'

module RubyEventStore
  module ROM
    RSpec.describe UnitOfWork do
      let(:rom_helper) { SpecHelper.new }

      it_behaves_like :unit_of_work, UnitOfWork
    end
  end
end
