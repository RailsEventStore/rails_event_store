# frozen_string_literal: true

require "spec_helper"

FooBarEvent = Class.new(::RubyEventStore::Event)

module RubyEventStore
  ::RSpec.describe Browser, :js, type: :feature do
    specify "main view", mutant: false do
      session = Capybara::Session.new(:cuprite, app_builder(event_store))

      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: "dummy")

      session.visit("/")

      expect(session).to have_content("Events in all")

      session.click_link "FooBarEvent"

      expect(session).to have_content(foo_bar_event.event_id)
      expect(session).to have_content(
        "timestamp: \"#{foo_bar_event.metadata[:timestamp].iso8601(TIMESTAMP_PRECISION)}\"",
      )
      expect(session).to have_content("valid_at: \"#{foo_bar_event.metadata[:valid_at].iso8601(TIMESTAMP_PRECISION)}\"")
      expect(session).to have_content("foo: \"bar\"")
    end

    specify "stream view", mutant: false do
      session = Capybara::Session.new(:cuprite, app_builder(event_store))

      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: "foo/bar.xml")

      session.visit("/streams/foo%2Fbar.xml")

      expect(session).to have_content("Events in foo/bar.xml")

      session.click_link "FooBarEvent"

      expect(session).to have_content(foo_bar_event.event_id)
      expect(session).to have_content(
        "timestamp: \"#{foo_bar_event.metadata[:timestamp].iso8601(TIMESTAMP_PRECISION)}\"",
      )
      expect(session).to have_content("valid_at: \"#{foo_bar_event.metadata[:valid_at].iso8601(TIMESTAMP_PRECISION)}\"")
      expect(session).to have_content("foo: \"bar\"")
    end

    specify "Content-Security-Policy", mutant: false do
      session =
        Capybara::Session.new(
          :cuprite,
          CspApp.new(
            app_builder(event_store),
            [
              "default-src 'self'",
              "connect-src 'self'",
              "ws://localhost:41221 http://127.0.0.1",
              "script-src 'self'",
            ].join(";"),
          ),
        )

      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: "dummy")

      session.visit("/")

      expect(session).to have_content("Events in all")
    end

    specify "expect no severe browser warnings", mutant: false do
      logger = mk_logger

      Capybara.register_driver(:cuprite_with_logger) do |app|
        Capybara::Cuprite::Driver.new(app, logger: logger, browser_options: { "no-sandbox" => nil })
      end

      session =
        Capybara::Session.new(
          :cuprite_with_logger,
          CspApp.new(app_builder(event_store), "style-src 'self'; script-src 'self'"),
        )

      session.visit("/")

      expect(logger.messages.select { |m| m["params"]["entry"]["level"] == "error" }).to be_empty
    end

    let(:event_store) { Client.new }

    def app_builder(event_store)
      Browser::App.for(event_store_locator: -> { event_store })
    end

    def mk_logger
      Class
        .new do
          attr_reader :messages

          def initialize
            @messages = []
          end

          def puts(message)
            _, _, body = message.strip.split(" ", 3)
            return unless body

            body = JSON.parse(body)
            @messages << body if body["method"] == "Log.entryAdded"
          end
        end
        .new
    end
  end
end
