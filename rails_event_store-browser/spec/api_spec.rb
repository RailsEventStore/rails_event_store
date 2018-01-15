require 'spec_helper'
require 'active_support/core_ext/hash/keys'
require 'support/json_api_lint'

DummyEvent = Class.new(::RailsEventStore::Event)

module RailsEventStore
  RSpec.describe Browser, type: :request do
    include SchemaHelper

    before { load_database_schema }

    specify do
      event_store.publish_event(dummy_event, stream_name: 'dummy')
      get '/res/streams'

      expect(response).to have_http_status(200)
      expect(parsed_body['data']).to match_array([all_stream_resource, dummy_stream_resource])
    end

    specify do
      event_store.publish_event(dummy_event, stream_name: 'dummy')
      get '/res/streams/all'

      expect(response).to have_http_status(200)
      expect(parsed_body['data']).to match_array([event_resource])

      get '/res/streams/dummy'

      expect(response).to have_http_status(200)
      expect(parsed_body['data']).to match_array([event_resource])
    end

    specify do
      event_store.publish_event(dummy_event, stream_name: 'dummy')
      get "/res/events/#{dummy_event.event_id}"

      expect(response).to have_http_status(200)
      expect(parsed_body['data']).to match(event_resource)
    end

    def dummy_event
      @dummy_event ||=
        DummyEvent.new(data: {
          foo: 1,
          bar: 2.0,
          baz: "3"
        })
    end

    def event_resource
      {
        'id' => dummy_event.event_id,
        'type' => 'events',
        'attributes' => {
          'event_type' => 'DummyEvent',
          'data' => {
            'foo' => 1,
            'bar' => 2.0,
            'baz' => "3"
          },
          'metadata' => {
            'timestamp' => dummy_event.metadata[:timestamp].as_json
          }
        }
      }
    end

    def all_stream_resource
      {
        'id' => 'all',
        'type' => 'streams'
      }
    end

    def dummy_stream_resource
      {
        'id' => 'dummy',
        'type' => 'streams'
      }
    end

    def event_store
      Rails.configuration.event_store
    end

    def parsed_body
      JSON.parse(response.body)
    end

    def get(url, headers: {}, params: {})
      headers['Content-Type'] = 'application/vnd.api+json'
      super(url, headers: headers, params: params)
    end

    def app
      JsonApiLint.new(super)
    end
  end
end