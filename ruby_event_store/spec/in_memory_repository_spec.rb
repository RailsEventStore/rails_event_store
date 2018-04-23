require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'
require_relative 'mappers/events_pb.rb'

module RubyEventStore
  RSpec.describe InMemoryRepository do
    let(:test_race_conditions_any)   { true }
    let(:test_race_conditions_auto)  { true }
    let(:test_expected_version_auto) { true }
    let(:test_link_events_to_stream) { true }
    let(:test_binary) { true }

    it_behaves_like :event_repository, InMemoryRepository

    it 'does not allow same event twice in a stream - checks stream events before checking all events' do
      repository = InMemoryRepository.new
      repository.append_to_stream(
        SRecord.new(event_id: eid = "fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a"),
        Stream.new('other'),
        ExpectedVersion.none
      )
      repository.append_to_stream(
        SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
        Stream.new('stream'),
        ExpectedVersion.none
      )
      expect(eid).not_to receive(:eql?)
      expect do
        repository.append_to_stream(
          SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
          Stream.new('stream'),
          ExpectedVersion.new(0)
        )
      end.to raise_error(RubyEventStore::EventDuplicatedInStream)
    end

    def verify_conncurency_assumptions
    end

    def cleanup_concurrency_test
    end

    def additional_limited_concurrency_for_auto_check
    end

    def migrate_to_binary
    end
  end
end
