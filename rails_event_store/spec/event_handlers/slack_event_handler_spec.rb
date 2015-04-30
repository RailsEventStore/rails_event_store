require 'spec_helper'

module RailsEventStore
  describe EventHandlers::SlackEventHandler do
    let(:webhook_url) { "https://hooks.slack.com/example" }
    let(:repository) { EventInMemoryRepository.new }
    let(:client) { Client.new(repository) }

    specify "should have handle_event method with one arg" do
      slack_event_handler = EventHandlers::SlackEventHandler.new(webhook_url)
      expect(slack_event_handler).to respond_to(:handle_event)
    end

    specify "should send request to slack" do
      stub_request(:any, webhook_url)

      slack_event_handler = EventHandlers::SlackEventHandler.new(webhook_url)

      client.subscribe(slack_event_handler)
      event = OrderCreated.new({data: 'sample'})
      client.publish_event(event)

      expect(a_request(:post, webhook_url)).to have_been_made
    end
  end
end
