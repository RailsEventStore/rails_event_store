require "spec_helper"

FooBarEvent = Class.new(::RubyEventStore::Event)

module RubyEventStore
  RSpec.describe Browser, type: :feature, js: true do
    before { Capybara.app = app_builder(event_store) }

    specify "main view", mutant: false do
      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: "dummy")

      visit("/")

      expect(page).to have_content("Events in all")

      click_on "FooBarEvent"

      expect(page).to have_content(foo_bar_event.event_id)
      expect(page).to have_content("timestamp: \"#{foo_bar_event.metadata[:timestamp].iso8601(TIMESTAMP_PRECISION)}\"")
      expect(page).to have_content("valid_at: \"#{foo_bar_event.metadata[:valid_at].iso8601(TIMESTAMP_PRECISION)}\"")
      expect(page).to have_content("foo: \"bar\"")
    end

    specify "stream view", mutant: false do
      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: "foo/bar.xml")

      visit("/streams/foo%2Fbar.xml")

      expect(page).to have_content("Events in foo/bar.xml")

      click_on "FooBarEvent"

      expect(page).to have_content(foo_bar_event.event_id)
      expect(page).to have_content("timestamp: \"#{foo_bar_event.metadata[:timestamp].iso8601(TIMESTAMP_PRECISION)}\"")
      expect(page).to have_content("valid_at: \"#{foo_bar_event.metadata[:valid_at].iso8601(TIMESTAMP_PRECISION)}\"")
      expect(page).to have_content("foo: \"bar\"")
    end

    specify "Content-Security-Policy", mutant: false do
      class CspApp < Struct.new(:app)
        def call(env)
          status, headers, response = app.call(env)

          headers["Content-Security-Policy"] =
            "default-src 'self'; connect-src 'self' ws://localhost:41221 http://127.0.0.1; script-src 'self'"
          [status, headers, response]
        end
      end

      Capybara.app = CspApp.new(app_builder(event_store))

      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish(foo_bar_event, stream_name: "dummy")

      visit("/")

      expect(page).to have_content("Events in all")
    end

    let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }

    def app_builder(event_store)
      Rack::Lint.new(RubyEventStore::Browser::App.for(event_store_locator: -> { event_store }, environment: :test))
    end
  end
end
