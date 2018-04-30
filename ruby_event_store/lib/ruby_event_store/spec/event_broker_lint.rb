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

    def verify(_subscriber)
    end

    def call(subscriber, event, serialized_event)
      @dispatched << {subscriber: subscriber, event: event, serialized_event: serialized_event}
    end
  end

  class TestMapper
    def event_to_serialized_record(domain_event)
      {
        event_id:   domain_event.event_id,
        metadata:   domain_event.metadata.to_h,
        data:       domain_event.data,
        event_type: domain_event.class.name
      }
    end
  end

  subject(:broker) { broker_class.new }

  it 'raise error when no subscriber' do
    expect { broker.add_subscriber(nil, [])}.to raise_error(RubyEventStore::SubscriberNotExist)
    expect { broker.add_thread_subscriber(nil, [])}.to raise_error(RubyEventStore::SubscriberNotExist)
    expect { broker.add_global_subscriber(nil)}.to raise_error(RubyEventStore::SubscriberNotExist)
    expect { broker.add_thread_global_subscriber(nil)}.to raise_error(RubyEventStore::SubscriberNotExist)
  end

  it 'notifies subscribed handlers' do
    handler         = TestHandler.new
    another_handler = TestHandler.new
    global_handler  = TestHandler.new

    broker.add_subscriber(handler, [Test1DomainEvent, Test3DomainEvent])
    broker.add_subscriber(another_handler, [Test2DomainEvent])
    broker.add_global_subscriber(global_handler)

    event1 = Test1DomainEvent.new
    event2 = Test2DomainEvent.new
    event3 = Test3DomainEvent.new

    mapper = TestMapper.new

    [event1, event2, event3].each do |ev|
      broker.notify_subscribers(ev, mapper.event_to_serialized_record(ev))
    end

    expect(handler.events).to eq([event1,event3])
    expect(another_handler.events).to eq([event2])
    expect(global_handler.events).to eq([event1,event2,event3])
  end

  it 'notifies subscribed thread handlers' do
    handler         = TestHandler.new
    another_handler = TestHandler.new
    global_handler  = TestHandler.new
    mapper          = TestMapper.new

    broker.add_thread_subscriber(handler, [Test1DomainEvent, Test3DomainEvent])
    broker.add_thread_subscriber(another_handler, [Test2DomainEvent])
    broker.add_thread_global_subscriber(global_handler)

    event1 = Test1DomainEvent.new
    event2 = Test2DomainEvent.new
    event3 = Test3DomainEvent.new

    [event1, event2, event3].each do |ev|
      broker.notify_subscribers(ev,  mapper.event_to_serialized_record(ev))
    end

    expect(handler.events).to eq([event1,event3])
    expect(another_handler.events).to eq([event2])
    expect(global_handler.events).to eq([event1,event2,event3])
  end

  it 'raises error when no valid method on handler' do
    subscriber = InvalidTestHandler.new
    expect do
      broker.add_subscriber(subscriber, [Test1DomainEvent])
    end.to raise_error(RubyEventStore::InvalidHandler)
  end

  it 'raises error when no valid method on global handler' do
    subscriber = InvalidTestHandler.new
    expect do
      broker.add_global_subscriber(subscriber)
    end.to raise_error(RubyEventStore::InvalidHandler)
  end

  it 'raises error when no valid method on thread handler' do
    subscriber = InvalidTestHandler.new
    expect do
      broker.add_thread_subscriber(subscriber, [Test1DomainEvent])
    end.to raise_error(RubyEventStore::InvalidHandler)
  end

  it 'raises error when no valid method on global thread handler' do
    subscriber = InvalidTestHandler.new
    expect do
      broker.add_thread_global_subscriber(subscriber)
    end.to raise_error(RubyEventStore::InvalidHandler)
  end

  it 'returns lambda as an output of global subscribe methods' do
    handler   = TestHandler.new
    result = broker.add_global_subscriber(handler)
    expect(result).to respond_to(:call)
  end

  it 'returns lambda as an output of subscribe methods' do
    handler   = TestHandler.new
    result    = broker.add_subscriber(handler, [Test1DomainEvent, Test2DomainEvent])
    expect(result).to respond_to(:call)
  end

  it 'revokes global subscription' do
    mapper    = TestMapper.new
    handler   = TestHandler.new
    event1    = Test1DomainEvent.new
    event2    = Test2DomainEvent.new

    serialized_event1 = mapper.event_to_serialized_record(event1)
    serialized_event2 = mapper.event_to_serialized_record(event2)

    revoke    = broker.add_global_subscriber(handler)
    broker.notify_subscribers(event1, serialized_event1)
    expect(handler.events).to eq([event1])
    revoke.()
    broker.notify_subscribers(event2, serialized_event2)
    expect(handler.events).to eq([event1])
  end

  it 'revokes subscription' do
    mapper    = TestMapper.new
    handler   = TestHandler.new
    event1    = Test1DomainEvent.new
    event2    = Test2DomainEvent.new
    serialized_event1 = mapper.event_to_serialized_record(event1)
    serialized_event2 = mapper.event_to_serialized_record(event2)

    revoke    = broker.add_subscriber(handler, [Test1DomainEvent, Test2DomainEvent])
    broker.notify_subscribers(event1, serialized_event1)
    expect(handler.events).to eq([event1])
    revoke.()
    broker.notify_subscribers(event2, serialized_event2)
    expect(handler.events).to eq([event1])
  end

  it 'revokes thread global subscription' do
    mapper    = TestMapper.new
    handler   = TestHandler.new
    event1    = Test1DomainEvent.new
    event2    = Test2DomainEvent.new
    serialized_event1 = mapper.event_to_serialized_record(event1)
    serialized_event2 = mapper.event_to_serialized_record(event2)

    revoke    = broker.add_thread_global_subscriber(handler)
    broker.notify_subscribers(event1, serialized_event1)
    expect(handler.events).to eq([event1])
    revoke.()
    broker.notify_subscribers(event2, serialized_event2)
    expect(handler.events).to eq([event1])
  end

  it 'revokes thread subscription' do
    mapper            = TestMapper.new
    handler           = TestHandler.new
    event1            = Test1DomainEvent.new
    event2            = Test2DomainEvent.new
    serialized_event1 =  mapper.event_to_serialized_record(event1)
    serialized_event2 =  mapper.event_to_serialized_record(event2)

    revoke    = broker.add_thread_subscriber(handler, [Test1DomainEvent, Test2DomainEvent])
    broker.notify_subscribers(event1, serialized_event1)
    expect(handler.events).to eq([event1])
    revoke.()
    broker.notify_subscribers(event2, serialized_event2)
    expect(handler.events).to eq([event1])
  end

  it 'allows to provide a custom dispatcher' do
    dispatcher        = TestDispatcher.new
    handler           = TestHandler.new
    mapper            = TestMapper.new
    event1            = Test1DomainEvent.new
    serialized_event1 = mapper.event_to_serialized_record(event1)

    broker_with_custom_dispatcher = broker_class.new(dispatcher: dispatcher)
    broker_with_custom_dispatcher.add_subscriber(handler, [Test1DomainEvent])
    broker_with_custom_dispatcher.notify_subscribers(event1, serialized_event1)
    expect(dispatcher.dispatched).to eq([{subscriber: handler, event: event1, serialized_event: serialized_event1}])
  end

  it 'subscribes by type of event which is a String' do
    mapper          = TestMapper.new
    handler         = TestHandler.new
    broker.add_subscriber(handler, ["Test1DomainEvent"])
    broker.add_thread_subscriber(handler, ["Test1DomainEvent"])

    event1           = Test1DomainEvent.new
    serialized_event1 = mapper.event_to_serialized_record(event1)
    broker.notify_subscribers(event1, serialized_event1)

    expect(handler.events).to eq([event1,event1])
  end

  private

  class HandlerClass
    @@received = nil
    def self.received
      @@received
    end
    def call(event)
      @@received = event
    end
  end
end
