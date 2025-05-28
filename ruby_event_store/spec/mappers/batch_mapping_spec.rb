# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  module Mappers
    ::RSpec.describe BatchMapping do
      mk_repository = -> { InMemoryRepository.new }

      let(:records) { 3.times.map { SRecord.new(event_id: SecureRandom.uuid) } }
      let(:repository) do
        mk_repository.call.tap { |repo| repo.append_to_stream(records, Stream.new("other"), ExpectedVersion.none) }
      end

      specify "use batch mapping with custom mapper" do
        mapper =
          Class
            .new do
              include BatchMapping

              def record_to_event(record) = record.event_id
            end
            .new
        specification =
          Specification.new(SpecificationReader.new(repository, mapper, mapping: RubyEventStore::BatchMapping))
        records.each { |record| expect(mapper).to receive(:record_to_event).with(record).and_call_original }
        expect(specification.to_a).to eq(records.map(&:event_id))
      end
    end
  end
end
