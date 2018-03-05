class MyEvent < RubyEventStore::Event

end

RSpec.describe PostgresqlQueue do
  include SchemaHelper

  around(:each) do |example|
    begin
      establish_database_connection
      load_database_schema
      example.run
    ensure
      drop_database
    end
  end

  let(:res) do
    RubyEventStore::Client.new(repository: RailsEventStoreActiveRecord::EventRepository.new)
  end

  subject(:q) do
    PostgresqlQueue::Reader.new(res)
  end

  it "has a version number" do
    expect(PostgresqlQueue::VERSION).not_to be nil
  end

  specify "exposes a single event" do
    res.publish_event(ev = MyEvent.new(data: {
      one: 1,
    }))
    expect(q.events(after_event_id: nil)).to eq([ev])
    expect(q.events(after_event_id: ev.event_id)).to eq([])
  end

end