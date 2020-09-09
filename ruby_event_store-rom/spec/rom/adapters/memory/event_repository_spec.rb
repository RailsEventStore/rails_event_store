require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/event_repository_lint'

module RubyEventStore
  module ROM
    RSpec.describe EventRepository do
      let(:rom_helper) { Memory::SpecHelper.new }

      let(:test_race_conditions_any)  { true }
      let(:test_race_conditions_auto) { true }
      let(:test_binary)               { true }
      let(:test_change)               { true }

      subject(:repository) { EventRepository.new(rom: rom_helper.env) }

      it_behaves_like :event_repository, EventRepository
      it_behaves_like :rom_event_repository, EventRepository

      def verify_conncurency_assumptions
      end

      def cleanup_concurrency_test
      end

      def additional_limited_concurrency_for_auto_check
      end
    end
  end
end