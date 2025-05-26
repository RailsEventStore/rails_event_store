# frozen_string_literal: true

require "spec_helper"

class CustomDispatcher
  attr_reader :dispatched_events

  def initialize
    @dispatched_events = []
  end

  def call(subscriber, event, record)
    subscriber = subscriber.new if Class === subscriber
    @dispatched_events << { to: subscriber.class, event: event, record: record }
  end

  def verify(subscriber)
    subscriber = subscriber.new if Class === subscriber
    subscriber.respond_to?(:call) or raise InvalidHandler.new(subscriber)
  rescue ArgumentError
    raise InvalidHandler.new(subscriber)
  end
end

class LegacyBroker
  def initialize(
    subscriptions: RubyEventStore::Subscriptions.new,
    dispatcher: RubyEventStore::Dispatcher.new
  )
    @subscriptions = subscriptions
    @dispatcher = dispatcher
  end

  def call(event, record)
    subscribers = subscriptions.all_for(event.event_type)
    subscribers.each { |subscriber| dispatcher.call(subscriber, event, record) }
  end

  def add_subscription(subscriber, event_types)
    verify_subscription(subscriber)
    subscriptions.add_subscription(subscriber, event_types)
  end

  def add_global_subscription(subscriber)
    verify_subscription(subscriber)
    subscriptions.add_global_subscription(subscriber)
  end

  def add_thread_subscription(subscriber, event_types)
    verify_subscription(subscriber)
    subscriptions.add_thread_subscription(subscriber, event_types)
  end

  def add_thread_global_subscription(subscriber)
    verify_subscription(subscriber)
    subscriptions.add_thread_global_subscription(subscriber)
  end

  def all_subscriptions_for(event_type)
    subscriptions.all_for(event_type)
  end

  private

  attr_reader :dispatcher, :subscriptions

  def verify_subscription(subscriber)
    unless subscriber
      raise SubscriberNotExist, "subscriber must be first argument or block"
    end
    unless dispatcher.verify(subscriber)
      raise InvalidHandler.new(
              "Handler #{subscriber} is invalid for dispatcher #{dispatcher}"
            )
    end
  end
end

module RubyEventStore
  ::RSpec.describe Client do
    let(:mapper) { Mappers::Default.new }
    let(:client) { Client.new(mapper: mapper) }

    specify "throws exception if subscriber is not defined" do
      expect { client.subscribe(nil, to: []) }.to raise_error(
        SubscriberNotExist
      )
      expect { client.subscribe_to_all_events(nil) }.to raise_error(
        SubscriberNotExist
      )
    end

    specify "throws exception if subscriber has not call method - handling subscribed events" do
      subscriber = Subscribers::InvalidHandler.new
      expect {
        client.subscribe(subscriber, to: [OrderCreated])
      }.to raise_error(InvalidHandler)
    end

    specify "throws exception if subscriber has not call method - handling all events" do
      subscriber = Subscribers::InvalidHandler.new
      expect { client.subscribe_to_all_events(subscriber) }.to raise_error(
        InvalidHandler
      )
    end

    specify "notifies subscribers listening on all events" do
      subscriber = Subscribers::ValidHandler.new
      client.subscribe_to_all_events(subscriber)
      event = OrderCreated.new
      client.publish(event)
      expect(subscriber.handled_events).to eq [event]
    end

    specify "still supports old brokers, topic will be ignored" do
      dispatcher = CustomDispatcher.new
      client =
        RubyEventStore::Client.new(
          message_broker: LegacyBroker.new(dispatcher: dispatcher)
        )
      subscriber_1 = Subscribers::ValidHandler.new
      subscriber_2 = Subscribers::ValidHandler.new
      client.subscribe(subscriber_1, to: [TestEvent])
      client.subscribe(subscriber_2, to: ["topic"])
      event = TestEvent.new
      client.publish(event, topic: "topic")
      record = mapper.event_to_record(event)
      expect(dispatcher.dispatched_events).to eq [
           { to: Subscribers::ValidHandler, event: event, record: record }
         ]
    end

    specify "warns when using old broker" do
      expect {
        RubyEventStore::Client.new(message_broker: LegacyBroker.new).publish(
          TestEvent.new
        )
      }.to output(<<~EOS).to_stderr
          Message broker shall support topics.
          Topic WILL BE IGNORED in the current broker.
          Modify the broker implementation to pass topic as an argument to broker.call method.
        EOS
    end

    specify "notifies subscribers listening on topic" do
      subscriber = Subscribers::ValidHandler.new
      client.subscribe(subscriber, to: ["topic", TestEvent])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      event_3 = TestEvent.new
      event_4 = TestEvent.new
      client.publish(event_1, topic: "topic")
      client.publish(event_2, topic: "another_topic")
      client.publish(event_3)
      client.publish(event_4, topic: "not_that_topic")
      expect(subscriber.handled_events).to eq [event_1, event_3]
    end

    specify "notifies subscribers listening on list of events" do
      subscriber = Subscribers::ValidHandler.new
      client.subscribe(subscriber, to: [OrderCreated, ProductAdded])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      client.publish(event_1)
      client.publish(event_2)
      expect(subscriber.handled_events).to eq [event_1, event_2]
    end

    specify "notifies subscribers listening on all events - with lambda" do
      handled_events = []
      subscriber = ->(event) { handled_events << event }
      client.subscribe_to_all_events(subscriber)
      event = OrderCreated.new
      client.publish(event)
      expect(handled_events).to eq [event]
    end

    specify "notifies subscribers listening on all events - with proc" do
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      subscriber = Subscribers::ValidHandler.new
      unsub = client.subscribe_to_all_events { |ev| subscriber.call(ev) }
      client.publish(event_1)
      unsub.()
      client.publish(event_2)
      expect(subscriber.handled_events).to eq [event_1]
      expect(client.read.to_a).to eq([event_1, event_2])
    end

    specify "notifies subscribers listening on list of events - with lambda" do
      handled_events = []
      subscriber = ->(event) { handled_events << event }
      client.subscribe(subscriber, to: [OrderCreated, ProductAdded])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      client.publish(event_1)
      client.publish(event_2)
      expect(handled_events).to eq [event_1, event_2]
    end

    specify "notifies subscribers listening on list of events - with proc" do
      handled_events = []
      client.subscribe(to: [OrderCreated, ProductAdded]) do |event|
        handled_events << event
      end
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      client.publish(event_1)
      client.publish(event_2)
      expect(handled_events).to eq [event_1, event_2]
    end

    specify "allows to provide a custom dispatcher" do
      dispatcher = CustomDispatcher.new
      client =
        Client.new(
          message_broker: Broker.new(dispatcher: dispatcher),
          mapper: mapper
        )
      subscriber = Subscribers::ValidHandler.new
      client.subscribe(subscriber, to: [OrderCreated])
      event = OrderCreated.new
      client.publish(event)
      record = mapper.event_to_record(event)
      expect(dispatcher.dispatched_events).to eq [
           { to: Subscribers::ValidHandler, event: event, record: record }
         ]
    end

    specify "unsubscribes" do
      Subscribers::ValidHandler.new
      event_1 = OrderCreated.new
      event_2 = OrderCreated.new
      subscriber = Subscribers::ValidHandler.new
      unsub = client.subscribe(subscriber, to: [OrderCreated])
      client.publish(event_1)
      unsub.()
      client.publish(event_2)
      expect(subscriber.handled_events).to eq [event_1]
      expect(client.read.to_a).to eq([event_1, event_2])
    end

    specify "dynamic subscription" do
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      subscriber = Subscribers::ValidHandler.new
      client
        .within { client.publish(event_1) }
        .subscribe(subscriber, to: [OrderCreated, ProductAdded])
        .call
      client.publish(event_2)
      expect(subscriber.handled_events).to eq [event_1]
      expect(client.read.to_a).to eq([event_1, event_2])
    end

    specify "subscribers receive event with enriched metadata" do
      client = Client.new(clock: -> { Time.at(0) })
      received_event = nil
      client.subscribe(to: [OrderCreated]) { |event| received_event = event }
      client.publish(OrderCreated.new)

      expect(received_event).not_to be_nil
      expect(received_event.metadata[:timestamp]).to eq(Time.at(0))
    end

    specify "throws exception if subscriber klass does not have call method - handling subscribed events" do
      expect {
        client.subscribe(Subscribers::InvalidHandler, to: [OrderCreated])
      }.to raise_error(InvalidHandler)
    end

    specify "throws exception if subscriber klass have not call method - handling all events" do
      expect {
        client.subscribe_to_all_events(Subscribers::InvalidHandler)
      }.to raise_error(InvalidHandler)
    end

    specify "dispatch events to subscribers via proxy" do
      dispatcher = CustomDispatcher.new
      client =
        Client.new(
          mapper: mapper,
          message_broker: Broker.new(dispatcher: dispatcher)
        )
      client.subscribe(Subscribers::ValidHandler, to: [OrderCreated])
      event = OrderCreated.new
      client.publish(event)
      record = mapper.event_to_record(event)
      expect(dispatcher.dispatched_events).to eq [
           { to: Subscribers::ValidHandler, event: event, record: record }
         ]
    end

    specify "dispatch all events to subscribers via proxy" do
      dispatcher = CustomDispatcher.new
      client =
        Client.new(
          mapper: mapper,
          message_broker: Broker.new(dispatcher: dispatcher)
        )
      client.subscribe_to_all_events(Subscribers::ValidHandler)
      event = OrderCreated.new
      client.publish(event)
      record = mapper.event_to_record(event)
      expect(dispatcher.dispatched_events).to eq [
           { to: Subscribers::ValidHandler, event: event, record: record }
         ]
    end

    specify "lambda is an output of global subscribe via proxy" do
      dispatcher = CustomDispatcher.new
      client =
        Client.new(
          mapper: mapper,
          message_broker: Broker.new(dispatcher: dispatcher)
        )
      result = client.subscribe_to_all_events(Subscribers::ValidHandler)
      expect(result).to respond_to(:call)
    end

    specify "lambda is an output of subscribe via proxy" do
      dispatcher = CustomDispatcher.new
      client =
        Client.new(
          mapper: mapper,
          message_broker: Broker.new(dispatcher: dispatcher)
        )
      result = client.subscribe(Subscribers::ValidHandler, to: [OrderCreated])
      expect(result).to respond_to(:call)
    end

    specify "dynamic global subscription via proxy" do
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      dispatcher = CustomDispatcher.new
      client =
        Client.new(
          mapper: mapper,
          message_broker: Broker.new(dispatcher: dispatcher)
        )
      result =
        client
          .within do
            client.publish(event_1)
            :elo
          end
          .subscribe_to_all_events(Subscribers::ValidHandler)
          .call
      client.publish(event_2)
      record = mapper.event_to_record(event_1)
      expect(dispatcher.dispatched_events).to eq [
           { to: Subscribers::ValidHandler, event: event_1, record: record }
         ]
      expect(result).to eq(:elo)
      expect(client.read.to_a).to eq([event_1, event_2])
    end

    specify "notifies subscriber in the order events were published" do
      handled_events = []
      subscriber = ->(event) { handled_events << event }
      client.subscribe(subscriber, to: [ProductAdded, OrderCreated])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      client.publish([event_1, event_2])
      expect(handled_events).to eq [event_1, event_2]
    end

    specify "with many subscribers they are called in the order events were published" do
      handled_events = []
      subscriber1 = ->(event) do
        handled_events << event
        handled_events << :subscriber1
      end
      client.subscribe(subscriber1, to: [ProductAdded, OrderCreated])
      subscriber2 = ->(event) do
        handled_events << event
        handled_events << :subscriber2
      end
      client.subscribe(subscriber2, to: [ProductAdded, OrderCreated])
      event_1 = OrderCreated.new
      event_2 = ProductAdded.new
      client.publish([event_1, event_2])
      expect(handled_events).to eq [
           event_1,
           :subscriber1,
           event_1,
           :subscriber2,
           event_2,
           :subscriber1,
           event_2,
           :subscriber2
         ]
    end

    specify "subscribe unallowed calls" do
      expect { client.subscribe(-> {}, to: []) {} }.to raise_error(
        ArgumentError,
        "subscriber must be first argument or block, cannot be both"
      )

      expect { client.subscribe(to: []) }.to raise_error(
        SubscriberNotExist,
        "subscriber must be first argument or block"
      )

      expect { client.subscribe_to_all_events }.to raise_error(
        SubscriberNotExist,
        "subscriber must be first argument or block"
      )

      expect { client.subscribe_to_all_events(-> {}) {} }.to raise_error(
        ArgumentError,
        "subscriber must be first argument or block, cannot be both"
      )
    end

    context "dynamic subscribe v2" do
      specify "dynamic global subscription via proxy" do
        event_1 = OrderCreated.new
        event_2 = ProductAdded.new
        dispatcher = CustomDispatcher.new
        client =
          Client.new(
            mapper: mapper,
            message_broker: Broker.new(dispatcher: dispatcher)
          )

        result =
          client
            .within do
              client.publish(event_1)
              :yo
            end
            .subscribe_to_all_events(Subscribers::ValidHandler)
            .call

        client.publish(event_2)
        record = mapper.event_to_record(event_1)
        expect(dispatcher.dispatched_events).to eq [
             { to: Subscribers::ValidHandler, event: event_1, record: record }
           ]
        expect(client.read.to_a).to eq([event_1, event_2])
        expect(result).to eq(:yo)
      end

      specify "dynamic subscription" do
        event_1 = OrderCreated.new
        event_2 = ProductAdded.new
        event_3 = ProductAdded.new
        types = [OrderCreated, ProductAdded]
        result =
          client
            .within do
              client.publish(event_1)
              client.publish(event_2)
              :result
            end
            .subscribe(h = Subscribers::ValidHandler.new, to: types)
            .call

        client.publish(event_3)
        expect(h.handled_events).to eq([event_1, event_2])
        expect(result).to eq(:result)
        expect(client.read.to_a).to eq([event_1, event_2, event_3])
      end

      specify "nested dynamic subscription" do
        e1 = e2 = e3 = e4 = e5 = e6 = nil
        h2 = nil
        result =
          client
            .within do
              client.publish(e1 = ProductAdded.new)
              client.publish(e2 = OrderCreated.new)
              client
                .within do
                  client.publish(e3 = ProductAdded.new)
                  client.publish(e4 = OrderCreated.new)
                  :result1
                end
                .subscribe(
                  h2 = Subscribers::ValidHandler.new,
                  to: [OrderCreated]
                )
                .call
              client.publish(e5 = ProductAdded.new)
              client.publish(e6 = OrderCreated.new)
              :result2
            end
            .subscribe(h1 = Subscribers::ValidHandler.new, to: [ProductAdded])
            .call
        client.publish(e7 = ProductAdded.new)
        client.publish(e8 = OrderCreated.new)

        expect(h1.handled_events).to eq([e1, e3, e5])
        expect(h2.handled_events).to eq([e4])
        expect(result).to eq(:result2)
        expect(client.read.to_a).to eq([e1, e2, e3, e4, e5, e6, e7, e8])
      end

      specify "dynamic subscription with exception" do
        event_1 = OrderCreated.new
        event_2 = OrderCreated.new
        exception = Class.new(StandardError)
        begin
          client
            .within do
              client.publish(event_1)
              raise exception
            end
            .subscribe(h = Subscribers::ValidHandler.new, to: OrderCreated)
            .call
        rescue exception
        end
        client.publish(event_2)
        expect(h.handled_events).to eq([event_1])
        expect(client.read.to_a).to eq([event_1, event_2])
      end

      specify "chained subscriptions" do
        event_1 = OrderCreated.new
        event_2 = ProductAdded.new
        event_3 = ProductAdded.new
        h1, h2, h3, h4 = 4.times.map { Subscribers::ValidHandler.new }
        result =
          client
            .within do
              client.publish(event_1)
              client.publish(event_2)
              :result
            end
            .subscribe(h1, to: OrderCreated)
            .subscribe_to_all_events(h2)
            .subscribe(to: [ProductAdded]) { |ev| h3.call(ev) }
            .subscribe_to_all_events { |ev| h4.call(ev) }
            .call

        client.publish(event_3)
        expect(h1.handled_events).to eq([event_1])
        expect(h3.handled_events).to eq([event_2])
        expect(h2.handled_events).to eq([event_1, event_2])
        expect(h4.handled_events).to eq([event_1, event_2])
        expect(result).to eq(:result)
        expect(client.read.to_a).to eq([event_1, event_2, event_3])
      end

      specify "temporary subscriptions don't affect other threads" do
        exchanger = Concurrent::Exchanger.new
        timeout = 3
        h1, h2, h3, h4 = 4.times.map { Subscribers::ValidHandler.new }
        events_count = 20
        thread =
          Thread.new do
            client
              .within do
                exchanger.exchange!("love_marta", timeout)
                events_count.times { client.publish(ProductAdded.new) }
                exchanger.exchange!("love_robert", timeout)
              end
              .subscribe_to_all_events(h3)
              .subscribe(h4, to: ProductAdded)
              .call
          end
        client
          .within do
            exchanger.exchange!("love_marta", timeout)
            events_count.times { client.publish(OrderCreated.new) }
            exchanger.exchange!("love_robert", timeout)
          end
          .subscribe_to_all_events(h1)
          .subscribe(h2, to: OrderCreated)
          .call
        thread.join

        expect(h1.handled_events.count).to eq(events_count)
        expect(h1.handled_events.map(&:class).uniq).to eq([OrderCreated])

        expect(h2.handled_events.count).to eq(events_count)
        expect(h2.handled_events.map(&:class).uniq).to eq([OrderCreated])

        expect(h3.handled_events.count).to eq(events_count)
        expect(h3.handled_events.map(&:class).uniq).to eq([ProductAdded])

        expect(h4.handled_events.count).to eq(events_count)
        expect(h4.handled_events.map(&:class).uniq).to eq([ProductAdded])
      end unless ENV["MUTATING"] == "true"
    end
  end
end
