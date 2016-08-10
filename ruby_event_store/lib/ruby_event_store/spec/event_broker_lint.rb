RSpec.shared_examples :event_broker do |broker_class|
  Test1DomainEvent = Class.new(RubyEventStore::Event)
  Test2DomainEvent = Class.new(RubyEventStore::Event)
  Test3DomainEvent = Class.new(RubyEventStore::Event)

  class InvalidTestHandler
  end
  class TestHandler
    def initialize
      @events = []
    end

    def call(event)
      @events << event
    end

    attr_reader :events
  end
  class TestDispatcher
    attr_reader :dispatched

    def initialize
      @dispatched = []
    end

    def call(subscriber, event)
      @dispatched << {subscriber: subscriber, event: event}
    end
  end

  subject(:broker) { broker_class.new }

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
    message = "#call method not found " +
              "in InvalidTestHandler subscriber." +
              " Are you sure it is a valid subscriber?"
    subscriber = InvalidTestHandler.new
    broker.add_subscriber(subscriber, [Test1DomainEvent])
    expect { broker.notify_subscribers(Test1DomainEvent.new) }.to raise_error(RubyEventStore::MethodNotDefined, message)
  end

  it 'raises error when no valid method on global handler' do
    message = "#call method not found " +
              "in InvalidTestHandler subscriber." +
              " Are you sure it is a valid subscriber?"
    subscriber = InvalidTestHandler.new
    broker.add_global_subscriber(subscriber)
    expect { broker.notify_subscribers(Test1DomainEvent.new) }.to raise_error(RubyEventStore::MethodNotDefined, message)
  end

  it 'returns lambda as an output of global subscribe methods' do
    handler   = TestHandler.new
    result = broker.add_global_subscriber(handler)
    expect(result).to respond_to(:call)
  end

  it 'return lambda as an output of subscribe methods' do
    handler   = TestHandler.new
    result    = broker.add_subscriber(handler, [Test1DomainEvent, Test2DomainEvent])
    expect(result).to respond_to(:call)
  end

  it 'revokes global subscription' do
    handler   = TestHandler.new
    event1    = Test1DomainEvent.new
    event2    = Test2DomainEvent.new

    revoke    = broker.add_global_subscriber(handler)
    broker.notify_subscribers(event1)
    expect(handler.events).to eq([event1])
    revoke.()
    broker.notify_subscribers(event2)
    expect(handler.events).to eq([event1])
  end

  it 'revokes subscription' do
    handler   = TestHandler.new
    event1    = Test1DomainEvent.new
    event2    = Test2DomainEvent.new

    revoke    = broker.add_subscriber(handler, [Test1DomainEvent, Test2DomainEvent])
    broker.notify_subscribers(event1)
    expect(handler.events).to eq([event1])
    revoke.()
    broker.notify_subscribers(event2)
    expect(handler.events).to eq([event1])
  end

  it 'allows to provide a custom dispatcher' do
    dispatcher  = TestDispatcher.new
    handler     = TestHandler.new
    event1      = Test1DomainEvent.new
    broker_with_custom_dispatcher = broker_class.new(dispatcher: dispatcher)
    broker_with_custom_dispatcher.add_subscriber(handler, [Test1DomainEvent])
    broker_with_custom_dispatcher.notify_subscribers(event1)
    expect(dispatcher.dispatched).to eq([{subscriber: handler, event: event1}])
  end
end
