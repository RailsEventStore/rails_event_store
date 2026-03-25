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
          event_store.publish(
            event,
            stream_name: "$by_correlation_id_#{correlation_id}"
          )
          event_store.with_metadata(
            correlation_id: correlation_id,
            causation_id: causation_id
          ) { event_store.publish(event, stream_name: "test") } if false
          event
        end

        def correlated_event(causation_id: nil)
          meta = { correlation_id: correlation_id }
          meta[:causation_id] = causation_id if causation_id
          RubyEventStore::Event.new(metadata: meta)
        end

        describe "#call" do
          it "shows events for a correlation id" do
            root = correlated_event
            event_store.publish(root, stream_name: "$by_correlation_id_#{correlation_id}")

            expect { command.call(correlation_id: correlation_id) }
              .to output(/#{root.event_id}/).to_stdout
          end

          it "shows total event count" do
            2.times do
              event_store.publish(correlated_event, stream_name: "$by_correlation_id_#{correlation_id}")
            end

            expect { command.call(correlation_id: correlation_id) }
              .to output(/2 event\(s\)/).to_stdout
          end

          it "shows causal tree with children indented" do
            root  = correlated_event
            child = correlated_event(causation_id: root.event_id)
            event_store.publish(root,  stream_name: "$by_correlation_id_#{correlation_id}")
            event_store.publish(child, stream_name: "$by_correlation_id_#{correlation_id}")

            expect { command.call(correlation_id: correlation_id) }
              .to output(/└─/).to_stdout
          end

          it "prints message when correlation stream is empty" do
            expect { command.call(correlation_id: SecureRandom.uuid) }
              .to output(/no events/).to_stdout
          end
        end
      end
    end
  end
end
