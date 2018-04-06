require 'spec_helper'
require 'pry'
require 'logger'

class MyEvent < RubyEventStore::Event
end

RSpec.describe PostgresqlQueue::Reader do
  include SchemaHelper

  around(:all) do |example|
    begin
      establish_database_connection
      load_database_schema
      example.run
    ensure
      drop_database
    end
  end


  before(:each) do
    establish_database_connection
    ActiveRecord::Base.connection.execute("TRUNCATE event_store_events")
    ActiveRecord::Base.connection.execute("TRUNCATE event_store_events_in_streams")
  end

  let(:res) do
    RubyEventStore::Client.new(repository: DistributedRepository.new)
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
    expect(q.events(after_event_id: nil)).to eqs([ev])
    expect(q.events(after_event_id: ev.event_id)).to eqs([])
  end

  specify "exposes max count events" do
    res.publish_events(events = 10.times.map{MyEvent.new})
    expect(q.events(after_event_id: nil, count: 2 )).to eqs(events[0..1])
  end

  specify "exposes 100 events by default" do
    res.publish_events(events = 105.times.map{MyEvent.new})
    expect(q.events(after_event_id: nil)).to eqs(events[0..99])
  end

  specify "does not read too much Events unnecessarily" do
    res.publish_events(events = 10.times.map{MyEvent.new})

    allow(MyEvent).to receive(:new).and_call_original
    expect(q.events(after_event_id: events[5].event_id, count: 3 )).to eqs(events[6..8])
    expect(MyEvent).to have_received(:new).exactly(3).times
  end

  specify "does not read too much EventInStream unnecessarily" do
    res.publish_events(events = 50.times.map{MyEvent.new})

    allow(RailsEventStoreActiveRecord::EventInStream).to receive(:allocate).and_call_original
    q.events(after_event_id: events[5].event_id, count: 10)
    expect(RailsEventStoreActiveRecord::EventInStream).to have_received(:allocate).exactly(2*10+3).times
  end

  specify "does not read EventInStream from linked stream" do
    res.publish_events(events = 50.times.map{MyEvent.new})
    res.link_to_stream(events[5].event_id, stream_name: "elo")

    allow(RailsEventStoreActiveRecord::EventInStream).to receive(:allocate).and_call_original
    q.events(after_event_id: events[5].event_id, count: 10)
    expect(RailsEventStoreActiveRecord::EventInStream).to have_received(:allocate).exactly(2*10+3).times
  end

  specify "handles non global stream" do
    res.publish_events(events = 50.times.map{MyEvent.new}, stream_name: "whoa")
    expect(q.events(after_event_id: nil, count: 5 )).to eqs(events[0..4])
    expect(q.events(after_event_id: events[4].event_id, count: 5 )).to eqs(events[5..9])
  end

  specify "explicit id ASC query" do
    res.publish_event(ev = MyEvent.new(data: {
      one: 1,
    }))
    expect_query(/SELECT.*FROM.*event_store_events_in_streams.*WHERE.*id.*>=.*AND.*id.*<=.*ORDER BY id ASC.*/) do
      expect(q.events(after_event_id: nil)).to eqs([ev])
    end
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
    expect(q.events(after_event_id: nil)).to eqs([ev])
    expect(q.events(after_event_id: ev.event_id)).to eqs([])
    exchanger.exchange!('done2', timeout)
    t.join(timeout)
    expect(q.events(after_event_id: nil)).to eqs([ev, ev2])
    expect(q.events(after_event_id: ev.event_id)).to eqs([ev2])
  end

  # Thread1: [1]     [3]
  # Thread2:     [2          ]
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
    expect(q.events(after_event_id: nil)).to eqs([ev])
    expect(q.events(after_event_id: ev.event_id)).to eqs([])
    exchanger.exchange!('done2', timeout)
    t.join(timeout)
    expect(q.events(after_event_id: nil)).to eqs([ev, ev2, ev3])
    expect(q.events(after_event_id: ev.event_id)).to eqs([ev2, ev3])
  end


  # Thread1: [1] [2,      4]
  # Thread2:          [3,     ]
  specify "does not expose committed event (4) after gap (3) if gap-event uncommitted" do
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
    expect(q.events(after_event_id: nil)).to eqs([ev1,ev2])
    expect(q.events(after_event_id: ev1.event_id)).to eqs([ev2])
    expect(q.events(after_event_id: ev2.event_id)).to eqs([])
    exchanger.exchange!('published4', timeout)
    t.join(timeout)
    expect(q.events(after_event_id: nil)).to eqs([ev1, ev2, ev3, ev4])
    expect(q.events(after_event_id: ev1.event_id)).to eqs([ev2, ev3, ev4])
  end

  private

  def expect_query(match, &block)
    count = 0
    counter_f = ->(_name, _started, _finished, _unique_id, payload) {
      count +=1 if match === payload[:sql]
    }
    ActiveSupport::Notifications.subscribed(counter_f, "sql.active_record", &block)
    expect(count).to eq(1)
  end

  RSpec::Matchers.define :eqs do |expected|
    match do |provided|
      @actual = provided.map(&:event_id)
      values_match?(expected.map(&:event_id), @actual)
    end
  end
end




# Thread1: [1] [       3,     5]
# Thread2:        [2,      4,    6]
#
#
# Thread1: [1] [       3,     5           ]
# Thread2:        [2,      4,    6]   X
#
#

# Thread1: [1]                          X
# Thread2:        [2L,     3G,     4S]
#
# Thread1: [1]         [3L,     5G,      7S]
# Thread2:        [2L,     4G,     6S] X

# Thread1: [1]                 [4L,     6G,   7S]
# Thread2:        [2L,     3G,     5S] X

# co z GAPami które się wydarzają pomiędzy insertami jednej transakcji
# a insertami drugiej transakcji? albo lock-sequencem drugiej transakcji?

# assumption: 1st GAP i meet must be from
# * my own transaction lock-seq which is already committed (otherwise I would not see higher numbers)
# * another uncommitted transaction
#
# Question: Can it be from something else?


# Thread1: [1]                 [4          L,     6G,   7S]
# Thread2:        [2L,     3G,     5S] X
#
#
# Co gdybym wszystkie numery sekwencji brał w krótkim locku?
#   wtedy nie zserializowałem zapisów ale zserializowałem branie numerów
#   lock(global)
#     SELECT
#       currval() as c                      32
#       setval(currval()+N)                 42 (uzyjemy 33..42)
#       pg_advisory_xact_lock(c+1=33),
#   unlock(global)


# Thread1: [1]                 [4L56,       6G,   7S]
# Thread2:        [2L35,     3G,     5S] X
#

# wtedy czesc sekwencji z jednej transakcji ma rosnace numery
# pierwszy gap ma zrealeasowany lock, nastepne gapy nie mają locka.
#
# jesli inna transakcja tez cos pobrała zanim ta sie skonczyla
# to jej pierwszy numer ma locka.