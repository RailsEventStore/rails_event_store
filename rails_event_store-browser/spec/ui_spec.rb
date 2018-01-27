require 'spec_helper'

FooBarEvent = Class.new(::RailsEventStore::Event)

module RailsEventStore
  RSpec.describe Browser, type: :feature, js: true do
    include SchemaHelper

    before { load_database_schema }

    specify do
      skip("in-memory sqlite cannot run this test") if ENV['DATABASE_URL'].include?(":memory:")

      foo_bar_event = FooBarEvent.new(data: { foo: :bar })
      event_store.publish_event(foo_bar_event, stream_name: 'baz')

      visit('/res')
      within('.browser__results') do
        click_on 'baz'
        click_on 'FooBarEvent'
      end
      within('.event__body') do
        expect(page).to have_content(foo_bar_event.event_id)
        expect(page).to have_content(%Q[{ "timestamp": "#{foo_bar_event.metadata[:timestamp].as_json}" ])
        expect(page).to have_content(%Q[{ "foo": "bar" }])
      end
    end

    def event_store
      Rails.configuration.event_store
    end
  end
end
