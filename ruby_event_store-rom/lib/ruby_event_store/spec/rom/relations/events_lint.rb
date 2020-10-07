RSpec.shared_examples :events_relation do |_relation_class|
  subject(:relation) { rom_container.relations[:events] }

  let(:env) { rom_helper.env }
  let(:rom_container) { env.rom_container }
  let(:rom_db) { rom_container.gateways[:default] }

  around(:each) do |example|
    rom_helper.run_lifecycle { example.run }
  end

  it 'just created is empty' do
    expect(relation.to_a).to be_empty
  end

  specify '#exist? indicates if one instance of the record exists by primary key' do
    event = { event_id: SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now }

    expect(relation.by_event_id(event[:event_id]).exist?).to eq(false)

    relation.insert(event)

    expect(relation.by_event_id(event[:event_id]).exist?).to eq(true)
  end

  specify '#insert verifies tuple is unique' do
    events = [
      { event_id: SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
      { event_id: SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
      { event_id: SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now }
    ]

    relation.command(:create).call(events[0..1])

    expect do
      env.handle_error(:unique_violation) { relation.insert(events[0]) }
    end.to raise_error(RubyEventStore::EventDuplicatedInStream)
    expect do
      env.handle_error(:unique_violation) { relation.insert(events[1]) }
    end.to raise_error(RubyEventStore::EventDuplicatedInStream)
    expect { relation.insert(events[2]) }.not_to raise_error
    expect do
      env.handle_error(:unique_violation) { relation.insert(events[2]) }
    end.to raise_error(RubyEventStore::EventDuplicatedInStream)
  end

  specify '#by_event_id finds tuples by ID' do
    events = [
      { event_id: id = SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
      { event_id: SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
      { event_id: SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now }
    ]

    relation.command(:create).call(events)

    expect(relation.by_event_id(id).to_a.size).to eq(1)
    expect(relation.by_event_id(id).to_a.map { |e| e[:event_id] }).to eq([id])
  end

  specify 'each method returns proper type' do
    events = [
      { event_id: id = SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
      { event_id: SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now },
      { event_id: SecureRandom.uuid, event_type: 'TestEvent', data: '{}', metadata: '{}', created_at: Time.now, valid_at: Time.now }
    ]

    relation.command(:create).call(events)

    expect(relation.by_event_id(SecureRandom.uuid).exist?).to eq(false)
    expect(relation.by_event_id(id).exist?).to eq(true)

    expect(relation.by_event_id(id)).to be_a(relation.class)
    # expect(relation.by_event_id(id).first).to be_a(::ROM::Struct)
  end
end
