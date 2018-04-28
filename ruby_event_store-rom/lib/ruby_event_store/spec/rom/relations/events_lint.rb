RSpec.shared_examples :events_relation do |relation_class|
  subject(:relation) { container.relations[:events] }

  let(:env) { rom_helper.env }
  let(:container) { env.container }
  let(:rom_db) { container.gateways[:default] }

  around(:each) do |example|
    rom_helper.run_lifecycle { example.run }
  end

  it 'just created is empty' do
    expect(relation.to_a).to be_empty
  end

  specify '#exist? indicates if one instance of the record exists by primary key' do
    event = {id: SecureRandom.uuid}

    expect(relation.by_pk(event[:id]).exist?).to eq(false)

    relation.insert(event)

    expect(relation.by_pk(event[:id]).exist?).to eq(true)
  end

  specify '#insert verifies tuple is unique' do
    events = [
      {id: SecureRandom.uuid},
      {id: SecureRandom.uuid},
      {id: SecureRandom.uuid}
    ]

    relation.insert(events[0])
    relation.insert(events[1])

    expect{relation.insert(events[0])}.to raise_error(RubyEventStore::ROM::TupleUniquenessError)
    expect{relation.insert(events[1])}.to raise_error(RubyEventStore::ROM::TupleUniquenessError)
    expect{relation.insert(events[2])}.not_to raise_error
    expect{relation.insert(events[2])}.to raise_error(RubyEventStore::ROM::TupleUniquenessError)
  end

  specify '#by_pk finds tuples by ID' do
    events = [
      {id: SecureRandom.uuid},
      {id: SecureRandom.uuid},
      {id: SecureRandom.uuid}
    ]

    relation.command(:create).call(events)

    expect(relation.by_pk(events[0][:id]).to_a.size).to eq(1)
    expect(relation.by_pk(events[0][:id]).to_a).to eq([events[0]])
  end

  specify '#pluck returns an array with single value for each tuple' do
    events = [
      {id: id1 = SecureRandom.uuid},
      {id: id2 = SecureRandom.uuid},
      {id: id3 = SecureRandom.uuid}
    ]

    relation.command(:create).call(events)

    expect(relation.to_a.size).to eq(3)
    expect(relation.pluck(:id)).to eq([id1, id2, id3])
    expect(relation.by_pk(events[0][:id]).to_a.size).to eq(1)
    expect(relation.by_pk(events[0][:id]).pluck(:id)).to eq([id1])
  end

  specify '#for_stream_entries filters events on :event_id in stream entries' do
    events = [
      {id: id1 = SecureRandom.uuid},
      {id: id2 = SecureRandom.uuid},
      {id: id3 = SecureRandom.uuid}
    ]

    stream_entries = [
      {id: 1, event_id: id2},
      {id: 2, event_id: id3}
    ]

    relation.command(:create).call(events)

    expect(relation.for_stream_entries(nil, stream_entries).to_a).to eq([events[1], events[2]])
  end
end
