require 'spec_helper'
require 'action_controller/railtie'

module RailsEventStore
  RSpec.describe LinkByMetadata do

    before do
      rails = double("Rails", configuration: Rails::Application::Configuration.new)
      stub_const("Rails", rails)
      Rails.configuration.event_store = event_store
      ActiveJob::Base.queue_adapter = SimpleAdapter
    end

    let(:event_store) { RailsEventStore::Client.new }

    specify "defaults to Rails.configuration.event_store and passes rest of options" do
      event_store.subscribe_to_all_events(LinkByMetadata.new(
        key: :city,
        prefix: "sweet+")
      )

      event_store.publish(ev = OrderCreated.new(metadata:{
        city: "Paris",
      }))

      expect(event_store.read.stream("sweet+Paris").each.to_a).to eq([ev])
    end

  end
end