module RubyEventStore
  module PubSub
    def self.const_missing(const_name)
      if const_name.equal?(:Subscriptions)
        warn "`RubyEventStore::PubSub::Subscriptions` has been deprecated. Use `RubyEventStore::Subscriptions` instead."

        Subscriptions
      elsif const_name.equal?(:Broker)
        warn "`RubyEventStore::PubSub::Broker` has been deprecated. Use `RubyEventStore::Broker` instead."

        Broker
      elsif const_name.equal?(:Dispatcher)
        warn "`RubyEventStore::PubSub::Dispatcher` has been deprecated. Use `RubyEventStore::Dispatcher` instead."

        Dispatcher
      else
        super
      end
    end
  end
end
