require 'spec_helper'

module RubyEventStore
  RSpec.describe Specification do
    specify { expect(specification.each).to be_kind_of(Enumerator) }

    specify { expect(specification.forward?).to eq(true) }
    specify { expect(specification.backward?).to eq(false) }
    specify { expect(specification.forward.forward?).to eq(true) }
    specify { expect(specification.forward.backward?).to eq(false) }
    specify { expect(specification.backward.forward?).to eq(false) }
    specify { expect(specification.backward.backward?).to eq(true) }

    specify { expect(specification.limit?).to eq(false) }
    specify { expect(specification.count).to eq(Float::INFINITY) }

    specify { expect(specification.all?).to eq(true) }
    specify { expect(specification.batched?).to eq(false) }
    specify { expect(specification.first?).to eq(false) }
    specify { expect(specification.last?).to eq(false) }

    specify { expect{specification.limit(nil) }.to raise_error(InvalidPageSize) }
    specify { expect{specification.limit(0)}.to raise_error(InvalidPageSize) }
    specify { expect(specification.limit(1).count).to eq(1) }
    specify { expect(specification.limit?).to eq(false) }
    specify { expect(specification.limit(100).limit?).to eq(true) }

    specify { expect(specification.stream_name).to eq(GLOBAL_STREAM) }
    specify { expect(specification.global_stream?).to eq(true) }
    specify { expect{specification.stream(nil)}.to raise_error(IncorrectStreamData) }
    specify { expect{specification.stream('')}.to raise_error(IncorrectStreamData) }
    specify { expect(specification.stream('stream').stream_name).to eq('stream') }
    specify { expect(specification.stream('nope').global_stream?).to eq(false) }
    specify { expect(specification.stream('all').stream_name).to eq('all') }
    specify { expect(specification.stream('all').global_stream?).to eq(false) }
    specify { expect(specification.stream(GLOBAL_STREAM).stream_name).to eq( GLOBAL_STREAM) }
    specify { expect(specification.stream(GLOBAL_STREAM).global_stream?).to eq(true) }

    specify { expect(specification.head?).to eq(true) }
    specify { expect(specification.from(:head).start).to eq(:head) }
    specify { expect{specification.from(nil)}.to raise_error(InvalidPageStart) }
    specify { expect{specification.from('')}.to raise_error(InvalidPageStart) }
    specify { expect{specification.from(:dummy)}.to raise_error(InvalidPageStart) }
    specify { expect{ specification.from(none_such_id) }.to raise_error(EventNotFound, /#{none_such_id}/) }
    specify { expect(specification.from(:head).head?).to eq(true) }

    specify do
      with_event_of_id(event_id) do
        expect(specification.from(event_id).start).to eq(event_id)
        expect(specification.from(event_id).head?).to eq(false)
        expect(specification.from(:head).from(event_id).start).to eq(event_id)
      end
    end

    specify do
      with_event_of_id(event_id) do
        spec = specification.backward.stream(stream_name).limit(10).from(event_id)
        expect(spec.stream_name).to eq(stream_name)
        expect(spec.count).to eq(10)
        expect(spec.start).to eq(event_id)
        expect(spec.backward?).to eq(true)
      end
    end

    specify do
      with_event_of_id(event_id) do
        specs = [
          specification.forward,
          specification.backward,
          specification.in_batches,
          specification.read_first,
          specification.read_last,
          specification.limit(10),
          specification.from(event_id),
          specification.stream(stream_name),
        ]
        expect(specs.map{|s| s.send(:repository)}.uniq).to eq([repository])
        expect(specs.map{|s| s.send(:mapper)}.uniq).to eq([mapper])
      end
    end

    specify 'immutable specification' do
      with_event_of_id(event_id) do
        spec = backward_specifcation = specification.backward
        expect(spec.object_id).not_to eq(specification.object_id)
        expect(spec.backward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.all?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.from(event_id)
        expect(spec.object_id).not_to eq(specification.object_id)
        expect(spec.forward?).to eq(true)
        expect(spec.start).to eq(event_id)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.all?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.limit(10)
        expect(spec.object_id).not_to eq(specification.object_id)
        expect(spec.forward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.count).to eq(10)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.all?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.stream(stream_name)
        expect(spec.object_id).not_to eq(specification.object_id)
        expect(spec.forward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(stream_name)
        expect(spec.all?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.in_batches
        expect(spec.object_id).not_to eq(specification.object_id)
        expect(spec.forward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.batched?).to eq(true)
        expect(spec.batch_size).to eq(100)

        spec = specification
        expect(spec.forward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.all?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = backward_specifcation.forward
        expect(spec.object_id).not_to eq(backward_specifcation.object_id)
        expect(spec.forward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.all?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = backward_specifcation
        expect(spec.object_id).not_to eq(specification.object_id)
        expect(spec.backward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.all?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.read_first
        expect(spec.object_id).not_to eq(specification.object_id)
        expect(spec.forward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.first?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification
        expect(spec.forward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.all?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.read_last
        expect(spec.object_id).not_to eq(specification.object_id)
        expect(spec.forward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.last?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification
        expect(spec.forward?).to eq(true)
        expect(spec.start).to eq(:head)
        expect(spec.limit?).to eq(false)
        expect(spec.stream_name).to eq(GLOBAL_STREAM)
        expect(spec.all?).to eq(true)
        expect(spec.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)
      end
    end

    specify do
      with_event_of_id(event_id) do
        expect(specification.each.to_a).to eq([test_event])
      end
    end

    specify do
      with_event_of_id(event_id) do
        expect(specification.stream(stream_name).each.to_a).to eq([test_event])
      end
    end

    specify do
      with_event_of_id(event_id) do
        expect(specification.limit(1).each.to_a).to eq([test_event])
      end
    end

    specify do
      with_event_of_id(event_id) do
        expect(specification.backward.each.to_a).to eq([test_event])
      end
    end

    specify do
      with_event_of_id(event_id) do
        expect(specification.forward.each.to_a).to eq([test_event])
      end
    end

    specify do
      records = [test_record, test_record]
      repository.append_to_stream(records, Stream.new("Dummy"), ExpectedVersion.none)

      expect(specification.from(records[0].event_id).each.to_a).to eq([TestEvent.new(event_id: records[1].event_id)])
    end

    specify do
      batch_size = 100
      records = (batch_size * 10).times.map { test_record }
      repository.append_to_stream(records, Stream.new("batch"), ExpectedVersion.none)

      expect(specification.stream("batch").in_batches.each_batch.to_a.size).to eq(10)
    end

    specify do
      batch_size = 100
      records = (batch_size * 10).times.map { test_record }
      repository.append_to_stream(records, Stream.new("batch"), ExpectedVersion.none)

      expect(specification.stream("batch").in_batches.each.to_a.size).to eq(1000)
    end

    specify { expect(specification.in_batches.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE) }

    specify { expect(specification.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE) }

    specify { expect(specification.in_batches(1000).batch_size).to eq(1000) }

    specify do
      with_event_of_id(event_id) do
        expect(specification.in_batches.each_batch.to_a).to eq([[test_event]])
      end
    end

    specify do
      with_event_of_id(event_id) do
        expect(specification.in_batches.each.to_a).to eq([test_event])
      end
    end

    specify do
      with_event_of_id(event_id) do
        expect { |b| specification.in_batches.each_batch(&b) }.to yield_successive_args([test_event])
      end
    end

    specify do
      with_event_of_id(event_id) do
        expect { |b| specification.in_batches.each(&b) }.to yield_successive_args(test_event)
      end
    end

    specify do
      with_event_of_id(event_id) do
        expect { |b| specification.each(&b) }.to yield_successive_args(test_event)
      end
    end

    specify do
      expect(specification.in_batches_of).to       eq(specification.in_batches)
      expect(specification.in_batches_of(1000)).to eq(specification.in_batches(1000))
    end

    specify do
      records = 200.times.map { test_record }
      repository.append_to_stream(records, Stream.new("whatever"), ExpectedVersion.none)

      expect(specification.each_batch.to_a).to     eq(specification.in_batches.each_batch.to_a)
      expect(specification.each_batch.to_a).not_to eq(specification.in_batches(1000).each_batch.to_a)
    end

    specify do
      expect(specification.first).to be_nil
      expect(specification.last).to be_nil

      records = 5.times.map { test_record }
      repository.append_to_stream(records, Stream.new("Dummy"), ExpectedVersion.none)

      expect(specification.stream("Another").first).to be_nil
      expect(specification.stream("Another").last).to be_nil

      expect(specification.first).to eq(TestEvent.new(event_id: records[0].event_id))
      expect(specification.last).to eq(TestEvent.new(event_id: records[4].event_id))

      expect(specification.from(records[2].event_id).first).to eq(TestEvent.new(event_id: records[3].event_id))
      expect(specification.from(records[2].event_id).last).to eq(TestEvent.new(event_id: records[4].event_id))

      expect(specification.from(records[2].event_id).backward.first).to eq(TestEvent.new(event_id: records[1].event_id))
      expect(specification.from(records[2].event_id).backward.last).to eq(TestEvent.new(event_id: records[0].event_id))

      expect(specification.from(records[4].event_id).first).to be_nil
      expect(specification.from(records[4].event_id).last).to be_nil

      expect(specification.from(records[0].event_id).backward.first).to be_nil
      expect(specification.from(records[0].event_id).backward.last).to be_nil
    end

    specify do
      repository.append_to_stream([test_record], Stream.new("Dummy"), ExpectedVersion.none)

      expect(specification.batched?).to eq(false)
      expect(specification.first?).to eq(false)
      expect(specification.last?).to eq(false)

      expect(specification.read_first.batched?).to eq(false)
      expect(specification.read_first.first?).to eq(true)
      expect(specification.read_first.last?).to eq(false)

      expect(specification.read_last.batched?).to eq(false)
      expect(specification.read_last.first?).to eq(false)
      expect(specification.read_last.last?).to eq(true)

      expect(specification.in_batches.batched?).to eq(true)
      expect(specification.in_batches.first?).to eq(false)
      expect(specification.in_batches.last?).to eq(false)
    end

    let(:repository)    { InMemoryRepository.new }
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
