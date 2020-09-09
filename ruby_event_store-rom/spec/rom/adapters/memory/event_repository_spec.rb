require 'spec_helper'
require 'ruby_event_store/rom/memory'
require 'ruby_event_store/spec/rom/event_repository_lint'

module RubyEventStore
  module ROM
    RSpec.describe EventRepository do
      around(:each) do |example|
        rom_helper.run_lifecycle { example.run }
      end

      let(:rom_helper) { Memory::SpecHelper.new }
      let(:env) { rom_helper.env }
      let(:rom_container) { env.rom_container }

      let(:test_race_conditions_any)  { true }
      let(:test_race_conditions_auto) { true }
      let(:test_binary)               { true }
      let(:test_change)               { true }

      it_behaves_like :event_repository, ->{ EventRepository.new(rom: Memory::SpecHelper.new.env) }
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