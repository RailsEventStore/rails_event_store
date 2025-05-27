# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  ::RSpec.describe BatchMapping do
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

    class CustomMapper
      include Mappers::BatchMapping

      def record_to_event(record)
        record
      end
    end

    specify "use batch mapping with custom mapper" do
      mapper = CustomMapper.new
      specification =
        Specification.new(
          SpecificationReader.new(repository, mapper, mapping: BatchMapping)
        )
      records.each do |record|
        expect(mapper).to receive(:record_to_event).with(
          record
        ).and_call_original
      end
      expect(specification.to_a).to eq(records)
    end
  end
end
