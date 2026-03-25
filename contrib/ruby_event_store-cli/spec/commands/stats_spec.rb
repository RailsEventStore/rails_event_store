# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/stats"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe Stats do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { Stats.new }

        before do
          EventStoreResolver.event_store = event_store
          allow(command).to receive(:stream_count).and_return(3)
          allow(command).to receive(:top_event_types).and_return([
            ["OrderPlaced", 10],
            ["PaymentProcessed", 5]
          ])
        end

        describe "#call" do
          it "shows total event count" do
            3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "test") }

            expect { command.call }
              .to output(/Total events:.*3/m).to_stdout
          end

          it "shows stream count" do
            expect { command.call }
              .to output(/Streams:.*3/m).to_stdout
          end

          it "shows top event types" do
            expect { command.call }
              .to output(/OrderPlaced.*10/m).to_stdout
          end

          context "with --stream" do
            it "shows stream event count" do
              3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Orders") }

              expect { command.call(stream: "Orders") }
                .to output(/Events:.*3/m).to_stdout
            end

            it "shows version and first/last for non-empty stream" do
              3.times { event_store.publish(RubyEventStore::Event.new, stream_name: "Orders") }

              expect { command.call(stream: "Orders") }
                .to output(/Version:.*2/m).to_stdout
            end

            it "shows zero count for empty stream" do
              expect { command.call(stream: "empty") }
                .to output(/Events:.*0/m).to_stdout
            end
          end
        end
      end
    end
  end
end
