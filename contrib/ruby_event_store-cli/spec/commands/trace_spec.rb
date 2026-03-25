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

        def correlated_event(causation_id: nil)
          meta = { correlation_id: correlation_id }
          meta[:causation_id] = causation_id if causation_id
          RubyEventStore::Event.new(metadata: meta)
        end

        def publish_to_correlation_stream(event)
          event_store.publish(event, stream_name: "$by_correlation_id_#{correlation_id}")
        end

        describe "#call" do
          it "shows events for a correlation id" do
            root = correlated_event
            publish_to_correlation_stream(root)

            expect {
              begin
                command.call(correlation_id: correlation_id)
              rescue SystemExit
              end
            }.to output(/#{root.event_id}/).to_stdout
          end

          it "shows total event count" do
            2.times { publish_to_correlation_stream(correlated_event) }

            expect {
              begin
                command.call(correlation_id: correlation_id)
              rescue SystemExit
              end
            }.to output(/2 event\(s\)/).to_stdout
          end

          it "shows the correlation id in header" do
            publish_to_correlation_stream(correlated_event)

            expect {
              begin
                command.call(correlation_id: correlation_id)
              rescue SystemExit
              end
            }.to output(/Trace: #{correlation_id}/).to_stdout
          end

          it "shows event type in tree" do
            event = correlated_event
            publish_to_correlation_stream(event)

            expect {
              begin
                command.call(correlation_id: correlation_id)
              rescue SystemExit
              end
            }.to output(/RubyEventStore::Event/).to_stdout
          end

          it "shows causal tree with children indented" do
            root  = correlated_event
            child = correlated_event(causation_id: root.event_id)
            publish_to_correlation_stream(root)
            publish_to_correlation_stream(child)

            expect {
              begin
                command.call(correlation_id: correlation_id)
              rescue SystemExit
              end
            }.to output(/└─/).to_stdout
          end

          it "shows grandchild at deeper indent" do
            root       = correlated_event
            child      = correlated_event(causation_id: root.event_id)
            grandchild = correlated_event(causation_id: child.event_id)
            publish_to_correlation_stream(root)
            publish_to_correlation_stream(child)
            publish_to_correlation_stream(grandchild)

            expect {
              begin
                command.call(correlation_id: correlation_id)
              rescue SystemExit
              end
            }.to output(/#{grandchild.event_id}/).to_stdout
          end

          it "shows root event without indent" do
            root = correlated_event
            publish_to_correlation_stream(root)

            output = capture_stdout {
              begin
                command.call(correlation_id: correlation_id)
              rescue SystemExit
              end
            }
            expect(output).to match(/^RubyEventStore::Event/)
          end

          it "shows child event with indent marker" do
            root  = correlated_event
            child = correlated_event(causation_id: root.event_id)
            publish_to_correlation_stream(root)
            publish_to_correlation_stream(child)

            output = capture_stdout {
              begin
                command.call(correlation_id: correlation_id)
              rescue SystemExit
              end
            }
            expect(output).to match(/^└─ RubyEventStore::Event/)
          end

          it "prints message when correlation stream is empty" do
            expect {
              begin
                command.call(correlation_id: SecureRandom.uuid)
              rescue SystemExit
              end
            }.to output(/no events/).to_stdout
          end
        end

        def capture_stdout
          old = $stdout
          $stdout = StringIO.new
          yield
          $stdout.string
        ensure
          $stdout = old
        end
      end
    end
  end
end
