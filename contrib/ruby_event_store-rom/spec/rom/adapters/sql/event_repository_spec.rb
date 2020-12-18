require 'spec_helper'
require 'ruby_event_store/rom/sql'
require 'ruby_event_store/spec/rom/event_repository_lint'

module RubyEventStore
  module ROM
    RSpec.describe EventRepository do
      include_examples :rom_event_repository
      let(:rom_helper) { SQL::SpecHelper.new }

      def additional_limited_concurrency_for_auto_check
        positions =
          rom_container
            .relations[:stream_entries]
            .ordered(:forward, RubyEventStore::Stream.new('stream'))
            .map { |entity| entity[:position] }
        expect(positions).to eq((0..positions.size - 1).to_a)
      end
    end
  end
end
