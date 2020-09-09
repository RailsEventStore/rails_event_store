require 'spec_helper'
require 'ruby_event_store/rom/sql'
require 'ruby_event_store/spec/rom/event_repository_lint'

module RubyEventStore
  module ROM
    RSpec.describe EventRepository do
      around(:each) do |example|
        rom_helper.run_lifecycle { example.run }
      end

      let(:rom_helper) { SQL::SpecHelper.new }
      let(:env) { rom_helper.env }
      let(:rom_container) { env.rom_container }

      let(:test_race_conditions_auto) { rom_helper.has_connection_pooling? }
      let(:test_race_conditions_any)  { rom_helper.has_connection_pooling? }
      let(:test_binary)               { false }
      let(:test_change)               { rom_helper.supports_upsert? }

      it_behaves_like :event_repository, ->{ EventRepository.new(rom: SQL::SpecHelper.new.env) }, [::ROM::SQL::Error]
      it_behaves_like :rom_event_repository, EventRepository

      def verify_conncurency_assumptions
        expect(rom_helper.connection_pool_size).to eq(5)
      end

      def cleanup_concurrency_test
        rom_helper.close_pool_connection
      end

      def additional_limited_concurrency_for_auto_check
        positions = rom_container.relations[:stream_entries]
          .ordered(:forward, RubyEventStore::Stream.new('stream'))
          .map { |entity| entity[:position] }
        expect(positions).to eq((0..positions.size - 1).to_a)
      end
    end
  end
end
