require 'spec_helper'

module RailsEventStore
  RSpec.describe Client do
    TestEvent = Class.new(RailsEventStore::Event)

    specify 'has default request metadata proc if no custom one provided' do
      client = Client.new
      expect(client.request_metadata.call({
        'action_dispatch.request_id' => 'dummy_id',
        'action_dispatch.remote_ip'  => 'dummy_ip'
      })).to eq({
        remote_ip: 'dummy_ip',
        request_id: 'dummy_id'
      })
    end

    specify 'allows to set custom request metadata proc' do
      client = Client.new(
        request_metadata: -> env { {server_name: env['SERVER_NAME']} }
      )
      expect(client.request_metadata.call({
        'SERVER_NAME' => 'example.org'
      })).to eq({
        server_name: 'example.org'
      })
    end

    specify 'published event metadata will be enriched by metadata provided in request metadata when executed inside a with_request_metadata block' do
      client = Client.new(
        repository: InMemoryRepository.new,
      )
      event = TestEvent.new
      client.with_request_metadata(
        'action_dispatch.request_id' => 'dummy_id',
        'action_dispatch.remote_ip'  => 'dummy_ip'
      ) do
        client.publish_event(event)
      end
      published = client.read.each.to_a
      expect(published.size).to eq(1)
      expect(published.first.metadata[:remote_ip]).to eq('dummy_ip')
      expect(published.first.metadata[:request_id]).to eq('dummy_id')
      expect(published.first.metadata[:timestamp]).to be_a Time
    end
  end
end
