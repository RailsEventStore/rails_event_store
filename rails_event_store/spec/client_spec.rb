# frozen_string_literal: true

require "spec_helper"
require "action_controller/railtie"

module RailsEventStore
  ::RSpec.describe Client do
    TestEvent = Class.new(RubyEventStore::Event)

    specify "default repository is built from the serializer seam, so a subclass swaps serialization with a single override" do
      recorded = []
      recording_serializer =
        Module.new do
          define_singleton_method(:dump) do |value|
            recorded << value
            YAML.dump(value)
          end
          define_singleton_method(:load) { |value| YAML.unsafe_load(value) }
        end
      client_class = Class.new(Client) { define_method(:serializer) { recording_serializer } }

      client_class.new.publish(TestEvent.new(data: { foo: "bar" }))

      expect(recorded).to include({ foo: "bar" })
    end

    specify "default serializer restores YAML types that a safe load would reject" do
      client = Client.new

      event = TestEvent.new(data: { scheduled_on: Date.new(2021, 8, 5) })
      client.publish(event)

      expect(client.read.event(event.event_id).data).to eq({ scheduled_on: Date.new(2021, 8, 5) })
    end

    specify "default mapper comes from the default_mapper seam" do
      recorded = []
      recording_mapper =
        Class.new(RubyEventStore::Mappers::BatchMapper) do
          define_method(:events_to_records) do |events|
            recorded.concat(events)
            super(events)
          end
        end
      client_class = Class.new(Client) { define_method(:default_mapper) { recording_mapper.new } }

      event = TestEvent.new
      client_class.new(repository: RubyEventStore::InMemoryRepository.new).publish(event)

      expect(recorded).to eq([event])
    end

    specify "has default request metadata proc if no custom one provided" do
      client = Client.new
      expect(
        client.request_metadata.call(
          { "action_dispatch.request_id" => "dummy_id", "action_dispatch.remote_ip" => "dummy_ip" },
        ),
      ).to eq({ remote_ip: "dummy_ip", request_id: "dummy_id" })
    end

    specify "allows to set custom request metadata proc" do
      client = Client.new(request_metadata: ->(env) { { server_name: env["SERVER_NAME"] } })
      expect(client.request_metadata.call({ "SERVER_NAME" => "example.org" })).to eq({ server_name: "example.org" })
    end

    specify "published event metadata will be enriched by metadata provided in request metadata when executed inside a with_request_metadata block" do
      client = Client.new(repository: RubyEventStore::InMemoryRepository.new)
      event = TestEvent.new
      client.with_request_metadata(
        "action_dispatch.request_id" => "dummy_id",
        "action_dispatch.remote_ip" => "dummy_ip",
      ) { client.publish(event) }
      published = client.read.to_a
      expect(published.size).to eq(1)
      expect(published.first.metadata[:remote_ip]).to eq("dummy_ip")
      expect(published.first.metadata[:request_id]).to eq("dummy_id")
      expect(published.first.metadata[:timestamp]).to be_a Time
    end

    specify "wraps repository into instrumentation" do
      client = Client.new(repository: RubyEventStore::InMemoryRepository.new)

      received_notifications = 0
      ActiveSupport::Notifications.subscribe("append_to_stream.repository.ruby_event_store") do
        received_notifications += 1
      end

      client.publish(TestEvent.new)

      expect(received_notifications).to eq(1)
    end

    specify "wraps mapper into instrumentation" do
      client =
        Client.new(repository: RubyEventStore::InMemoryRepository.new, mapper: RubyEventStore::Mappers::BatchMapper.new)

      received_notifications = 0
      ActiveSupport::Notifications.subscribe("events_to_records.mapper.ruby_event_store") do
        received_notifications += 1
      end

      client.publish(TestEvent.new)

      expect(received_notifications).to eq(1)
    end

    specify "wraps single item mapper into instrumentation" do
      client =
        silence_warnings do
          Client.new(repository: RubyEventStore::InMemoryRepository.new, mapper: RubyEventStore::Mappers::Default.new)
        end

      received_notifications = 0
      ActiveSupport::Notifications.subscribe("event_to_record.mapper.ruby_event_store") { received_notifications += 1 }

      client.publish(TestEvent.new)

      expect(received_notifications).to eq(1)
    end

    specify "#inspect" do
      client = Client.new
      object_id = client.object_id.to_s(16)
      expect(client.inspect).to eq("#<RailsEventStore::Client:0x#{object_id}>")
    end

    specify { expect { Client.new }.not_to output.to_stderr }
  end
end
