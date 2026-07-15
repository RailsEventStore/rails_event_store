# frozen_string_literal: true

require "spec_helper"

FooBarEvent = Class.new(::RubyEventStore::Event)

module RailsEventStore
  ::RSpec.describe HotwireBrowser, :js, type: :feature do
    specify "opens the search dialog with the keyboard shortcut", mutant: false do
      session = Capybara::Session.new(:cuprite, app_builder(event_store))
      session.visit("/")

      expect(session).to have_no_css("dialog[open]")

      session.find("body").send_keys([:control, "k"])

      expect(session).to have_css("dialog[open]")
    rescue Ferrum::BinaryNotFoundError => exc
      skip exc.message
    end

    specify "main view", mutant: false do
      session = Capybara::Session.new(:cuprite, app_builder(event_store))

      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: "dummy")

      session.visit("/")

      expect(session).to have_content("Events in all")

      session.click_link "FooBarEvent"

      expect(session).to have_content(foo_bar_event.event_id)
      expect(session).to have_content(
        "timestamp: \"#{foo_bar_event.metadata[:timestamp].iso8601(RubyEventStore::TIMESTAMP_PRECISION)}\"",
      )
      expect(session).to have_content(
        "valid_at: \"#{foo_bar_event.metadata[:valid_at].iso8601(RubyEventStore::TIMESTAMP_PRECISION)}\"",
      )
      expect(session).to have_content("foo: \"bar\"")
    rescue Ferrum::BinaryNotFoundError => exc
      skip exc.message
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
        "timestamp: \"#{foo_bar_event.metadata[:timestamp].iso8601(RubyEventStore::TIMESTAMP_PRECISION)}\"",
      )
      expect(session).to have_content(
        "valid_at: \"#{foo_bar_event.metadata[:valid_at].iso8601(RubyEventStore::TIMESTAMP_PRECISION)}\"",
      )
      expect(session).to have_content("foo: \"bar\"")
    rescue Ferrum::BinaryNotFoundError => exc
      skip exc.message
    end

    specify "displays timestamps in the browser timezone", mutant: false do
      session = Capybara::Session.new(:cuprite, app_builder(event_store))
      session.driver.browser.page.command("Emulation.setTimezoneOverride", timezoneId: "America/New_York")

      event = TimeEnrichment.with(FooBarEvent.new, timestamp: Time.utc(2020, 1, 1, 5, 0, 0, 0))
      event_store.append(event, stream_name: "dummy")

      session.visit("/events/#{event.event_id}")

      expect(session).to have_content("2020-01-01T00:00:00.000")
    rescue Ferrum::BinaryNotFoundError => exc
      skip exc.message
    end

    specify "falls back to the detected zone when the stored timezone is unsupported", mutant: false do
      session = Capybara::Session.new(:cuprite, app_builder(event_store))
      session.driver.browser.page.command("Emulation.setTimezoneOverride", timezoneId: "America/New_York")

      event = TimeEnrichment.with(FooBarEvent.new, timestamp: Time.utc(2020, 1, 1, 5, 0, 0, 0))
      event_store.append(event, stream_name: "dummy")

      session.visit("/")
      session.execute_script("localStorage.setItem('rails_event_store_hotwire_browser.timezone', 'Not/AZone')")
      session.visit("/events/#{event.event_id}")

      expect(session).to have_content("2020-01-01T00:00:00.000")
    rescue Ferrum::BinaryNotFoundError => exc
      skip exc.message
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
    rescue Ferrum::BinaryNotFoundError => exc
      skip exc.message
    end

    specify "expect no severe browser warnings", mutant: false do
      logger = mk_logger

      Capybara.register_driver(:cuprite_with_logger) do |app|
        Capybara::Cuprite::Driver.new(
          app,
          logger: logger,
          process_timeout: 30,
          browser_options: {
            "no-sandbox" => nil,
          },
        )
      end

      session =
        Capybara::Session.new(
          :cuprite_with_logger,
          CspApp.new(app_builder(event_store), "style-src 'self'; script-src 'self'"),
        )

      session.visit("/")

      expect(logger.messages.select { |m| m["params"]["entry"]["level"] == "error" }).to be_empty
    rescue Ferrum::BinaryNotFoundError => exc
      skip exc.message
    end

    let(:event_store) { RubyEventStore::Client.new }

    def app_builder(event_store)
      TestApplication.config.event_store = event_store
      TestApplication
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
