# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  ::RSpec.describe SpecificationReader do
    mk_repository = -> { InMemoryRepository.new }

    let(:records) { 3.times.map { SRecord.new(event_id: SecureRandom.uuid) } }
    let(:repository) do
      mk_repository.call.tap do |repo|
        repo.append_to_stream(
          records,
          Stream.new("other"),
          ExpectedVersion.none
        )
      end
    end

    specify "reading from mapper in batches" do
      mapper = spy
      specification =
        Specification.new(
          SpecificationReader.new(repository, mapper, mapping: BatchMapping)
        )
      specification.to_a
      expect(mapper).to have_received(:records_to_events).with(records)
    end

    specify "reading from non batch compatible mappers" do
      mapper = spy

      specification =
        Specification.new(SpecificationReader.new(repository, mapper))
      specification.to_a
      records.each do |record|
        expect(mapper).to have_received(:record_to_event).with(record)
      end
    end

    specify "reading single event from mapper in batches" do
      mapper = spy
      specification =
        Specification.new(
          SpecificationReader.new(repository, mapper, mapping: BatchMapping)
        )
      specification.last
      expect(mapper).to have_received(:records_to_events).with([records.last])
    end

    specify "reading single event from non batch compatible mappers" do
      mapper = spy

      specification =
        Specification.new(SpecificationReader.new(repository, mapper))
      specification.last
      expect(mapper).to have_received(:record_to_event).with(records.last)
    end
  end
end
