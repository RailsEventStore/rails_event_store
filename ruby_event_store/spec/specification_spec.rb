require 'spec_helper'

module RubyEventStore
  RSpec.describe Specification do
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

    specify { expect{ specification.from(none_such_id) }.to raise_error(EventNotFound, /#{none_such_id}/) }

    specify { expect(specification.from(event_id)).to match_result({ start: event_id }) }

    specify { expect(specification.from(:head).from(event_id)).to match_result({ start: event_id }) }

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

    specify { expect(specification.from(event_id)).to match_result({ head?: false }) }

    specify do
      expect(specification.limit(10).from(event_id)).to match_result({
        count: 10,
        start: event_id
      })
    end

    specify do
      expect(specification.stream(stream_name).from(event_id)).to match_result({
        stream_name: stream_name,
        start: event_id
      })
    end

    specify do
      expect(specification.stream(stream_name).from(event_id)).to match_result({
        stream_name: stream_name,
        start: event_id
      })
    end

    specify do
      expect(specification.backward.from(event_id)).to match_result({
        direction: :backward,
        start: event_id
      })
    end

    specify do
      expect(specification.stream(stream_name).forward.from(event_id)).to match_result({
        direction: :forward,
        stream_name: stream_name,
        start: event_id
      })
    end

    specify 'immutable specification' do
      expect(backward_specifcation = specification.backward).to match_result({
        direction: :backward,
        start: :head,
        count: Specification::NO_LIMIT,
        stream_name: GLOBAL_STREAM,
        batch_size: Specification::NO_BATCH
      })
      expect(specification.from(event_id)).to match_result({
        direction: :forward,
        start: event_id,
        count: Specification::NO_LIMIT,
        stream_name: GLOBAL_STREAM,
        batch_size: Specification::NO_BATCH
      })
      expect(specification.limit(10)).to match_result({
        direction: :forward,
        start: :head,
        count: 10,
        stream_name: GLOBAL_STREAM,
        batch_size: Specification::NO_BATCH
      })
      expect(specification.stream(stream_name)).to match_result({
        direction: :forward,
        start: :head,
        count: Specification::NO_LIMIT,
        stream_name: stream_name,
        batch_size: Specification::NO_BATCH
      })
      expect(specification.in_batches).to match_result({
        direction: :forward,
        start: :head,
        count: Specification::NO_LIMIT,
        stream_name: GLOBAL_STREAM,
        batch_size: 100
      })
      expect(specification).to match_result({
        direction: :forward,
        start: :head,
        count: Specification::NO_LIMIT,
        stream_name: GLOBAL_STREAM,
        batch_size: Specification::NO_BATCH
      })
      expect(backward_specifcation.forward).to match_result({
        direction: :forward,
        start: :head,
        count: Specification::NO_LIMIT,
        stream_name: GLOBAL_STREAM,
        batch_size: Specification::NO_BATCH
      })
      expect(backward_specifcation).to match_result({
        direction: :backward,
        start: :head,
        count: Specification::NO_LIMIT,
        stream_name: GLOBAL_STREAM,
        batch_size: Specification::NO_BATCH
      })
    end

    specify { expect(specification.each.to_a).to eq([test_event]) }

    specify { expect(specification.stream(stream_name).each.to_a).to eq([test_event]) }

    specify { expect(specification.limit(1).each.to_a).to eq([test_event]) }

    specify { expect(specification.backward.each.to_a).to eq([test_event]) }

    specify { expect(specification.forward.each.to_a).to eq([test_event]) }

    specify { expect(specification.from(event_id).each.to_a).to eq([test_event]) }

    specify do
      batch_size = 100
      events = (batch_size * 10).times.map { test_record }
      repository.append_to_stream(events, Stream.new("batch"), ExpectedVersion.none)
      expect(specification.stream("batch").in_batches.each.to_a.size).to eq(10)
    end

    specify { expect(specification.in_batches).to match_result(batch_size: 100) }

    specify { expect(specification).to match_result(batch_size: Specification::NO_BATCH) }

    specify { expect(specification.in_batches(1000)).to match_result(batch_size: 1000) }

    specify do
      expect(specification.in_batches.each.to_a).to eq([[test_event]])
    end

    specify { expect { |b| specification.in_batches.each(&b) }.to yield_control }
    specify { expect { |b| specification.each(&b) }.to yield_control }

    let(:repository)    { InMemoryRepository.new }
    let(:mapper)        { Mappers::NullMapper.new }
    let(:mapper)        { Mappers::Default.new }
    let(:specification) { Specification.new(repository, mapper) }
    let(:event_id)      { SecureRandom.uuid }
    let(:none_such_id)  { SecureRandom.uuid }
    let(:stream_name)   { SecureRandom.hex }
    let(:test_event)    { TestEvent.new(event_id: event_id) }

    def test_record(event_id = SecureRandom.uuid)
        RubyEventStore::SerializedRecord.new(
        event_id: event_id,
        data: "{}",
        metadata: "{}",
        event_type: "TestEvent",
      )
    end

    around(:each) do |example|
      with_event_of_id(event_id) do
        example.call
      end
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

    def with_event_of_id(event_id, &block)
      repository.append_to_stream(
        [test_record(event_id)],
        Stream.new(stream_name),
        ExpectedVersion.none
      )
      block.call
    end
  end
end
