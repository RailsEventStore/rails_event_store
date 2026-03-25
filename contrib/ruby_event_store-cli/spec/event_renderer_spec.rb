# frozen_string_literal: true

require_relative "spec_helper"
require "ruby_event_store/cli/event_renderer"

module RubyEventStore
  module CLI
    class RendererHost
      include EventRenderer
    end

    RSpec.describe EventRenderer do
      let(:host) { RendererHost.new }

      def make_event(event_id: SecureRandom.uuid, type: "OrderPlaced", data: {}, metadata: {})
        double(
          event_id: event_id,
          event_type: type,
          data: data,
          metadata: double(to_h: metadata),
          timestamp: Time.utc(2024, 1, 15, 12, 0, 0)
        )
      end

      describe "#render" do
        it "delegates to render_table for table format" do
          event = make_event
          expect { host.render([event], format: "table") }
            .to output(/EVENT ID/).to_stdout
        end

        it "delegates to render_json for json format" do
          event = make_event
          expect { host.render([event], format: "json") }
            .to output(/event_id/).to_stdout
        end
      end

      describe "#render_table" do
        it "prints header" do
          event = make_event
          expect { host.render_table([event]) }
            .to output(/EVENT ID.*TYPE.*TIMESTAMP/m).to_stdout
        end

        it "prints event id" do
          event = make_event(event_id: "abc-123")
          expect { host.render_table([event]) }
            .to output(/abc-123/).to_stdout
        end

        it "prints event type" do
          event = make_event(type: "OrderPlaced")
          expect { host.render_table([event]) }
            .to output(/OrderPlaced/).to_stdout
        end

        it "prints timestamp" do
          event = make_event
          expect { host.render_table([event]) }
            .to output(/2024-01-15/).to_stdout
        end

        it "prints event count" do
          events = [make_event, make_event]
          expect { host.render_table(events) }
            .to output(/2 event\(s\)/).to_stdout
        end

        it "prints no events message for empty list" do
          expect { host.render_table([]) }
            .to output(/no events/).to_stdout
        end

        it "does not print header for empty list" do
          expect { host.render_table([]) }
            .not_to output(/EVENT ID/).to_stdout
        end
      end

      describe "#render_json" do
        it "prints event_id" do
          event = make_event(event_id: "abc-123")
          expect { host.render_json([event]) }
            .to output(/abc-123/).to_stdout
        end

        it "prints event_type" do
          event = make_event(type: "OrderPlaced")
          expect { host.render_json([event]) }
            .to output(/OrderPlaced/).to_stdout
        end

        it "prints data" do
          event = make_event(data: { order_id: "x" })
          expect { host.render_json([event]) }
            .to output(/order_id/).to_stdout
        end

        it "prints metadata" do
          event = make_event(metadata: { correlation_id: "c" })
          expect { host.render_json([event]) }
            .to output(/correlation_id/).to_stdout
        end

        it "prints timestamp" do
          event = make_event
          expect { host.render_json([event]) }
            .to output(/2024-01-15/).to_stdout
        end

        it "renders valid JSON" do
          event = make_event
          output = capture_stdout { host.render_json([event]) }
          expect { JSON.parse(output) }.not_to raise_error
        end
      end

      describe "#resolve_type" do
        it "returns class for known constant" do
          expect(host.resolve_type("String")).to eq(String)
        end

        it "raises for unknown constant" do
          expect { host.resolve_type("NonExistentClass") }
            .to raise_error(/Unknown event type: NonExistentClass/)
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
