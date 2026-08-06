# frozen_string_literal: true

require "spec_helper"
require "action_controller/railtie"

module RailsEventStore
  ::RSpec.describe Configuration do
    let(:current) { Gem::Version.new(RubyEventStore::VERSION).segments.take(2).join(".") }

    specify { expect(Configuration.new.loaded_defaults).to eq(current) }
    specify { expect(Configuration.new.load_defaults(RubyEventStore::VERSION).loaded_defaults).to eq(current) }
    specify { expect { Configuration.new.load_defaults("2.17.0") }.to raise_error(RubyEventStore::UnknownDefaults) }

    describe "current defaults" do
      let(:config) { Configuration.new.load_defaults(RubyEventStore::VERSION) }

      specify { expect(config.serializer).to eq(RubyEventStore::Serializers::YAML) }
      specify { expect(config.build_repository.call).to be_a(RubyEventStore::ActiveRecord::EventRepository) }
      specify { expect(config.build_mapper.call).to be_a(RubyEventStore::Mappers::BatchMapper) }
      specify { expect(config.build_subscriptions.call).to be_a(RubyEventStore::InstrumentedSubscriptions) }
      specify { expect(config.build_dispatcher.call).to be_a(RubyEventStore::InstrumentedDispatcher) }
      specify { expect(config.build_message_broker.call).to be_a(RubyEventStore::Broker) }
      specify { expect(config.build_event_type_resolver.call).to be_a(RubyEventStore::EventTypeResolver) }
      specify { expect(config.clock.call).to be_a(Time) }

      specify do
        expect(
          config.request_metadata.call(
            { "action_dispatch.request_id" => "dummy_id", "action_dispatch.remote_ip" => "dummy_ip" },
          ),
        ).to eq({ remote_ip: "dummy_ip", request_id: "dummy_id" })
      end

      specify "serializer is used by repository built out of defaults" do
        config.serializer = JSON

        expect(RubyEventStore::ActiveRecord::EventRepository).to receive(:new).with(serializer: JSON)

        config.build_repository.call
      end

      specify "serializer is used by dispatcher built out of defaults" do
        config.serializer = JSON

        expect(ActiveJobScheduler).to receive(:new).with(serializer: JSON)

        config.build_dispatcher.call
      end

      specify "subscriptions keep subscribers and report adding them" do
        subscriptions = config.build_subscriptions.call
        received_notifications = 0
        ActiveSupport::Notifications.subscribe("add.subscriptions.ruby_event_store") { received_notifications += 1 }

        subscriptions.add_subscription(handler = ->(_) {}, ["SomeEventType"])

        expect(subscriptions.all_for("SomeEventType")).to eq([handler])
        expect(received_notifications).to eq(1)
      end

      specify "dispatcher falls back to synchronous dispatch and reports it" do
        dispatcher = config.build_dispatcher.call
        received_notifications = 0
        ActiveSupport::Notifications.subscribe("call.dispatcher.ruby_event_store") { received_notifications += 1 }

        event = RubyEventStore::Event.new
        received = []
        dispatcher.call(->(published) { received << published }, event, nil)

        expect(received).to eq([event])
        expect(received_notifications).to eq(1)
      end
    end

    describe "global configuration" do
      around do |example|
        RailsEventStore.instance_variable_set(:@configuration, nil)
        example.call
      ensure
        RailsEventStore.instance_variable_set(:@configuration, Configuration.new)
      end

      specify { expect(RailsEventStore.configuration).to be_a(Configuration) }
      specify { expect(RailsEventStore.configuration).to be(RailsEventStore.configuration) }

      specify do
        RailsEventStore.configure do |config|
          config.load_defaults(RubyEventStore::VERSION)
          config.build_repository = -> { RubyEventStore::InMemoryRepository.new }
        end

        expect(RailsEventStore.configuration.loaded_defaults).to eq(current)
        expect(RailsEventStore.configuration.build_repository.call).to be_a(RubyEventStore::InMemoryRepository)
      end
    end
  end
end
