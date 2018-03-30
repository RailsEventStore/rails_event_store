require 'spec_helper'

module RubyEventStore
  RSpec.describe Specification do
    let(:specification) { Specification.new(InMemoryRepository.new) }

    specify { expect(specification.direction).to eq(:forward) }
    specify { expect(specification.start).to eq(:head) }
    specify { expect(specification.count).to be_nil }
    specify { expect(specification.stream_name).to eq(GLOBAL_STREAM) }
    specify { expect(specification.forward.direction).to eq(:forward) }
    specify { expect(specification.backward.direction).to eq(:backward) }
    specify { expect(specification.backward.forward.direction).to eq(:forward) }
    specify { expect(specification.from(:head).start).to eq(:head) }
    specify { expect(specification.from('567ef3dd-dd28-4e05-9734-9353cd8653df').start).to eq('567ef3dd-dd28-4e05-9734-9353cd8653df') }
    specify { expect{specification.stream(nil)}.to raise_error(IncorrectStreamData) }
    specify { expect{specification.stream('')}.to raise_error(IncorrectStreamData) }
    specify { expect(specification.stream('stream').stream_name).to eq('stream') }
    specify { expect(specification.each).to be_kind_of(Enumerator) }
  end
end
