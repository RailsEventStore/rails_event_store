require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'

module RubyEventStore
  RSpec.describe Repositories::InMemory do
    # There is no way to use in-memory adapter in a
    # lock-free, unlimited concurrency way
    let(:test_race_conditions_any)   { false }
    let(:test_race_conditions_auto)  { true }
    let(:test_expected_version_auto) { true }
    let(:test_link_events_to_stream) { true }

    it_behaves_like :event_repository, Repositories::InMemory

    it 'does not allow same event twice in a stream - checks stream events before checking all events' do
      repository = Repositories::InMemory.new
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

    def verify_conncurency_assumptions
    end

    def cleanup_concurrency_test
    end

    def additional_limited_concurrency_for_auto_check
    end
  end
end
