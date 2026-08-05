# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Configuration do
    specify { expect(Configuration.new.loaded_defaults).to eq(VERSION) }
    specify { expect(Configuration.new.load_defaults("3.0").loaded_defaults).to eq("3.0") }
    specify { expect(Configuration.new.load_defaults("3.0")).to be_a(Configuration) }
    specify { expect { Configuration.new.load_defaults("2.17.0") }.to raise_error(UnknownDefaults, /"2.17.0"/) }

    describe "3.0 defaults" do
      let(:config) { Configuration.new.load_defaults("3.0") }

      specify { expect(config.build_repository.call).to be_a(InMemoryRepository) }
      specify { expect(config.build_mapper.call).to be_a(Mappers::BatchMapper) }
      specify { expect(config.build_subscriptions.call).to be_a(Subscriptions) }
      specify { expect(config.build_dispatcher.call).to be_a(SyncScheduler) }
      specify { expect(config.build_message_broker.call).to be_a(Broker) }
      specify { expect(config.build_event_type_resolver.call).to be_a(EventTypeResolver) }
      specify { expect(config.clock.call).to be_a(Time) }
      specify { expect(config.correlation_id_generator.call).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/) }

      specify "each call builds a new instance" do
        expect(config.build_repository.call).not_to be(config.build_repository.call)
      end

      specify "message broker is built out of configured subscriptions and dispatcher" do
        dispatcher = ImmediateDispatcher.new(scheduler: SyncScheduler.new)
        subscriptions = Subscriptions.new
        config.build_dispatcher = -> { dispatcher }
        config.build_subscriptions = -> { subscriptions }

        expect(Broker).to receive(:new).with(subscriptions: subscriptions, dispatcher: dispatcher)

        config.build_message_broker.call
      end
    end

    describe "global configuration" do
      around do |example|
        example.call
      ensure
        RubyEventStore.instance_variable_set(:@configuration, Configuration.new)
      end

      specify { expect(RubyEventStore.configuration).to be_a(Configuration) }
      specify { expect(RubyEventStore.configuration).to be(RubyEventStore.configuration) }

      specify do
        RubyEventStore.configure do |config|
          config.load_defaults("3.0")
          config.build_dispatcher = -> { ImmediateDispatcher.new(scheduler: SyncScheduler.new) }
        end

        expect(RubyEventStore.configuration.loaded_defaults).to eq("3.0")
        expect(RubyEventStore.configuration.build_dispatcher.call).to be_a(ImmediateDispatcher)
      end
    end
  end
end
