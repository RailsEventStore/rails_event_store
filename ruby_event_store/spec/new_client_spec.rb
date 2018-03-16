require 'spec_helper'
require 'time'
require_relative 'mappers/events_pb.rb'

module RubyEventStore
  RSpec.describe NewClient do

    specify 'publish_event returns :ok when success' do
      client = RubyEventStore::NewClient.new(repository: InMemoryRepository.new)
      expect(client.publish_event(TestEvent.new)).to eq(:ok)
    end

    specify 'publish to default stream when not specified' do
      client = RubyEventStore::NewClient.new(repository: InMemoryRepository.new)
      test_event = TestEvent.new
      expect(client.publish_events([test_event])).to eq(:ok)
      expect(client.read_stream_events_forward(GLOBAL_STREAM)).to eq([test_event])
    end

  end
end
