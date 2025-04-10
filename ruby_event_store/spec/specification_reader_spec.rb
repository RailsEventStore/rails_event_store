
# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/event_repository_lint"

module RubyEventStore
  ::RSpec.describe SpecificationReader do
    mk_repository = -> { InMemoryRepository.new }

    let(:repository) {
      mk_repository.call.tap do |repo|
        repo.append_to_stream(
          [SRecord.new(event_id: "fbce0b3d-40e3-4d1d-90a1-901f1ded5a4a")],
          Stream.new("other"),
          ExpectedVersion.none
        )
      end
    }
    let(:mapper_klass) {
      Class.new(Mappers::Default) do
        attr_reader :invoked_map_records_to_events

        def map_records_to_events(...)
          @invoked_map_records_to_events = true
          super(...)
        end
      end
    }

    specify "reading invokes the mapper in batches" do
      mapper = mapper_klass.new
      specification = Specification.new(
        SpecificationReader.new(repository, mapper)
      )
      specification.to_a
      expect(mapper.invoked_map_records_to_events).to eq(true)
    end

    specify "specification can still handle non batch compatible mappers" do
      mapper_klass.undef_method(:map_records_to_events)
      mapper = mapper_klass.new
      expect(Warning).to receive(:warn).with("Your custom mapper does not support batch reading. This behaviour will be deprecated in future releases. You can include RubyEventStore::Mappers::BatchMapping to your mapper to make it compatible.\n", { category: nil }).once

      specification = Specification.new(
        SpecificationReader.new(repository, mapper)
      )
      specification.to_a
      expect(mapper.invoked_map_records_to_events).to_not eq(true)
    end
  end
end
