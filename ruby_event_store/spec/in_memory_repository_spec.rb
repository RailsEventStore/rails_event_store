require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'

module RubyEventStore
  RSpec.describe InMemoryRepository do
    let(:test_race_conditions_any)   { true }
    let(:test_race_conditions_auto)  { true }
    let(:test_expected_version_auto) { true }
    let(:test_link_events_to_stream) { true }
    let(:test_binary) { true }
    let(:test_change) { true }

    it_behaves_like :event_repository, InMemoryRepository

    it 'does not confuse all with GLOBAL_STREAM' do
      repository = InMemoryRepository.new
      repository.append_to_stream(
        SRecord.new(event_id: "fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a"),
        Stream.new('all'),
        ExpectedVersion.none
      )
      repository.append_to_stream(
        SRecord.new(event_id: "a1b49edb-7636-416f-874a-88f94b859bef"),
        Stream.new('stream'),
        ExpectedVersion.none
      )

      expect(repository.read(Specification.new(SpecificationReader.new(repository, Mappers::NullMapper.new)).result))
        .to(contains_ids(%w[fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a a1b49edb-7636-416f-874a-88f94b859bef]))

      expect(repository.read(Specification.new(SpecificationReader.new(repository, Mappers::NullMapper.new)).stream('all').result))
        .to(contains_ids(%w[fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a]))
    end

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
  end
end
