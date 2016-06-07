RSpec.shared_examples :event_broker do |broker|
  Test1DomainEvent = Class.new(RubyEventStore::Event)
  Test2DomainEvent = Class.new(RubyEventStore::Event)
  Test3DomainEvent = Class.new(RubyEventStore::Event)

  class IncorrectDenormalizer
  end
  class TestHandler
    def initialize
      @events = []
    end

    def handle_event(event)
      @events << event
    end

    attr_reader :events
  end

  it 'raise error when no subscriber' do
    expect { broker.add_subscriber(nil, [])}.to raise_error(RubyEventStore::SubscriberNotExist)
    expect { broker.add_global_subscriber(nil)}.to raise_error(RubyEventStore::SubscriberNotExist)
  end

  it 'notify subscribed handlers' do
    handler         = TestHandler.new
    another_handler = TestHandler.new
    global_handler  = TestHandler.new

    broker.add_subscriber(handler, [Test1DomainEvent, Test3DomainEvent])
    broker.add_subscriber(another_handler, [Test2DomainEvent])
    broker.add_global_subscriber(global_handler)

    event1 = Test1DomainEvent.new
    event2 = Test2DomainEvent.new
    event3 = Test3DomainEvent.new

    [event1, event2, event3].each do |ev|
      broker.notify_subscribers(ev)
    end

    expect(handler.events).to eq([event1,event3])
    expect(another_handler.events).to eq([event2])
    expect(global_handler.events).to eq([event1,event2,event3])
  end

  it 'raises error when no valid method on handler' do
    message = "#handle_event method is not found " +
              "in Subscribers::IncorrectDenormalizer subscriber." +
              " Are you sure it is a valid subscriber?"
    subscriber = Subscribers::IncorrectDenormalizer.new
    expect { broker.add_subscriber(subscriber, [])}.to raise_error(RubyEventStore::MethodNotDefined, message)
    expect { broker.add_global_subscriber(subscriber)}.to raise_error(RubyEventStore::MethodNotDefined, message)
  end
end
