require 'spec_helper'

module RubyEventStore
  RSpec.describe Specification do
    let(:specification) { Specification.new(InMemoryRepository.new) }

    specify { expect(specification.each).to be_kind_of(Enumerator) }

    specify { expect(specification).to have_result(:direction, :forward) }

    specify { expect(specification).to have_result(:start, :head) }

    specify { expect(specification).to have_result(:count, Specification::NO_LIMIT) }

    specify { expect(specification).to have_result(:stream, Stream.new(GLOBAL_STREAM)) }

    specify { expect{specification.limit(nil) }.to raise_error(InvalidPageSize) }

    specify { expect{specification.limit(0)}.to raise_error(InvalidPageSize) }

    specify { expect(specification.limit(1)).to have_result(:count, 1) }

    specify { expect(specification.forward).to have_result(:direction, :forward) }

    specify { expect(specification.backward).to have_result(:direction, :backward) }

    specify { expect(specification.backward.forward).to have_result(:direction, :forward) }

    specify { expect{specification.stream(nil)}.to raise_error(IncorrectStreamData) }

    specify { expect{specification.stream('')}.to raise_error(IncorrectStreamData) }

    specify { expect(specification.stream('stream')).to have_result(:stream, Stream.new('stream')) }

    specify { expect(specification.stream('all')).to have_result(:stream_name, GLOBAL_STREAM) }

    specify { expect(specification.from(:head)).to have_result(:start, :head) }

    specify { expect{specification.from(nil)}.to raise_error(InvalidPageStart) }

    specify { expect{specification.from('')}.to raise_error(InvalidPageStart) }

    specify { expect{specification.from(:dummy)}.to raise_error(InvalidPageStart) }

    specify do
      expect{specification.from('567ef3dd-dd28-4e05-9734-9353cd8653df')}
        .to(raise_error(EventNotFound, /567ef3dd-dd28-4e05-9734-9353cd8653df/))
    end

    specify do
      repository = InMemoryRepository.new
      test_event = TestEvent.new(event_id: '567ef3dd-dd28-4e05-9734-9353cd8653df')
      specification = Specification.new(repository)
      repository.append_to_stream([test_event], Stream.new("fancy_stream"), ExpectedVersion.new(-1))

      expect(specification.from('567ef3dd-dd28-4e05-9734-9353cd8653df'))
        .to(have_result(:start, '567ef3dd-dd28-4e05-9734-9353cd8653df'))
    end

    RSpec::Matchers.define :have_result do |attribute, expected|
      match do |specification|
        @actual = specification.result.public_send(attribute)
        values_match?(expected, @actual)
      end
    end
  end
end
