require 'spec_helper'

module RubyEventStore
  RSpec.describe Specification do
    specify { expect(specification.each).to be_kind_of(Enumerator) }

    specify { expect(specification.result.forward?).to eq(true) }
    specify { expect(specification.result.backward?).to eq(false) }
    specify { expect(specification.forward.result.forward?).to eq(true) }
    specify { expect(specification.forward.result.backward?).to eq(false) }
    specify { expect(specification.backward.result.forward?).to eq(false) }
    specify { expect(specification.backward.result.backward?).to eq(true) }

    specify { expect(specification.result.limit?).to eq(false) }
    specify { expect(specification.result.limit).to eq(Float::INFINITY) }

    specify { expect(specification.result.all?).to eq(true) }
    specify { expect(specification.result.batched?).to eq(false) }
    specify { expect(specification.result.first?).to eq(false) }
    specify { expect(specification.result.last?).to eq(false) }

    specify { expect{specification.limit(nil) }.to raise_error(InvalidPageSize) }
    specify { expect{specification.limit(0)}.to raise_error(InvalidPageSize) }
    specify { expect(specification.limit(1).result.limit).to eq(1) }
    specify { expect(specification.result.limit?).to eq(false) }
    specify { expect(specification.limit(100).result.limit?).to eq(true) }

    specify { expect(specification.result.stream.name).to eq(GLOBAL_STREAM) }
    specify { expect(specification.result.stream.global?).to eq(true) }
    specify { expect{specification.stream(nil)}.to raise_error(IncorrectStreamData) }
    specify { expect{specification.stream('')}.to raise_error(IncorrectStreamData) }
    specify { expect(specification.stream('stream').result.stream.name).to eq('stream') }
    specify { expect(specification.stream('nope').result.stream.global?).to eq(false) }
    specify { expect(specification.stream('all').result.stream.name).to eq('all') }
    specify { expect(specification.stream('all').result.stream.global?).to eq(false) }
    specify { expect(specification.stream(GLOBAL_STREAM).result.stream.name).to eq( GLOBAL_STREAM) }
    specify { expect(specification.stream(GLOBAL_STREAM).result.stream.global?).to eq(true) }

    specify { expect(specification.result.head?).to eq(true) }
    specify { expect(specification.from(:head).result.start).to eq(:head) }
    specify { expect{specification.from(nil)}.to raise_error(InvalidPageStart) }
    specify { expect{specification.from('')}.to raise_error(InvalidPageStart) }
    specify { expect{specification.from(:dummy)}.to raise_error(InvalidPageStart) }
    specify { expect{specification.from(none_such_id) }.to raise_error(EventNotFound, /#{none_such_id}/) }
    specify { expect(specification.from(:head).result.head?).to eq(true) }

    specify { expect(specification.result.with_ids).to be_nil }
    specify { expect(specification.with_id([event_id]).result.with_ids).to eq([event_id]) }
    specify { expect(specification.result.with_ids?).to eq(false) }
    specify { expect(specification.with_id([event_id]).result.with_ids?).to eq(true) }

    specify { expect(specification.result.with_types).to be_nil }
    specify { expect(specification.of_type([TestEvent]).result.with_types).to eq([TestEvent]) }
    specify { expect(specification.result.with_types?).to eq(false) }
    specify { expect(specification.of_type([TestEvent]).result.with_types?).to eq(true) }

    specify do
      with_event_of_id(event_id) do
        expect(specification.from(event_id).result.start).to eq(event_id)
        expect(specification.from(event_id).result.head?).to eq(false)
        expect(specification.from(:head).from(event_id).result.start).to eq(event_id)
      end
    end

    specify do
      with_event_of_id(event_id) do
        spec = specification.backward.stream(stream_name).limit(10).from(event_id)
        expect(spec.result.stream.name).to eq(stream_name)
        expect(spec.result.stream.global?).to eq(false)
        expect(spec.result.limit).to eq(10)
        expect(spec.result.start).to eq(event_id)
        expect(spec.result.backward?).to eq(true)
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
          specification.with_id([event_id]),
          specification.of_type([TestEvent]),
        ]
        expect(specs.map{|s| s.send(:reader)}.uniq).to eq([reader])
      end
    end

    specify { expect(specification.in_batches(3).from(:head).result.batch_size).to eq(3) }
    specify { expect(specification.in_batches(3).in_batches.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE) }
    specify { expect(specification.in_batches(3).forward.result.batch_size).to eq(3) }
    specify { expect(specification.in_batches(3).backward.result.batch_size).to eq(3) }
    specify { expect(specification.in_batches(3).read_first.result.batch_size).to eq(3) }
    specify { expect(specification.in_batches(3).read_last.result.batch_size).to eq(3) }
    specify { expect(specification.in_batches(3).limit(1).result.batch_size).to eq(3) }
    specify { expect(specification.in_batches(3).stream('dummy').result.batch_size).to eq(3) }

    specify do
      with_event_of_id(event_id) do
        expect(specification.from(event_id).stream('dummy').result.start).to eq(event_id)
        expect(specification.from(event_id).limit(1).result.start).to eq(event_id)
        expect(specification.from(event_id).read_first.result.start).to eq(event_id)
        expect(specification.from(event_id).read_last.result.start).to eq(event_id)
        expect(specification.from(event_id).forward.result.start).to eq(event_id)
        expect(specification.from(event_id).backward.result.start).to eq(event_id)
        expect(specification.read_first.from(event_id).result.first?).to eq(true)
      end
    end

    specify { expect(specification.limit(3).stream('dummy').result.limit).to eq(3) }
    specify { expect(specification.limit(3).read_first.result.limit).to eq(3) }
    specify { expect(specification.limit(3).read_last.result.limit).to eq(3) }
    specify { expect(specification.limit(3).forward.result.limit).to eq(3) }
    specify { expect(specification.limit(3).backward.result.limit).to eq(3) }
    specify { expect(specification.limit(3).in_batches.result.limit).to eq(3) }

    specify { expect(specification.read_first.stream('dummy').result.first?).to eq(true) }
    specify { expect(specification.stream('dummy').forward.result.stream.name).to eq('dummy') }
    specify { expect(specification.stream('dummy').forward.result.stream.global?).to eq(false) }
    specify { expect(specification.stream('dummy').backward.result.stream.name).to eq('dummy') }
    specify { expect(specification.stream('dummy').backward.result.stream.global?).to eq(false) }
    specify { expect(specification.stream('dummy').in_batches.result.stream.name).to eq('dummy') }
    specify { expect(specification.stream('dummy').in_batches.result.stream.global?).to eq(false) }

    specify { expect(specification.read_first.limit(1).result.first?).to eq(true) }
    specify { expect(specification.read_first.forward.result.first?).to eq(true) }
    specify { expect(specification.read_first.backward.result.first?).to eq(true) }
    specify { expect(specification.backward.in_batches.result.backward?).to eq(true) }

    specify 'immutable specification' do
      with_event_of_id(event_id) do
        spec = backward_specifcation = specification.backward
        expect(spec.result.object_id).not_to eq(specification.result.object_id)
        expect(spec.result.backward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.all?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.from(event_id)
        expect(spec.result.object_id).not_to eq(specification.result.object_id)
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(event_id)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.all?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.limit(10)
        expect(spec.result.object_id).not_to eq(specification.result.object_id)
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit).to eq(10)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.all?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.stream(stream_name)
        expect(spec.result.object_id).not_to eq(specification.result.object_id)
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(stream_name)
        expect(spec.result.stream.global?).to eq(false)
        expect(spec.result.all?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.in_batches
        expect(spec.result.object_id).not_to eq(specification.result.object_id)
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.batched?).to eq(true)
        expect(spec.result.batch_size).to eq(100)

        spec = specification
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.all?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = backward_specifcation.forward
        expect(spec.result.object_id).not_to eq(backward_specifcation.result.object_id)
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.all?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = backward_specifcation
        expect(spec.result.object_id).not_to eq(specification.result.object_id)
        expect(spec.result.backward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.all?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.read_first
        expect(spec.result.object_id).not_to eq(specification.result.object_id)
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.first?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.all?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.read_last
        expect(spec.result.object_id).not_to eq(specification.result.object_id)
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.last?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)

        spec = specification.with_id([event_id])
        expect(spec.result.object_id).not_to eq(specification.result.object_id)
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)
        expect(spec.result.with_ids).to eq([event_id])

        spec = specification.of_type([TestEvent])
        expect(spec.result.object_id).not_to eq(specification.result.object_id)
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)
        expect(spec.result.with_types).to eq([TestEvent])

        spec = specification
        expect(spec.result.forward?).to eq(true)
        expect(spec.result.start).to eq(:head)
        expect(spec.result.limit?).to eq(false)
        expect(spec.result.stream.name).to eq(GLOBAL_STREAM)
        expect(spec.result.stream.global?).to eq(true)
        expect(spec.result.all?).to eq(true)
        expect(spec.result.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE)
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

    #specify { expect(specification.in_batches.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE) }

    #specify { expect(specification.batch_size).to eq(Specification::DEFAULT_BATCH_SIZE) }

    #specify { expect(specification.in_batches(1000).batch_size).to eq(1000) }

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
      expect(specification.in_batches_of.result).to       eq(specification.in_batches.result)
      expect(specification.in_batches_of(1000).result).to eq(specification.in_batches(1000).result)
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
      expect(specification.event(event_id)).to be_nil
      expect{specification.event!(event_id)}.to raise_error(EventNotFound, "Event not found: #{event_id}")

      records = 5.times.map { test_record }
      repository.append_to_stream(records, Stream.new("Dummy"), ExpectedVersion.none)

      expect(specification.event(records[0].event_id)).to eq(TestEvent.new(event_id: records[0].event_id))
      expect(specification.event(records[3].event_id)).to eq(TestEvent.new(event_id: records[3].event_id))

      expect(specification.event!(records[0].event_id)).to eq(TestEvent.new(event_id: records[0].event_id))
      expect(specification.event!(records[3].event_id)).to eq(TestEvent.new(event_id: records[3].event_id))

      expect(specification.events([0,2,4].map{|i| records[i].event_id}).to_a).to eq(
        [0,2,4].map{|i| TestEvent.new(event_id: records[i].event_id)})
      expect(specification.events([records[0].event_id, SecureRandom.uuid]).to_a).to eq(
        [TestEvent.new(event_id: records[0].event_id)])
    end

    specify do
      repository.append_to_stream([test_record], Stream.new("Dummy"), ExpectedVersion.none)

      expect(specification.result.batched?).to eq(false)
      expect(specification.result.first?).to eq(false)
      expect(specification.result.last?).to eq(false)

      expect(specification.read_first.result.batched?).to eq(false)
      expect(specification.read_first.result.first?).to eq(true)
      expect(specification.read_first.result.last?).to eq(false)

      expect(specification.read_last.result.batched?).to eq(false)
      expect(specification.read_last.result.first?).to eq(false)
      expect(specification.read_last.result.last?).to eq(true)

      expect(specification.in_batches.result.batched?).to eq(true)
      expect(specification.in_batches.result.first?).to eq(false)
      expect(specification.in_batches.result.last?).to eq(false)
    end

    specify{ expect(specification.result.frozen?).to eq(true) }
    specify{ expect(specification.backward.result.frozen?).to eq(true) }

    specify "#hash" do
      expect(specification.result.hash).to eq(specification.forward.result.hash)
      expect(specification.forward.result.hash).not_to eq(specification.backward.result.hash)

      expect(specification.read_first.result.hash).to eq(specification.read_first.result.hash)
      expect(specification.read_last.result.hash).to eq(specification.read_last.result.hash)
      expect(specification.read_first.result.hash).not_to eq(specification.read_last.result.hash)

      expect(specification.result.hash).not_to eq(specification.limit(10).result.hash)
      expect(specification.in_batches.result.hash).to eq(specification.in_batches(Specification::DEFAULT_BATCH_SIZE).result.hash)
      expect(specification.in_batches.result.hash).not_to eq(specification.in_batches(10).result.hash)
      expect(specification.result.hash).to eq(specification.stream(GLOBAL_STREAM).result.hash)
      expect(specification.result.hash).not_to eq(specification.stream('dummy').result.hash)

      expect(specification.with_id(event_id).result.hash).to eq(specification.with_id(event_id).result.hash)
      expect(specification.with_id(event_id).result.hash).not_to eq(specification.with_id(SecureRandom.uuid).result.hash)

      expect(specification.of_type([TestEvent]).result.hash).to eq(specification.of_type([TestEvent]).result.hash)
      expect(specification.of_type([TestEvent]).result.hash).not_to eq(specification.of_type([OrderCreated]).result.hash)

      with_event_of_id(event_id) do
        expect(specification.result.hash).to eq(specification.from(:head).result.hash)
        expect(specification.from(event_id).result.hash).not_to eq(specification.from(:head).result.hash)
      end

      expect(specification.result.hash).not_to eq([
          SpecificationResult,
          :forward,
          :head,
          Float::INFINITY,
          Stream.new(GLOBAL_STREAM),
          :all,
          Specification::DEFAULT_BATCH_SIZE,
          nil,
          nil,
        ].hash)

      expect(Class.new(SpecificationResult).new.hash).not_to eq(specification.result.hash)
    end

    specify "#eql?" do
      expect(specification.result).to eq(specification.forward.result)
      expect(specification.forward.result).not_to eq(specification.backward.result)

      expect(specification.read_first.result).to eq(specification.read_first.result)
      expect(specification.read_last.result).to eq(specification.read_last.result)
      expect(specification.read_first.result).not_to eq(specification.read_last.result)

      expect(specification.result).not_to eq(specification.limit(10).result)
      expect(specification.in_batches.result).to eq(specification.in_batches(Specification::DEFAULT_BATCH_SIZE).result)
      expect(specification.in_batches.result).not_to eq(specification.in_batches(10).result)
      expect(specification.result).to eq(specification.stream(GLOBAL_STREAM).result)
      expect(specification.result).not_to eq(specification.stream('dummy').result)

      expect(specification.with_id(event_id).result).to eq(specification.with_id(event_id).result)
      expect(specification.with_id(event_id).result).not_to eq(specification.with_id(SecureRandom.uuid).result)

      with_event_of_id(event_id) do
        expect(specification.result).to eq(specification.from(:head).result)
        expect(specification.from(event_id).result).not_to eq(specification.from(:head).result)
      end
    end

    specify "#dup" do
      expect(specification.result.dup).to eq(specification.result)
      specification.result.dup do |result|
        expect(result.object_id).not_to eq(specification.result.object_id)
      end
    end

    let(:repository)    { InMemoryRepository.new }
    let(:mapper)        { Mappers::Default.new }
    let(:reader)        { SpecificationReader.new(repository, mapper) }
    let(:specification) { Specification.new(reader) }
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
