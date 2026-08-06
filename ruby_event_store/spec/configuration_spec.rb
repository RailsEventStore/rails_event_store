# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Configuration do
    let(:current) { Gem::Version.new(VERSION).segments.take(2).join(".") }

    specify { expect(Configuration.new.loaded_defaults).to eq(current) }
    specify { expect(Configuration.new.load_defaults(VERSION)).to be_a(Configuration) }
    specify { expect { Configuration.new.load_defaults("2.17.0") }.to raise_error(UnknownDefaults, /"2.17.0"/) }
    specify { expect(Configuration.new.variant).to be_nil }
    specify { expect(Configuration.new(:json).variant).to eq(:json) }

    describe "version without defaults of its own" do
      specify "loads the ones of the last version which changed them" do
        expect(Configuration.new.load_defaults("99.9.9").loaded_defaults).to eq(current)
      end

      specify "patch versions never change the defaults" do
        major, minor = Gem::Version.new(VERSION).segments

        expect(Configuration.new.load_defaults("#{major}.#{minor}.99").loaded_defaults).to eq(current)
      end

      specify "version older than any known defaults is rejected" do
        expect { Configuration.new.load_defaults("0.1.0") }.to raise_error(UnknownDefaults)
      end
    end

    describe "current defaults" do
      let(:config) { Configuration.new.load_defaults(VERSION) }

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
        RubyEventStore.instance_variable_set(:@configuration, nil)
        example.call
      ensure
        RubyEventStore.instance_variable_set(:@configuration, Configuration.new)
      end

      specify { expect(RubyEventStore.configuration).to be_a(Configuration) }
      specify { expect(RubyEventStore.configuration).to be(RubyEventStore.configuration) }
      specify { expect(RubyEventStore.configuration.variant).to be_nil }
      specify { expect(RubyEventStore.configuration(:json).variant).to eq(:json) }

      specify do
        RubyEventStore.configure do |config|
          config.load_defaults(VERSION)
          config.build_dispatcher = -> { ImmediateDispatcher.new(scheduler: SyncScheduler.new) }
        end

        expect(RubyEventStore.configuration.loaded_defaults).to eq(current)
        expect(RubyEventStore.configuration.build_dispatcher.call).to be_a(ImmediateDispatcher)
      end
    end
  end
end
