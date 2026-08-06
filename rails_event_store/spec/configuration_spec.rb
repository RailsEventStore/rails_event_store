# frozen_string_literal: true

require "spec_helper"
require "action_controller/railtie"
require "ostruct"

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

    describe "json variant" do
      let(:config) { Configuration.new(:json).load_defaults(RubyEventStore::VERSION) }

      specify { expect(Configuration.new.variant).to be_nil }
      specify { expect(config.variant).to eq(:json) }

      specify "repository serializes to JSON no matter the configured serializer" do
        config.serializer = RubyEventStore::Serializers::YAML

        expect(RubyEventStore::ActiveRecord::EventRepository).to receive(:new).with(serializer: JSON)

        config.build_repository.call
      end

      specify "mapper preserves types data would lose in JSON" do
        event = DummyEvent.new(data: { date: Date.new(2021, 8, 5) }, metadata: { key: "value" })

        record = dumped(event)

        expect(record.data).to eql({ "date" => "2021-08-05" })
        expect(record.metadata[:types]).to eq(
          { data: { date: %w[Symbol Date] }, metadata: { key: %w[Symbol String] } },
        )
      end

      specify "a variant which is not :json gets the ordinary defaults" do
        other = Configuration.new(:something_else).load_defaults(RubyEventStore::VERSION)
        other.serializer = RubyEventStore::Serializers::YAML

        expect(RubyEventStore::ActiveRecord::EventRepository).to receive(:new).with(
          serializer: RubyEventStore::Serializers::YAML,
        )

        other.build_repository.call

        record = other.build_mapper.call.events_to_records([event(date: Date.new(2021, 8, 5))]).first
        expect(record.data).to eql({ date: Date.new(2021, 8, 5) })
        expect(record.metadata).not_to have_key(:types)
      end

      specify "mapper of the default variant leaves types alone" do
        event = DummyEvent.new(data: { date: Date.new(2021, 8, 5) })

        record = Configuration.new.build_mapper.call.events_to_records([event]).first

        expect(record.data).to eq({ date: Date.new(2021, 8, 5) })
        expect(record.metadata).not_to have_key(:types)
      end

      describe "types the mapper stores and reads back" do
        specify "Symbol" do
          expect(dumped(event(a_symbol: :value)).data).to eql({ "a_symbol" => "value" })
          expect(roundtripped(event(a_symbol: :value)).data).to eq({ a_symbol: :value })
        end

        specify "Time" do
          time = Time.utc(2021, 8, 5, 12, 0, 0, 123456)

          expect(dumped(event(a_time: time)).data).to eql({ "a_time" => "2021-08-05T12:00:00.123456Z" })
          expect(roundtripped(event(a_time: time)).data).to eql({ a_time: time })
        end

        specify "ActiveSupport::TimeWithZone" do
          time_zone = Time.zone
          Time.zone = "Europe/Warsaw"
          time = Time.utc(2021, 8, 5, 12, 0, 0, 123456).in_time_zone

          record = dumped(event(a_time_with_zone: time))

          expect(record.data).to eql({ "a_time_with_zone" => "2021-08-05T14:00:00.123456+02:00" })
          expect(record.metadata[:types][:data]).to eq({ a_time_with_zone: %w[Symbol ActiveSupport::TimeWithZone] })

          read = roundtripped(event(a_time_with_zone: time)).data.fetch(:a_time_with_zone)
          expect(read).to be_a(ActiveSupport::TimeWithZone)
          expect(read).to eq(time)
        ensure
          Time.zone = time_zone
        end

        specify "Date" do
          date = Date.new(2021, 8, 5)

          expect(dumped(event(a_date: date)).data).to eql({ "a_date" => "2021-08-05" })
          expect(roundtripped(event(a_date: date)).data).to eql({ a_date: date })
        end

        specify "DateTime" do
          datetime = DateTime.new(2021, 8, 5, 12, 0, 0)

          expect(dumped(event(a_datetime: datetime)).data).to eql({ "a_datetime" => "2021-08-05T12:00:00+00:00" })
          expect(roundtripped(event(a_datetime: datetime)).data).to eql({ a_datetime: datetime })
        end

        specify "BigDecimal" do
          expect(dumped(event(money: BigDecimal("123.45"))).data).to eql({ "money" => "123.45" })
          expect(roundtripped(event(money: BigDecimal("123.45"))).data).to eq({ money: BigDecimal("123.45") })
        end

        specify "OpenStruct" do
          expect(dumped(DummyEvent.new(data: OpenStruct.new(a: 1))).data).to eq({ a: 1 })
          expect(roundtripped(DummyEvent.new(data: OpenStruct.new(a: 1))).data).to eq(OpenStruct.new(a: 1))
        end

        specify "metadata keys come back as symbols" do
          record = dumped(DummyEvent.new(data: {}, metadata: { a_key: "value" }))
          record = RubyEventStore::Record.new(**record.to_h.merge(metadata: deep_stringify(record.metadata)))

          expect(read(record).metadata[:a_key]).to eq("value")
        end
      end

      def mapper = config.build_mapper.call

      def event(data) = DummyEvent.new(data: data)

      def dumped(event) = mapper.events_to_records([event]).first

      def read(record) = mapper.records_to_events([record]).first

      def roundtripped(event) = read(dumped(event))

      def deep_stringify(hash)
        hash.to_h { |key, value| [key.to_s, value.is_a?(Hash) ? deep_stringify(value) : value] }
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
      specify { expect(RailsEventStore.configuration.variant).to be_nil }
      specify { expect(RailsEventStore.configuration(:json).variant).to eq(:json) }

      specify "configure yields the configuration" do
        yielded = nil
        RailsEventStore.configure { |config| yielded = config }

        expect(yielded).to be(RailsEventStore.configuration)
        expect(yielded.variant).to be_nil
      end

      specify "configure yields the configuration of the variant it was asked for" do
        yielded = nil
        RailsEventStore.configure(:json) { |config| yielded = config }

        expect(yielded).to be(RailsEventStore.configuration(:json))
        expect(yielded.variant).to eq(:json)
      end

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
