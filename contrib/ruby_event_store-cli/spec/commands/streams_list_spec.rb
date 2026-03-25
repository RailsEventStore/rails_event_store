# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/streams_list"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe StreamsList do
        let(:command) { StreamsList.new }

        before { EventStoreResolver.event_store = RubyEventStore::Client.new }

        def with_streams(*streams)
          allow(command).to receive(:fetch_streams) do |prefix: nil|
            prefix ? streams.select { |s| s.start_with?(prefix) } : streams
          end
        end

        describe "#call" do
          it "lists all streams" do
            with_streams("Orders", "User-1", "User-2")

            expect { command.call }
              .to output(/Orders.*User-1.*User-2/m).to_stdout
          end

          it "prints count" do
            with_streams("Orders", "User-1", "User-2")

            expect { command.call }
              .to output(/3 stream\(s\)/).to_stdout
          end

          it "filters by prefix" do
            with_streams("User-1", "User-2", "Orders")

            expect { command.call(prefix: "User") }
              .to output(/User-1.*User-2/m).to_stdout
          end

          it "prints filtered count" do
            with_streams("User-1", "User-2", "Orders")

            expect { command.call(prefix: "User") }
              .to output(/2 stream\(s\)/).to_stdout
          end

          it "prints message when no streams" do
            with_streams

            expect { command.call }
              .to output(/no streams/).to_stdout
          end
        end
      end
    end
  end
end
