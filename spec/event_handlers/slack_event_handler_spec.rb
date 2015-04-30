require 'spec_helper'

module RailsEventStore
  describe EventHandlers::SlackEventHandler do
    let(:webhook_url) { "http://hooks.slack.com/example" }
    let(:repository) { EventInMemoryRepository.new }
    let(:client) { Client.new(repository) }

    specify "should have handle_event method with one arg" do
      slack_event_handler = EventHandlers::SlackEventHandler.new(webhook_url)
      expect(slack_event_handler).to respond_to(:handle_event)
    end

    specify "should be able to subscribe" do
      slack_event_handler = EventHandlers::SlackEventHandler.new(webhook_url)

      client.subscribe(slack_event_handler)
      event = OrderCreated.new({data: 'sample'})
      client.publish_event(event)
    end
  end
end
