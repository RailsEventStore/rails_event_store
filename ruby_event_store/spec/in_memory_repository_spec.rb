require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'
require_relative 'mappers/events_pb.rb'

module RubyEventStore
  RSpec.describe InMemoryRepository do
    let(:test_race_conditions_any)   { true }
    let(:test_race_conditions_auto)  { true }
    let(:test_expected_version_auto) { true }
    let(:test_link_events_to_stream) { true }

    it_behaves_like :event_repository, InMemoryRepository

    it 'does not allow same event twice in a stream - checks stream events before checking all events' do
      repository = InMemoryRepository.new
      repository.append_to_stream(
        TestDomainEvent.new(event_id: eid = "fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a"),
        'other',
        -1
      )
      repository.append_to_stream(
        TestDomainEvent.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
        'stream',
        -1
      )
      expect(eid).not_to receive(:eql?)
      expect do
        repository.append_to_stream(
          TestDomainEvent.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
          'stream',
          0
        )
      end.to raise_error(RubyEventStore::EventDuplicatedInStream)
    end

    specify 'add_metadata default mapper' do
      repository = InMemoryRepository.new
      event = TestDomainEvent.new
      repository.add_metadata(event, :yo, 1)
      expect(event.metadata.fetch(:yo)).to eq(1)
    end

    specify 'add_metadata protobuf mapper' do
      event = ResTesting::OrderCreated.new
      repository = InMemoryRepository.new(mapper: RubyEventStore::Mappers::Protobuf.new)
      repository.add_metadata(event, :customer_id, 123)
      expect(event.customer_id).to eq(123)
    end

    def verify_conncurency_assumptions
    end

    def cleanup_concurrency_test
    end

    def additional_limited_concurrency_for_auto_check
    end
  end
end
