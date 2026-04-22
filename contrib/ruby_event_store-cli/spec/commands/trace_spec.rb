# frozen_string_literal: true

require_relative "../spec_helper"
require "ruby_event_store/cli/commands/trace"

module RubyEventStore
  module CLI
    module Commands
      RSpec.describe Trace do
        let(:event_store) { RubyEventStore::Client.new }
        let(:command) { Trace.new }
        let(:correlation_id) { SecureRandom.uuid }

        before { EventStoreResolver.event_store = event_store }

        def publish_correlated(event, causation_id: nil)
          meta = { correlation_id: correlation_id }
          meta[:causation_id] = causation_id if causation_id
          event_store.with_metadata(meta) { event_store.publish(event, stream_name: "test") }
          event_store.link(event.event_id, stream_name: "$by_correlation_id_#{correlation_id}")
          event
        end

        describe "#call" do
          it "prints message when no events found" do
            expect { command.call(correlation_id: SecureRandom.uuid) }
              .to output(/no events found/).to_stdout
          end

          it "shows root event" do
            e1 = publish_correlated(RubyEventStore::Event.new)

            expect { command.call(correlation_id: correlation_id) }
              .to output(/#{e1.event_id}/).to_stdout
          end

          it "shows event types" do
            publish_correlated(RubyEventStore::Event.new)

            expect { command.call(correlation_id: correlation_id) }
              .to output(/RubyEventStore::Event/).to_stdout
          end

          it "shows child event indented under parent" do
            e1 = publish_correlated(RubyEventStore::Event.new)
            e2 = publish_correlated(RubyEventStore::Event.new, causation_id: e1.event_id)

            output = capture_stdout { command.call(correlation_id: correlation_id) }
            e1_line = output.lines.index { |l| l.include?(e1.event_id) }
            e2_line = output.lines.index { |l| l.include?(e2.event_id) }
            expect(e1_line).to be < e2_line
            expect(output.lines[e2_line]).to include("└──")
          end

          it "shows multiple root events when no causal relation" do
            e1 = publish_correlated(RubyEventStore::Event.new)
            e2 = publish_correlated(RubyEventStore::Event.new)

            output = capture_stdout { command.call(correlation_id: correlation_id) }
            expect(output).to include(e1.event_id)
            expect(output).to include(e2.event_id)
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
