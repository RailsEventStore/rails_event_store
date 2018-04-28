RSpec.shared_examples :stream_entries_relation do |relation_class|
  subject(:relation) { container.relations[:stream_entries] }

  let(:env) { rom_helper.env }
  let(:container) { env.container }
  let(:rom_db) { container.gateways[:default] }

  around(:each) do |example|
    rom_helper.run_lifecycle { example.run }
  end

  it 'just created is empty' do
    expect(relation.to_a).to be_empty
  end

  specify '#insert verifies tuple is unique steam and event_id' do
    stream_entries = [
      {stream: 'stream', position: 0, event_id: id1 = SecureRandom.uuid},
      {stream: 'stream', position: 1, event_id: SecureRandom.uuid},
      {stream: 'stream', position: 2, event_id: SecureRandom.uuid}
    ]

    relation.command(:create).call(stream_entries)

    conflicting_event_id = {stream: 'stream', position: 3, event_id: id1}

    expect(relation.to_a.size).to eq(3)
    expect{relation.insert(conflicting_event_id)}.to raise_error do |err|
      expect(err).to be_a(RubyEventStore::ROM::TupleUniquenessError)
      expect(err.message).to eq(%[Uniquness violated for stream ("stream") and event_id (#{id1.inspect})])
    end

    conflicting_position = {stream: 'stream', position: 2, event_id: SecureRandom.uuid}

    expect{relation.insert(conflicting_position)}.to raise_error do |err|
      expect(err).to be_a(RubyEventStore::ROM::TupleUniquenessError)
      expect(err.message).to eq(%[Uniquness violated for stream ("stream") and position (2)])
    end
  end

  specify '#take ignores nil' do
    stream_entries = [
      {stream: 'stream', position: 0, event_id: id1 = SecureRandom.uuid},
      {stream: 'stream', position: 1, event_id: id2 = SecureRandom.uuid},
      {stream: 'stream', position: 2, event_id: id3 = SecureRandom.uuid}
    ]

    relation.command(:create).call(stream_entries)

    expect(relation.to_a.size).to eq(3)
    expect(relation.take(nil).to_a.size).to eq(3)
    expect(relation.take(nil).map { |e| e[:event_id] }).to eq([id1, id2, id3])
  end

  specify '#take returns specified number of tuples' do
    stream_entries = [
      {stream: 'stream', position: 0, event_id: id1 = SecureRandom.uuid},
      {stream: 'stream', position: 1, event_id: id2 = SecureRandom.uuid},
      {stream: 'stream', position: 2, event_id: SecureRandom.uuid}
    ]

    relation.command(:create).call(stream_entries)

    expect(relation.to_a.size).to eq(3)
    expect(relation.take(2).to_a.size).to eq(2)
    expect(relation.take(2).map { |e| e[:event_id] }).to eq([id1, id2])
  end

  specify '#by_stream returns tuples for the specified stream' do
    stream_entries = [
      {stream: 'stream', position: 0, event_id: SecureRandom.uuid},
      {stream: 'stream', position: 1, event_id: SecureRandom.uuid},
      {stream: 'stream2', position: 2, event_id: SecureRandom.uuid}
    ]

    relation.command(:create).call(stream_entries)

    expect(relation.to_a.size).to eq(3)
    expect(relation.by_stream(RubyEventStore::Stream.new('stream')).to_a.size).to eq(2)
  end

  specify '#by_stream_and_event_id returns a tuple for the specified stream and event_id' do
    stream = RubyEventStore::Stream.new('stream')
    stream2 = RubyEventStore::Stream.new('stream2')

    stream_entries = [
      {stream: stream.name, position: 0, event_id: id = SecureRandom.uuid},
      {stream: stream.name, position: 1, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 2, event_id: SecureRandom.uuid}
    ]

    relation.command(:create).call(stream_entries)

    expect(relation.to_a.size).to eq(3)
    expect(relation.by_stream_and_event_id(stream, id)[:event_id]).to eq(id)
    expect{relation.by_stream_and_event_id(stream2, id)}.to raise_error(ROM::TupleCountMismatchError)
  end

  specify '#max_position gets the largest position value' do
    stream = RubyEventStore::Stream.new('stream')
    stream2 = RubyEventStore::Stream.new('stream2')
    stream3 = RubyEventStore::Stream.new('stream3')

    stream_entries = [
      {stream: stream.name, position: 0, event_id: SecureRandom.uuid},
      {stream: stream.name, position: 2, event_id: id = SecureRandom.uuid},
      {stream: stream.name, position: 1, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 1, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 0, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 3, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 2, event_id: SecureRandom.uuid}
    ]

    relation.command(:create).call(stream_entries)

    expect(relation.to_a.size).to eq(7)
    expect(relation.max_position(stream)).not_to be(nil)
    expect(relation.max_position(stream)[:position]).to eq(2)
    expect(relation.max_position(stream)[:event_id]).to eq(id)
    expect(relation.max_position(stream3)).to eq(nil)
  end

  specify '#ordered gets the stream entries :forward' do
    stream = RubyEventStore::Stream.new('stream')
    stream2 = RubyEventStore::Stream.new('stream2')

    stream_entries = [
      {stream: stream.name, position: 0, event_id: SecureRandom.uuid},
      {stream: stream.name, position: 1, event_id: id1 = SecureRandom.uuid},
      {stream: stream.name, position: 2, event_id: id2 = SecureRandom.uuid},
      {stream: stream2.name, position: 0, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 1, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 2, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 3, event_id: SecureRandom.uuid}
    ]

    relation.command(:create).call(stream_entries)

    expect(relation.to_a.size).to eq(7)
    expect(relation.ordered(:forward, stream).to_a.size).to eq(3)
    expect(relation.ordered(:forward, stream).map { |e| e[:position] }).to eq([0, 1, 2])

    offset1 = relation.by_stream_and_event_id(stream, id1)[:id]
    offset2 = relation.by_stream_and_event_id(stream, id2)[:id]

    expect(relation.ordered(:forward, stream, offset1).map { |e| e[:position] }).to eq([2])
    expect(relation.ordered(:forward, stream, offset2).map { |e| e[:position] }).to eq([])
  end

  specify '#ordered gets the stream entries :backward' do
    stream = RubyEventStore::Stream.new('stream')
    stream2 = RubyEventStore::Stream.new('stream2')

    stream_entries = [
      {stream: stream.name, position: 0, event_id: id1 = SecureRandom.uuid},
      {stream: stream.name, position: 1, event_id: id2 = SecureRandom.uuid},
      {stream: stream.name, position: 2, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 0, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 1, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 2, event_id: SecureRandom.uuid},
      {stream: stream2.name, position: 3, event_id: SecureRandom.uuid}
    ]

    relation.command(:create).call(stream_entries)

    expect(relation.to_a.size).to eq(7)
    expect(relation.ordered(:backward, stream).to_a.size).to eq(3)
    expect(relation.ordered(:backward, stream).map { |e| e[:position] }).to eq([2, 1, 0])

    offset1 = relation.by_stream_and_event_id(stream, id1)[:id]
    offset2 = relation.by_stream_and_event_id(stream, id2)[:id]

    expect(relation.ordered(:backward, stream, offset1).map { |e| e[:position] }).to eq([])
    expect(relation.ordered(:backward, stream, offset2).map { |e| e[:position] }).to eq([0])
  end

  specify 'each method returns proper type' do
    stream = RubyEventStore::Stream.new('stream')
    stream_entries = [
      {stream: 'stream', position: 0, event_id: id1 = SecureRandom.uuid},
      {stream: 'stream', position: 1, event_id: id2 = SecureRandom.uuid},
      {stream: 'stream', position: 2, event_id: id3 = SecureRandom.uuid}
    ]

    relation.command(:create).call(stream_entries)

    expect(relation.take(1)).to be_a(RubyEventStore::ROM::Memory::Relations::StreamEntries)
    expect(relation.take(1).one).to be_a(::ROM::Struct)

    expect(relation.by_stream(stream)).to be_a(RubyEventStore::ROM::Memory::Relations::StreamEntries)
    expect(relation.by_stream(stream).take(1).one).to be_a(::ROM::Struct)

    expect(relation.by_stream_and_event_id(stream, id1)).to be_a(::ROM::Struct)
    
    expect(relation.max_position(stream)).to be_a(::ROM::Struct)

    expect(relation.ordered(:forward, stream)).to be_a(RubyEventStore::ROM::Memory::Relations::StreamEntries)
    expect(relation.ordered(:forward, stream).take(1).one).to be_a(::ROM::Struct)
  end
end

#   def ordered(direction, stream, offset_entry_id = nil)
#     reverse, operator = DIRECTION_MAP[direction]

#     raise ArgumentError, 'Direction must be :forward or :backward' if order.nil?

#     order_columns = %i[position id]
#     order_columns.delete(:position) if stream.global?
    
#     query = by_stream(stream)
#     query = query.restrict { |tuple| tuple[:id].public_send(operator, offset_entry_id) } if offset_entry_id
#     query = query.order(*order_columns)
#     query = new(query.dataset.reverse) if reverse

#     query
#   end
# end
