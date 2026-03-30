require "spec_helper"

RSpec.describe RailsEventStore do
  specify "deprecated constant returns the RubyEventStore equivalent" do
    expect(RailsEventStore::Event).to eq(RubyEventStore::Event)
  end

  specify "deprecated constant warns with message pointing to RubyEventStore" do
    expect { RailsEventStore::Event }.to output(<<~EOW).to_stderr
      RailsEventStore::Event is deprecated and will be removed in the next major release.

      Use RubyEventStore::Event instead.
    EOW
  end

  specify "unknown constant raises NameError" do
    expect { RailsEventStore::NonExistentConstant }.to raise_error(NameError)
  end
end

module RailsEventStore
  RSpec.describe Client do
    specify do
      expect {
        RailsEventStore::Client.new(
          message_broker:
            RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::SyncScheduler.new,
            ),
        )
      }.not_to output(<<~EOS).to_stderr
          Passing subscriptions and dispatcher to RailsEventStore::Client has been deprecated.

          Pass it using message_broker argument. For example:

          event_store = RailsEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::ComposedDispatcher.new(
                RailsEventStore::AfterCommitDispatcher.new(
                  scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML)
                ),
                RubyEventStore::SyncScheduler.new
              )
            )
          )
      EOS
    end
    specify do
      expect {
        RailsEventStore::Client.new(
          subscriptions: RubyEventStore::Subscriptions.new,
          message_broker:
            RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::SyncScheduler.new,
            ),
        )
      }.to output(<<~EOS).to_stderr
          Passing subscriptions and dispatcher to RailsEventStore::Client has been deprecated.

          Pass it using message_broker argument. For example:

          event_store = RailsEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::ComposedDispatcher.new(
                RailsEventStore::AfterCommitDispatcher.new(
                  scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML)
                ),
                RubyEventStore::SyncScheduler.new
              )
            )
          )

          Because message_broker has been provided,
          arguments passed by subscriptions or dispatcher will be ignored.
      EOS
    end

    specify do
      expect { RailsEventStore::Client.new(subscriptions: RubyEventStore::Subscriptions.new) }.to output(
        <<~EOS,
          Passing subscriptions and dispatcher to RailsEventStore::Client has been deprecated.

          Pass it using message_broker argument. For example:

          event_store = RailsEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::ComposedDispatcher.new(
                RailsEventStore::AfterCommitDispatcher.new(
                  scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML)
                ),
                RubyEventStore::SyncScheduler.new
              )
            )
          )
      EOS
      ).to_stderr
    end

    specify do
      expect { RailsEventStore::Client.new(dispatcher: RubyEventStore::SyncScheduler.new) }.to output(<<~EOS).to_stderr
          Passing subscriptions and dispatcher to RailsEventStore::Client has been deprecated.

          Pass it using message_broker argument. For example:

          event_store = RailsEventStore::Client.new(
            message_broker: RubyEventStore::Broker.new(
              subscriptions: RubyEventStore::Subscriptions.new,
              dispatcher: RubyEventStore::ComposedDispatcher.new(
                RailsEventStore::AfterCommitDispatcher.new(
                  scheduler: RailsEventStore::ActiveJobScheduler.new(serializer: RubyEventStore::Serializers::YAML)
                ),
                RubyEventStore::SyncScheduler.new
              )
            )
          )
      EOS
    end
  end
end
