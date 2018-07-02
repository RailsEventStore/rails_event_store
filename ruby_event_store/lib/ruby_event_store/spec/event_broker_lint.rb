RSpec.shared_examples :event_broker do |broker_class|
  Test1DomainEvent = Class.new(RubyEventStore::Event)
  Test2DomainEvent = Class.new(RubyEventStore::Event)
  Test3DomainEvent = Class.new(RubyEventStore::Event)

  class TestHandler
    def initialize
      @events = []
    end

    def call(event)
      @events << event
    end

    attr_reader :events
  end

  subject(:broker) { broker_class.new }

  it 'returns all subscribed handlers' do
    handler         = TestHandler.new
    another_handler = TestHandler.new
    global_handler  = TestHandler.new

    broker.local.add(handler, [Test1DomainEvent, Test3DomainEvent])
    broker.local.add(another_handler, [Test2DomainEvent])
    broker.global.add(global_handler)

    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([handler, global_handler])
    expect(broker.all_subscribers_for('Test2DomainEvent')).to eq([another_handler, global_handler])
    expect(broker.all_subscribers_for('Test3DomainEvent')).to eq([handler, global_handler])
  end

  it 'returns subscribed thread handlers' do
    handler         = TestHandler.new
    another_handler = TestHandler.new
    global_handler  = TestHandler.new

    broker.thread.local.add(handler, [Test1DomainEvent, Test3DomainEvent])
    broker.thread.local.add(another_handler, [Test2DomainEvent])
    broker.thread.global.add(global_handler)

    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([global_handler, handler])
    expect(broker.all_subscribers_for('Test2DomainEvent')).to eq([global_handler, another_handler])
    expect(broker.all_subscribers_for('Test3DomainEvent')).to eq([global_handler, handler])
  end

  it 'returns lambda as an output of global subscribe methods' do
    handler   = TestHandler.new
    result = broker.global.add(handler)
    expect(result).to respond_to(:call)
  end

  it 'returns lambda as an output of subscribe methods' do
    handler   = TestHandler.new
    result    = broker.local.add(handler, [Test1DomainEvent, Test2DomainEvent])
    expect(result).to respond_to(:call)
  end

  it 'revokes global subscription' do
    handler   = TestHandler.new

    revoke    = broker.global.add(handler)
    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([handler])
    expect(broker.all_subscribers_for('Test2DomainEvent')).to eq([handler])
    revoke.()
    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([])
    expect(broker.all_subscribers_for('Test2DomainEvent')).to eq([])
  end

  it 'revokes subscription' do
    handler   = TestHandler.new

    revoke    = broker.local.add(handler, [Test1DomainEvent, Test2DomainEvent])
    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([handler])
    expect(broker.all_subscribers_for('Test2DomainEvent')).to eq([handler])
    revoke.()
    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([])
    expect(broker.all_subscribers_for('Test2DomainEvent')).to eq([])
  end

  it 'revokes thread global subscription' do
    handler   = TestHandler.new

    revoke    = broker.thread.global.add(handler)
    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([handler])
    expect(broker.all_subscribers_for('Test2DomainEvent')).to eq([handler])
    revoke.()
    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([])
    expect(broker.all_subscribers_for('Test2DomainEvent')).to eq([])
  end

  it 'revokes thread subscription' do
    handler           = TestHandler.new

    revoke    = broker.thread.local.add(handler, [Test1DomainEvent, Test2DomainEvent])
    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([handler])
    expect(broker.all_subscribers_for('Test2DomainEvent')).to eq([handler])
    revoke.()
    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([])
    expect(broker.all_subscribers_for('Test2DomainEvent')).to eq([])
  end

  it 'subscribes by type of event which is a String' do
    handler         = TestHandler.new
    broker.local.add(handler, ["Test1DomainEvent"])
    broker.thread.local.add(handler, ["Test1DomainEvent"])

    expect(broker.all_subscribers_for('Test1DomainEvent')).to eq([handler, handler])
  end
end
