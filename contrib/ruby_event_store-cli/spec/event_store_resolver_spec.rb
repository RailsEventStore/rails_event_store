# frozen_string_literal: true

require_relative "spec_helper"
require "ruby_event_store/cli/event_store_resolver"

module RubyEventStore
  module CLI
    RSpec.describe EventStoreResolver do
      describe ".resolve" do
        it "returns instance set via initializer without loading environment" do
          fake_store = instance_double(RubyEventStore::Client)
          EventStoreResolver.event_store = fake_store

          expect(EventStoreResolver).not_to receive(:require)
          expect(EventStoreResolver.resolve).to eq(fake_store)
        end
      end

      describe ".find_event_store" do
        it "returns Rails.configuration.event_store when available" do
          fake_store = instance_double(RubyEventStore::Client)
          fake_config = FakeConfiguration.new
          fake_config.event_store = fake_store
          stub_const("Rails", double(configuration: fake_config, respond_to?: true))

          expect(EventStoreResolver.find_event_store).to eq(fake_store)
        end

        it "falls back to EVENT_STORE constant" do
          hide_const("Rails")
          fake_store = instance_double(RubyEventStore::Client)
          stub_const("EVENT_STORE", fake_store)

          expect(EventStoreResolver.find_event_store).to eq(fake_store)
        end

        it "falls back to RES constant" do
          hide_const("Rails")
          fake_store = instance_double(RubyEventStore::Client)
          stub_const("RES", fake_store)

          expect(EventStoreResolver.find_event_store).to eq(fake_store)
        end

        it "returns nil when nothing found" do
          hide_const("Rails")
          EventStoreResolver::CANDIDATE_CONSTS.each { |c| hide_const(c) if Object.const_defined?(c) }

          expect(EventStoreResolver.find_event_store).to be_nil
        end
      end
    end
  end
end
