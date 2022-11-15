require "spec_helper"

FooBarEvent = Class.new(::RubyEventStore::Event)

module RubyEventStore
  RSpec.describe Browser, type: :feature, js: true do
    specify "main view", mutant: false do
      session = Capybara::Session.new(:chrome, app_builder(event_store))

      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: "dummy")

      session.visit("/")

      expect(session).to have_content("Events in all")

      session.click_link "FooBarEvent"

      expect(session).to have_content(foo_bar_event.event_id)
      expect(session).to have_content(
        "timestamp: \"#{foo_bar_event.metadata[:timestamp].iso8601(TIMESTAMP_PRECISION)}\""
      )
      expect(session).to have_content(
        "valid_at: \"#{foo_bar_event.metadata[:valid_at].iso8601(TIMESTAMP_PRECISION)}\""
      )
      expect(session).to have_content("foo: \"bar\"")
    end

    specify "stream view", mutant: false do
      session = Capybara::Session.new(:chrome, app_builder(event_store))

      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: "foo/bar.xml")

      session.visit("/streams/foo%2Fbar.xml")

      expect(session).to have_content("Events in foo/bar.xml")

      session.click_link "FooBarEvent"

      expect(session).to have_content(foo_bar_event.event_id)
      expect(session).to have_content(
        "timestamp: \"#{foo_bar_event.metadata[:timestamp].iso8601(TIMESTAMP_PRECISION)}\""
      )
      expect(session).to have_content(
        "valid_at: \"#{foo_bar_event.metadata[:valid_at].iso8601(TIMESTAMP_PRECISION)}\""
      )
      expect(session).to have_content("foo: \"bar\"")
    end

    specify "Content-Security-Policy", mutant: false do
      session =
        Capybara::Session.new(
          :chrome,
          CspApp.new(
            app_builder(event_store),
            [
              "default-src 'self'",
              "connect-src 'self'",
              "ws://localhost:41221 http://127.0.0.1",
              "script-src 'self'"
            ].join(";")
          )
        )

      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: "dummy")

      session.visit("/")

      expect(session).to have_content("Events in all")
    end

    specify "expect no severe browser warnings", mutant: false do
      session =
        Capybara::Session.new(
          :chrome,
          CspApp.new(
            app_builder(event_store),
            "style-src 'self'; script-src 'self'"
          )
        )

      session.visit("/")

      expect(
        session
          .driver
          .browser
          .manage
          .logs
          .get(:browser)
          .select { |le| le.level == "SEVERE" }
      ).to be_empty
    end

    let(:event_store) do
      RubyEventStore::Client.new(
        repository: RubyEventStore::InMemoryRepository.new
      )
    end

    def app_builder(event_store)
      RubyEventStore::Browser::App.for(event_store_locator: -> { event_store })
    end
  end
end
