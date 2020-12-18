require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/unit_of_work_lint'

module RubyEventStore
  module ROM
  module Memory
  RSpec.describe UnitOfWork do
    let(:rom_helper) { SpecHelper.new }

    it_behaves_like :unit_of_work, UnitOfWork

    specify '#mutex can synchronize threads' do
      expect(UnitOfWork.mutex).to be_a(Mutex)
    end
  end
  end
  end
end
