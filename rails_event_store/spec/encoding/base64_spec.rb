# frozen_string_literal: true

require "spec_helper"
require "base64"

module RailsEventStore
  module Encoding
    ::RSpec.describe Base64::Transformation do
      specify "encodes the encrypted attribute and its iv as base64 on dump" do
        record =
          RubyEventStore::Record.new(
            event_id: "id",
            event_type: "ProfileUpdated",
            data: { user_id: "u1", email: "\xF5\x00\x9a".b },
            metadata: { encryption: { email: { cipher: "aes-256-gcm", iv: "\x01\x02\x03".b, identifier: "u1" } } },
            timestamp: Time.now,
            valid_at: Time.now,
          )

        dumped = Base64::Transformation.new.dump(record)

        expect(dumped.data[:email]).to eq(::Base64.strict_encode64("\xF5\x00\x9a".b))
        expect(dumped.metadata[:encryption][:email][:iv]).to eq(::Base64.strict_encode64("\x01\x02\x03".b))
      end

      specify "load reverses dump for the encrypted attribute and its iv" do
        record =
          RubyEventStore::Record.new(
            event_id: "id",
            event_type: "ProfileUpdated",
            data: { user_id: "u1", email: "\xF5\x00\x9a".b },
            metadata: { encryption: { email: { cipher: "aes-256-gcm", iv: "\x01\x02\x03".b, identifier: "u1" } } },
            timestamp: Time.now,
            valid_at: Time.now,
          )
        transformation = Base64::Transformation.new

        loaded = transformation.load(transformation.dump(record))

        expect(loaded.data[:email]).to eq("\xF5\x00\x9a".b)
        expect(loaded.metadata[:encryption][:email][:iv]).to eq("\x01\x02\x03".b)
      end

      specify "passes the record through untouched when there is no encryption metadata" do
        record =
          RubyEventStore::Record.new(
            event_id: "id",
            event_type: "ProfileUpdated",
            data: { email: "plain" },
            metadata: { correlation_id: "c1" },
            timestamp: Time.now,
            valid_at: Time.now,
          )

        expect(Base64::Transformation.new.dump(record)).to eq(record)
      end

      specify "leaves a nil encrypted attribute as nil" do
        record =
          RubyEventStore::Record.new(
            event_id: "id",
            event_type: "ProfileUpdated",
            data: { user_id: "u1", email: nil },
            metadata: { encryption: { email: { cipher: "aes-256-gcm", iv: "\x01\x02\x03".b, identifier: "u1" } } },
            timestamp: Time.now,
            valid_at: Time.now,
          )

        expect(Base64::Transformation.new.dump(record).data[:email]).to be_nil
      end

      specify "skips an attribute declared in the schema but absent from data" do
        record =
          RubyEventStore::Record.new(
            event_id: "id",
            event_type: "ProfileUpdated",
            data: { user_id: "u1" },
            metadata: { encryption: { email: { cipher: "aes-256-gcm", iv: "\x01\x02\x03".b, identifier: "u1" } } },
            timestamp: Time.now,
            valid_at: Time.now,
          )

        expect(Base64::Transformation.new.dump(record).data).to eq({ user_id: "u1" })
      end

      specify "recurses into nested schema branches" do
        record =
          RubyEventStore::Record.new(
            event_id: "id",
            event_type: "TicketTransferred",
            data: { sender: { name: "\xAA".b } },
            metadata: {
              encryption: {
                sender: {
                  name: { cipher: "aes-256-gcm", iv: "\x09".b, identifier: "u1" },
                },
              },
            },
            timestamp: Time.now,
            valid_at: Time.now,
          )

        dumped = Base64::Transformation.new.dump(record)

        expect(dumped.data[:sender][:name]).to eq(::Base64.strict_encode64("\xAA".b))
        expect(dumped.metadata[:encryption][:sender][:name][:iv]).to eq(::Base64.strict_encode64("\x09".b))
      end

      specify "does not mutate the original record" do
        data = { user_id: "u1", email: "\xF5".b }
        metadata = { encryption: { email: { cipher: "aes-256-gcm", iv: "\x01".b, identifier: "u1" } } }
        record =
          RubyEventStore::Record.new(
            event_id: "id",
            event_type: "ProfileUpdated",
            data: data,
            metadata: metadata,
            timestamp: Time.now,
            valid_at: Time.now,
          )

        Base64::Transformation.new.dump(record)

        expect(data[:email]).to eq("\xF5".b)
        expect(metadata[:encryption][:email][:iv]).to eq("\x01".b)
      end
    end
  end
end
