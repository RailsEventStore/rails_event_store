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

        context "when event_store is not set" do
          before { allow(EventStoreResolver).to receive(:require) }

          it "requires config/environment.rb" do
            allow(EventStoreResolver).to receive(:find_event_store).and_return(RubyEventStore::Client.new)

            EventStoreResolver.resolve

            expect(EventStoreResolver).to have_received(:require).with(
              File.expand_path(EventStoreResolver::DEFAULT_REQUIRE_PATH)
            )
          end

          it "returns the event store found after loading environment" do
            store = RubyEventStore::Client.new
            allow(EventStoreResolver).to receive(:find_event_store).and_return(store)

            expect(EventStoreResolver.resolve).to eq(store)
          end

          it "aborts with message listing candidate constants when no store found" do
            allow(EventStoreResolver).to receive(:find_event_store).and_return(nil)

            expect {
              begin
                EventStoreResolver.resolve
              rescue SystemExit
              end
            }.to output(/#{EventStoreResolver::CANDIDATE_CONSTS.join(", ")}/).to_stderr
          end

          it "aborts with message mentioning the require path" do
            allow(EventStoreResolver).to receive(:find_event_store).and_return(nil)

            expect {
              begin
                EventStoreResolver.resolve
              rescue SystemExit
              end
            }.to output(/#{EventStoreResolver::DEFAULT_REQUIRE_PATH}/).to_stderr
          end
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
