# frozen_string_literal: true

require "spec_helper"
require "json"

module RailsEventStore
  ::RSpec.describe "module composition of clients" do
    ProfileUpdated =
      Class.new(RubyEventStore::Event) do
        def self.encryption_schema
          { email: ->(data) { data.fetch(:user_id) } }
        end
      end
    PlainEvent = Class.new(RubyEventStore::Event)

    specify "encryption composes on top of the default YAML client, a combination no inheritance chain expresses" do
      key_repository = RubyEventStore::Mappers::InMemoryEncryptionKeyRepository.new
      user_id = SecureRandom.uuid
      key_repository.create(user_id)
      client_class = Class.new(Client) { prepend Encryption }
      client = client_class.new(key_repository: key_repository)

      event = ProfileUpdated.new(data: { user_id: user_id, email: "bob@secret" })
      client.publish(event)

      expect(client.read.event(event.event_id).data[:email]).to eq("bob@secret")
      raw = ActiveRecord::Base.connection.select_value("select data from event_store_events")
      expect(raw).not_to include("bob@secret")
    end

    specify "Base64 encoding bridges encryption and JSON so ciphertext is stored as valid JSON" do
      key_repository = RubyEventStore::Mappers::InMemoryEncryptionKeyRepository.new
      user_id = SecureRandom.uuid
      key_repository.create(user_id)
      client_class =
        Class.new(Client) do
          include Serialization::JSON
          include Encoding::Base64
          prepend Encryption
        end
      client = client_class.new(key_repository: key_repository)

      event = ProfileUpdated.new(data: { user_id: user_id, email: "dave@secret" })
      client.publish(event)

      expect(client.read.event(event.event_id).data[:email]).to eq("dave@secret")
      raw = ActiveRecord::Base.connection.select_value("select data from event_store_events")
      expect { ::JSON.parse(raw) }.not_to raise_error
      expect(raw).not_to include("dave@secret")
    end

    specify "two transformation modules compose in include order onto the same client" do
      first = Module.new { private def transformations = [marker(:first), *super] }
      second = Module.new { private def transformations = [marker(:second), *super] }
      marker =
        Class.new do
          def initialize(name) = @name = name
          def dump(record) = record.with(metadata: record.metadata.merge(@name => true))
          def load(record) = record
        end
      client_class =
        Class.new(Client) do
          include first
          include second
          define_method(:marker) { |name| marker.new(name) }
        end
      client = client_class.new(repository: RubyEventStore::InMemoryRepository.new)

      event = PlainEvent.new
      client.publish(event)

      expect(client.read.event(event.event_id).metadata.to_h).to include(first: true, second: true)
    end

    specify "Encryption#initialize threads the remaining keyword arguments through to the client" do
      key_repository = RubyEventStore::Mappers::InMemoryEncryptionKeyRepository.new
      clock = -> { Time.utc(2021, 8, 5, 12, 0, 0) }
      client_class = Class.new(Client) { prepend Encryption }
      client =
        client_class.new(key_repository: key_repository, clock: clock, repository: RubyEventStore::InMemoryRepository.new)

      event = PlainEvent.new
      client.publish(event)

      expect(client.read.event(event.event_id).metadata[:timestamp]).to eq(Time.utc(2021, 8, 5, 12, 0, 0))
    end
  end
end
