require 'spec_helper'

module RubyEventStore
  RSpec.describe Subscription do
    class Subscriber
      def initialize(no = 0)
        @no = no
        @event = nil
      end
      attr_reader :event

      def call(event)
        @event = event
      end

      def inspect
        "Subscriber#{@no}"
      end
    end

    it { expect{ Subscription.new(nil) }.to raise_error(SubscriberNotExist, 'subscriber must exists') }

    specify 'subscribe for all event types given' do
      store = InMemorySubscriptionsStore.new
      sub1 = Subscription.new(-> { }, [OrderCreated, ProductAdded], store: store)
      sub2 = Subscription.new(-> { }, [OrderCreated], store: store)
      sub3 = Subscription.new(-> { }, store: store)
      expect(store.all).to match_array [sub1, sub2, sub3]
      expect(store.all_for(OrderCreated)).to eq [sub1, sub2]
      expect(store.all_for(ProductAdded)).to eq [sub1]
      expect(store.all_for(GLOBAL_SUBSCRIPTION)).to eq [sub3]

      expect([sub1, sub2, sub3].map(&:persisted?).uniq).to eq [true]
    end

    specify 'when store not given do not add or delete from it' do
      store = double(:store)
      allow(store).to receive(:nil?).and_return(true)
      expect(store).not_to receive(:add)
      expect(store).not_to receive(:delete)
      sub = Subscription.new(-> { }, store: store)
      sub.unsubscribe
      expect(sub.persisted?).to eq(false)
    end

    specify 'unsubscribe from all event types' do
      store = InMemorySubscriptionsStore.new
      sub1 = Subscription.new(-> { }, [OrderCreated, ProductAdded], store: store)
      sub2 = Subscription.new(-> { }, [OrderCreated], store: store)
      sub3 = Subscription.new(-> { }, store: store)
      expect(store.all).to match_array [sub1, sub2, sub3]

      sub1.unsubscribe
      expect(store.all_for(OrderCreated)).to eq [sub2]
      expect(store.all_for(ProductAdded)).to eq []
      expect(store.all_for(GLOBAL_SUBSCRIPTION)).to eq [sub3]

      sub2.unsubscribe
      expect(store.all_for(OrderCreated)).to eq []
      expect(store.all_for(ProductAdded)).to eq []
      expect(store.all_for(GLOBAL_SUBSCRIPTION)).to eq [sub3]

      sub3.unsubscribe
      expect(store.all_for(OrderCreated)).to eq []
      expect(store.all_for(ProductAdded)).to eq []
      expect(store.all_for(GLOBAL_SUBSCRIPTION)).to eq []
    end

    specify '#global?' do
      sub1 = Subscription.new(-> { }, [OrderCreated, ProductAdded])
      sub2 = Subscription.new(-> { }, [OrderCreated])
      sub3 = Subscription.new(-> { })

      expect(sub1.global?).to eq false
      expect(sub2.global?).to eq false
      expect(sub3.global?).to eq true
    end

    specify '#subscribed_for' do
      sub1 = Subscription.new(-> { }, [OrderCreated, ProductAdded])
      sub2 = Subscription.new(-> { }, [OrderCreated])
      sub3 = Subscription.new(-> { })

      expect(sub1.subscribed_for).to eq [OrderCreated, ProductAdded]
      expect(sub2.subscribed_for).to eq [OrderCreated]
      expect(sub3.subscribed_for).to eq [GLOBAL_SUBSCRIPTION]

      expect { sub1.subscribed_for << [TestEvent] }.to raise_error(RuntimeError)
    end

    specify '#inspect' do
      sub1 = Subscription.new(Subscriber.new(1), [OrderCreated, ProductAdded])
      sub2 = Subscription.new(Subscriber.new(2), [OrderCreated])
      sub3 = Subscription.new(Subscriber.new(3))

      expect(sub1.inspect).to eq <<~EOS.strip
          #<RubyEventStore::Subscription:0x#{sub1.object_id.to_s(16)}>
            - event types: [OrderCreated, ProductAdded]
            - subscriber: Subscriber1
      EOS

      expect(sub2.inspect).to eq <<~EOS.strip
          #<RubyEventStore::Subscription:0x#{sub2.object_id.to_s(16)}>
            - event types: [OrderCreated]
            - subscriber: Subscriber2
      EOS

      expect(sub3.inspect).to eq <<~EOS.strip
          #<RubyEventStore::Subscription:0x#{sub3.object_id.to_s(16)}>
            - global subscription
            - subscriber: Subscriber3
      EOS
    end

    specify '#call' do
      event = RubyEventStore::Event.new

      handler1 = Subscriber.new
      Subscription.new(handler1).call(event)
      expect(handler1.event).to eq(event)

      handler2 = Subscriber.new
      expect(Subscriber).to receive(:new).and_return(handler2)
      Subscription.new(Subscriber).call(event)
      expect(handler2.event).to eq(event)

      result = nil
      Subscription.new(->(e) { result = e }).call(event)
      expect(result).to eq(event)
    end

    specify '#==' do
      subscriber1 = Subscriber.new(1)
      subscriber2 = Subscriber.new(2)
      expect(Subscription.new(subscriber1) == Subscription.new(subscriber1)).to eq true
      expect(Subscription.new(subscriber2) == Subscription.new(subscriber1)).to eq false

      expect(Subscription.new(subscriber1, [OrderCreated]) == Subscription.new(subscriber1, [OrderCreated])).to eq true
      expect(Subscription.new(subscriber1, [OrderCreated, ProductAdded]) == Subscription.new(subscriber1, [OrderCreated])).to eq false
      expect(Subscription.new(subscriber1, [OrderCreated]) == Subscription.new(subscriber1)).to eq false

      klass = Class.new(Subscription)
      expect(klass.new(subscriber1) == Subscription.new(subscriber1)).to eq false
    end

    specify '#hash' do
      subscriber1 = Subscriber.new(1)
      subscriber2 = Subscriber.new(2)
      expect(Subscription.new(subscriber1).hash).to eq(Subscription.new(subscriber1).hash)
      expect(Subscription.new(subscriber2).hash).not_to eq(Subscription.new(subscriber1).hash)

      expect(Subscription.new(subscriber1, [OrderCreated]).hash).to eq(Subscription.new(subscriber1, [OrderCreated]).hash)
      expect(Subscription.new(subscriber1, [OrderCreated, ProductAdded]).hash).not_to eq(Subscription.new(subscriber1, [OrderCreated]).hash)
      expect(Subscription.new(subscriber1, [OrderCreated]).hash).not_to eq(Subscription.new(subscriber1).hash)

      klass = Class.new(Subscription)
      expect(
        klass.new(subscriber1).hash
      ).not_to eq(Subscription.new(subscriber1).hash)
      expect(
        klass.new(subscriber1).hash
      ).to eq(klass.new(subscriber1).hash)

      expect(Subscription.new(subscriber1, [OrderCreated]).hash).not_to eq([
        Subscription,
        [OrderCreated],
        subscriber1
      ].hash)
    end
  end
end
