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

  specify "does not expose un-committed event" do
    exchanger = Concurrent::Exchanger.new
    timeout = 3
    res.publish_event(ev = MyEvent.new(data: {
      one: 1,
    }))
    ev2 = nil
    t = Thread.new do
      ActiveRecord::Base.transaction do
        res.publish_event(ev2 = MyEvent.new(data: {
          two: 2,
        }))
        exchanger.exchange!('published1', timeout)
        exchanger.exchange!('done1', timeout)
      end
    end
    exchanger.exchange!('published2', timeout)
    expect(q.events(after_event_id: nil)).to eq([ev])
    expect(q.events(after_event_id: ev.event_id)).to eq([])
    exchanger.exchange!('done2', timeout)
    t.join(timeout)
    expect(q.events(after_event_id: nil)).to eq([ev, ev2])
    expect(q.events(after_event_id: ev.event_id)).to eq([ev2])
  end

  specify "does not expose committed event after previous un-committed" do
    exchanger = Concurrent::Exchanger.new
    timeout = 3
    res.publish_event(ev = MyEvent.new(data: {
      one: 1,
    }))
    ev2 = nil
    t = Thread.new do
      ActiveRecord::Base.transaction do
        res.publish_event(ev2 = MyEvent.new(data: {
          two: 2,
        }))
        exchanger.exchange!('published1', timeout)
        exchanger.exchange!('done1', timeout)
      end
    end
    exchanger.exchange!('published2', timeout)
    res.publish_event(ev3 = MyEvent.new(data: {
      three: 3,
    }))
    expect(q.events(after_event_id: nil)).to eq([ev])
    expect(q.events(after_event_id: ev.event_id)).to eq([])
    exchanger.exchange!('done2', timeout)
    t.join(timeout)
    expect(q.events(after_event_id: nil)).to eq([ev, ev2, ev3])
    expect(q.events(after_event_id: ev.event_id)).to eq([ev2, ev3])
  end


  # Thread1: [1] [2,      4]
  # Thread2:          [3,     ]
  specify "does not expose committed event (4) after gap (3) if gap-event uncommitted" do
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
    exchanger = Concurrent::Exchanger.new
    timeout = 5
    ev3 = ev2 = ev4 = nil
    res.publish_event(ev1 = MyEvent.new(data: {one: 1},event_id: "11111111-1111-1111-1111-111111111111"))
    t = Thread.new do
      exchanger.exchange!('published2', timeout)
      ActiveRecord::Base.transaction do
        res.publish_event(ev3 = MyEvent.new(data: {three: 3},event_id: "33333333-3333-3333-3333-333333333333"))
        exchanger.exchange!('published3', timeout)
        exchanger.exchange!('published4', timeout)
      end
    end
    ActiveRecord::Base.transaction do
      res.publish_event(ev2 = MyEvent.new(data: {two: 2},event_id: "22222222-2222-2222-2222-222222222222"))
      exchanger.exchange!('published2', timeout)
      exchanger.exchange!('published3', timeout)
      res.publish_event(ev4 = MyEvent.new(data: {four: 4},event_id: "44444444-4444-4444-4444-444444444444"))
    end
    expect(q.events(after_event_id: nil)).to eq([ev1,ev2])
    expect(q.events(after_event_id: ev1.event_id)).to eq([ev2])
    expect(q.events(after_event_id: ev2.event_id)).to eq([])
    exchanger.exchange!('published4', timeout)
    t.join(timeout)
    expect(q.events(after_event_id: nil)).to eq([ev1, ev2, ev3, ev4])
    expect(q.events(after_event_id: ev1.event_id)).to eq([ev2, ev3, ev4])
  end
end