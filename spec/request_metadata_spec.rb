require 'spec_helper'
require 'support/test_rails'

module RailsEventStore
  UUID_REGEX = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/

  RSpec.describe Client do

    let(:dummy_event_class) do
      Class.new(RailsEventStore::Event)
    end

    specify 'no config' do
      event_store = Client.new

      TestRails.new.(->{ event_store.publish_event(dummy_event_class.new) })

      expect(event_store.read_events_forward(GLOBAL_STREAM)).to_not be_empty
      event_store.read_events_forward(GLOBAL_STREAM).map(&:metadata).each do |metadata|
        expect(metadata.remote_ip).to  eq('127.0.0.1')
        expect(metadata.request_id).to match(UUID_REGEX)
      end
    end
  end
end
