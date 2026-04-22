# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/stream_show"

module RubyEventStore
  module CLI
    module Commands
      class FirstType < RubyEventStore::Event; end
      class LastType < RubyEventStore::Event; end

      RSpec.describe StreamShow do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { StreamShow.new }

        before { EventStoreResolver.event_store = event_store }

        describe "#call" do
          it "shows stream details" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect { command.call(stream_name: "test-stream") }
              .to output(/Events:\s+2/).to_stdout
          end

          it "shows version as count minus one" do
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")
            event_store.publish(RubyEventStore::Event.new, stream_name: "test-stream")

            expect { command.call(stream_name: "test-stream") }
              .to output(/Version:\s+1/).to_stdout
          end

          it "shows first and last event type" do
            event_store.publish(FirstType.new, stream_name: "test-stream")
            event_store.publish(LastType.new, stream_name: "test-stream")

            output = capture_stdout { command.call(stream_name: "test-stream") }
            expect(output).to match(/First:.*FirstType/)
            expect(output).to match(/Last:.*LastType/)
          end

          it "shows zero events for empty stream" do
            expect { command.call(stream_name: "empty-stream") }
              .to output(/Events:\s+0/).to_stdout
          end

          it "shows stream name" do
            expect { command.call(stream_name: "my-stream") }
              .to output(/Stream:\s+my-stream/).to_stdout
          end

          it "does not show version for empty stream" do
            expect { command.call(stream_name: "empty-stream") }
              .not_to output(/Version/).to_stdout
          end
        end

        def capture_stdout
          out = StringIO.new
          $stdout = out
          yield
          out.string
        ensure
          $stdout = STDOUT
        end
      end
    end
  end
end
