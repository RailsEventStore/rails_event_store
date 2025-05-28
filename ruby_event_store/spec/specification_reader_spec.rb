# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  ::RSpec.describe SpecificationReader do
    mk_repository = -> { InMemoryRepository.new }

    let(:records) { 3.times.map { SRecord.new(event_id: SecureRandom.uuid) } }
    let(:repository) do
      mk_repository.call.tap { |repo| repo.append_to_stream(records, Stream.new("other"), ExpectedVersion.none) }
    end

    specify "reading from mapper in batches" do
      mapper = spy
      specification = Specification.new(SpecificationReader.new(repository, mapper, mapping: BatchMapping))
      expect(specification.to_a).to be_an(Array)
      expect(mapper).to have_received(:records_to_events).with(records)
    end

    specify "reading from non batch compatible mappers" do
      mapper = spy

      specification = Specification.new(SpecificationReader.new(repository, mapper))
      expect(specification.to_a).to be_an(Array)
      records.each { |record| expect(mapper).to have_received(:record_to_event).with(record) }
    end

    specify "reading single event from mapper in batches" do
      mapper = spy
      specification = Specification.new(SpecificationReader.new(repository, mapper, mapping: BatchMapping))
      expect(specification.last).not_to be_an(Array)
      expect(mapper).to have_received(:records_to_events).with([records.last])
    end

    specify "reading single event from non batch compatible mappers" do
      mapper = spy

      specification = Specification.new(SpecificationReader.new(repository, mapper))
      expect(specification.last).not_to be_an(Array)
      expect(mapper).to have_received(:record_to_event).with(records.last)
    end

    specify "no mapping when no read records" do
      mapper = spy
      Specification.new(SpecificationReader.new(repository, mapper)).event(SecureRandom.uuid)
      Specification.new(SpecificationReader.new(repository, mapper)).stream("not-existing").to_a
      expect(mapper).not_to have_received(:record_to_event)
    end

    specify "counts read records" do
      mapper = spy
      expect(Specification.new(SpecificationReader.new(repository, mapper)).count).to eq(3)

      expect(Specification.new(SpecificationReader.new(repository, mapper)).stream("not-existing").count).to eq(0)
    end
  end
end
