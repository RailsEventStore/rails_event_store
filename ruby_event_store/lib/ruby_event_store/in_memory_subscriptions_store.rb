module RubyEventStore
  class InMemorySubscriptionsStore
    def initialize
      @subscriptions = Hash.new {|hsh, key| hsh[key] = [] }
    end

    def add(subscription, type = nil)
      @subscriptions[type.to_s] << subscription
    end

    def delete(subscription, type = nil)
      @subscriptions.fetch(type.to_s).delete(subscription)
    end

    def all_for(event_type)
      @subscriptions[event_type.to_s]
    end

    def all_global
      all_for(nil)
    end

    def value
      self
    end
  end
end
