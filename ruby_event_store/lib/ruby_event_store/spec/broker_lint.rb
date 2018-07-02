RSpec.shared_examples :broker do |broker_klass|
  let(:event) { instance_double(::RubyEventStore::Event, type: 'EventType') }
  let(:serialized_event) { instance_double(::RubyEventStore::SerializedRecord)  }
  let(:handler) { HandlerClass.new }
  let(:subscriptions) { ::RubyEventStore::PubSub::Subscriptions.new }
  let(:dispatcher) { ::RubyEventStore::PubSub::Dispatcher.new }
  let(:broker) { broker_klass.new(subscriptions: subscriptions, dispatcher: dispatcher) }

  specify "must have subscriptions & dispatcher" do
    broker = broker_klass.new(subscriptions: subscriptions, dispatcher: dispatcher)
    expect(broker.subscriptions).to eq(subscriptions)
    expect(broker.dispatcher).to eq(dispatcher)
  end

  specify "no dispatch when no subscriptions" do
    expect(subscriptions).to receive(:all_for).with('EventType').and_return([])
    expect(dispatcher).not_to receive(:call)
    broker.call(event, serialized_event)
  end

  specify "calls subscription" do
    expect(subscriptions).to receive(:all_for).with('EventType').and_return([handler])
    expect(dispatcher).to receive(:call).with(handler, event, serialized_event)
    broker.call(event, serialized_event)
  end

  specify "calls subscribed class" do
    expect(subscriptions).to receive(:all_for).with('EventType').and_return([HandlerClass])
    expect(dispatcher).to receive(:call).with(HandlerClass, event, serialized_event)
    broker.call(event, serialized_event)
  end

  specify "calls all subscriptions" do
    expect(subscriptions).to receive(:all_for).with('EventType').and_return([handler, HandlerClass])
    expect(dispatcher).to receive(:call).with(handler, event, serialized_event)
    expect(dispatcher).to receive(:call).with(HandlerClass, event, serialized_event)
    broker.call(event, serialized_event)
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
