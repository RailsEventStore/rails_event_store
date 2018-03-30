require 'spec_helper'

module RubyEventStore
  RSpec.describe Specification do
    let(:specification) { Specification.new(InMemoryRepository.new) }

    specify { expect(specification.direction).to eq(:forward) }
    specify { expect(specification.start).to eq(:head) }
    specify { expect(specification.count).to eq(Specification::NO_LIMIT) }
    specify { expect{specification.limit(nil).count}.to raise_error(InvalidPageSize) }
    specify { expect(specification.limit(5).count).to eq(5) }
    specify { expect{specification.limit(0).count}.to raise_error(InvalidPageSize) }
    specify { expect(specification.stream_name).to eq(GLOBAL_STREAM) }
    specify { expect(specification.forward.direction).to eq(:forward) }
    specify { expect(specification.backward.direction).to eq(:backward) }
    specify { expect(specification.backward.forward.direction).to eq(:forward) }
    specify { expect{specification.stream(nil)}.to raise_error(IncorrectStreamData) }
    specify { expect{specification.stream('')}.to raise_error(IncorrectStreamData) }
    specify { expect(specification.stream('stream').stream_name).to eq('stream') }
    specify { expect(specification.each).to be_kind_of(Enumerator) }
    specify { expect(specification.from(:head).start).to eq(:head) }
    specify { expect{specification.from(nil)}.to raise_error(InvalidPageStart) }
    specify { expect{specification.from('')}.to raise_error(InvalidPageStart) }
    specify { expect{specification.from(:dummy)}.to raise_error(InvalidPageStart) }
    specify do
      repository = InMemoryRepository.new
      repository.append_to_stream([TestEvent.new(event_id: '567ef3dd-dd28-4e05-9734-9353cd8653df')], Stream.new("fancy_stream"), ExpectedVersion.new(-1))
      specification = Specification.new(repository)
      expect(specification.from('567ef3dd-dd28-4e05-9734-9353cd8653df').start).to eq('567ef3dd-dd28-4e05-9734-9353cd8653df')
    end
  end
end
