require "spec_helper"

module RubyEventStore
  RSpec.describe Client do
    specify do
      expect {
        RubyEventStore::Client.new(
          message_broker:
            RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::Dispatcher.new,
            ),
        )
      }.not_to output(<<~EOS).to_stderr
          Passing subscriptions and dispatcher to RubyEventStore::Client has been deprecated.

          Pass it using message_broker argument. For example:

          event_store = RubyEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::Dispatcher.new
            )
          )
      EOS
    end
    specify do
      expect {
        RubyEventStore::Client.new(
          subscriptions: RubyEventStore::Subscriptions.new,
          message_broker:
            RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::Dispatcher.new,
            ),
        )
      }.to output(<<~EOS).to_stderr
          Passing subscriptions and dispatcher to RubyEventStore::Client has been deprecated.

          Pass it using message_broker argument. For example:

          event_store = RubyEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::Dispatcher.new
            )
          )

          Because message_broker has been provided,
          arguments passed by subscriptions or dispatcher will be ignored.
      EOS
    end

    specify do
      expect { RubyEventStore::Client.new(subscriptions: RubyEventStore::Subscriptions.new) }.to output(
        <<~EOS,
          Passing subscriptions and dispatcher to RubyEventStore::Client has been deprecated.

          Pass it using message_broker argument. For example:

          event_store = RubyEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::Dispatcher.new
            )
          )
      EOS
      ).to_stderr
    end

    specify do
      expect { RubyEventStore::Client.new(dispatcher: RubyEventStore::Dispatcher.new) }.to output(<<~EOS).to_stderr
          Passing subscriptions and dispatcher to RubyEventStore::Client has been deprecated.

          Pass it using message_broker argument. For example:

          event_store = RubyEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::Dispatcher.new
            )
          )
      EOS
    end

    specify { expect { RubyEventStore::Client.new(mapper: Mappers::Default.new) }.to output(<<~EOS).to_stderr }
        Mappers that process items one by one are deprecated.
        Wrap your mapper with BatchMapper:
          RubyEventStore::Mappers::BatchMapper.new(mapper)
        or implement mapper that process items in batches.
      EOS
  end
end
