require 'spec_helper'

module RailsEventStore
  describe EventHandlers::SlackEventHandler do
    let(:webhook_url) { "https://hooks.slack.com/example" }
    let(:repository) { EventInMemoryRepository.new }
    let(:client) { Client.new(repository) }

    specify "should send request to slack" do
      WebMock.disable_net_connect!

      stub_request(:any, webhook_url)

      slack_event_handler = EventHandlers::SlackEventHandler.new(webhook_url)

      client.subscribe(slack_event_handler)
      event = OrderCreated.new
      client.publish_event(event)

      expected_body = {
        payload: '{"text":"Event OrderCreated raised.","username":"Rails EventStore Bot"}'
      }

      expect(a_request(:post, webhook_url).with(body: expected_body)).to have_been_made

      WebMock.allow_net_connect!
    end
  end
end
