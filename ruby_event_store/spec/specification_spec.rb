require 'spec_helper'

module RubyEventStore
  RSpec.describe Specification do
    let(:specification) { Specification.new(InMemoryRepository.new) }

    specify { expect(specification.each).to be_kind_of(Enumerator) }

    specify { expect(specification).to match_result({ direction: :forward }) }

    specify { expect(specification).to match_result({ start: :head }) }

    specify { expect(specification).to match_result({ count: Specification::NO_LIMIT }) }

    specify { expect(specification).to match_result({ stream_name: GLOBAL_STREAM }) }

    specify { expect{specification.limit(nil) }.to raise_error(InvalidPageSize) }

    specify { expect{specification.limit(0)}.to raise_error(InvalidPageSize) }

    specify { expect(specification.limit(1)).to match_result({ count: 1 }) }

    specify { expect(specification.forward).to match_result({ direction: :forward }) }

    specify { expect(specification.backward).to match_result({ direction: :backward }) }

    specify { expect(specification.backward.forward).to match_result({ direction: :forward }) }

    specify { expect{specification.stream(nil)}.to raise_error(IncorrectStreamData) }

    specify { expect{specification.stream('')}.to raise_error(IncorrectStreamData) }

    specify { expect(specification.stream('stream')).to match_result({ stream_name: 'stream' }) }

    specify { expect(specification.stream('all')).to match_result({ stream_name: 'all' }) }

    specify { expect(specification.stream(GLOBAL_STREAM)).to match_result({ stream_name: GLOBAL_STREAM }) }

    specify { expect(specification.from(:head)).to match_result({ start: :head }) }

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
        .to(match_result({ start: '567ef3dd-dd28-4e05-9734-9353cd8653df' }))
    end

    specify { expect(specification.stream('all')).to match_result({ global_stream?: false }) }

    specify { expect(specification.stream('nope')).to match_result({ global_stream?: false }) }

    specify { expect(specification.stream(GLOBAL_STREAM)).to match_result({ global_stream?: true }) }

    specify { expect(specification).to match_result({ global_stream?: true }) }

    specify { expect(specification).to match_result({ limit?: false }) }

    specify { expect(specification.limit(100)).to match_result({ limit?: true }) }

    specify { expect(specification).to match_result({ forward?: true }) }

    specify { expect(specification).to match_result({ backward?: false }) }

    specify { expect(specification.forward).to match_result({ forward?: true, backward?: false }) }

    specify { expect(specification.backward).to match_result({ forward?: false, backward?: true }) }

    specify { expect(specification).to match_result({ head?: true }) }

    specify { expect(specification.from(:head)).to match_result({ head?: true }) }

    specify do
      repository = InMemoryRepository.new
      test_event = TestEvent.new(event_id: '567ef3dd-dd28-4e05-9734-9353cd8653df')
      specification = Specification.new(repository)
      repository.append_to_stream([test_event], Stream.new("fancy_stream"), ExpectedVersion.new(-1))

      expect(specification.from('567ef3dd-dd28-4e05-9734-9353cd8653df')).to match_result({ head?: false })
    end
    
    RSpec::Matchers.define :match_result do |expected_hash|
      match do |specification|
        @actual = expected_hash.keys.reduce({}) do |memo, attribute|
          memo[attribute] = specification.result.public_send(attribute)
          memo
        end
        values_match?(expected_hash, @actual)
      end
      diffable
    end
  end
end
