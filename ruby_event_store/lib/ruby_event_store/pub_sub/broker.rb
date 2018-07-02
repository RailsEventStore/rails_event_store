require 'concurrent'

module RubyEventStore
  module PubSub
    class Broker
      def initialize
        @local  = Local.new
        @global = Global.new
        @thread  = Thread.new
      end
      attr_reader :local, :global, :thread

      def all_subscribers_for(event_type)
        [local, global, thread].map{|r| r.all(event_type)}.reduce(&:+)
      end

      private

      class Thread
        def initialize
          @local  = ThreadLocal.new
          @global = ThreadGlobal.new
        end
        attr_reader :local, :global

        def all(event_type)
          [global, local].map{|r| r.all(event_type)}.reduce(&:+)
        end
      end

      class Local
        def initialize
          @subscribers = Hash.new {|hsh, key| hsh[key] = [] }
        end

        def add(subscriber, event_types)
          event_types.each{ |type| @subscribers[type.to_s] << subscriber }
          ->() {event_types.each{ |type| @subscribers.fetch(type.to_s).delete(subscriber) } }
        end

        def all(event_type)
          @subscribers[event_type]
        end
      end

      class Global
        def initialize
          @subscribers = []
        end

        def add(subscriber)
          @subscribers << subscriber
          ->() { @subscribers.delete(subscriber) }
        end

        def all(_event_type)
          @subscribers
        end
      end

      class ThreadLocal
        def initialize
          @subscribers = Concurrent::ThreadLocalVar.new do
            Hash.new {|hsh, key| hsh[key] = [] }
          end
        end

        def add(subscriber, event_types)
          event_types.each{ |type| @subscribers.value[type.to_s] << subscriber }
          ->() {event_types.each{ |type| @subscribers.value.fetch(type.to_s).delete(subscriber) } }
        end

        def all(event_type)
          @subscribers.value[event_type]
        end
      end

      class ThreadGlobal
        def initialize
          @subscribers = Concurrent::ThreadLocalVar.new([])
        end

        def add(subscriber)
          @subscribers.value += [subscriber]
          ->() { @subscribers.value -= [subscriber] }
        end

        def all(_event_type)
          @subscribers.value
        end
      end
    end
  end
end
