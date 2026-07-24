# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/browser/app"
require "ruby_event_store/process_manager/browser_extension"

RSpec.describe RubyEventStore::ProcessManager::BrowserExtension do
  let(:event_store) { RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new) }
  let(:command_bus) { ->(command) {} }
  let(:app) do
    RubyEventStore::Browser::App.for(event_store_locator: -> { event_store }, extensions: [described_class.new])
  end
  let(:web_client) { Rack::MockRequest.new(app) }

  BrowserOrderPaid = Class.new(RubyEventStore::Event)
  BrowserOrderAddressSet = Class.new(RubyEventStore::Event)

  BrowserOrderState = Data.define(:paid, :address_set) do
    def initialize(paid: false, address_set: false)
      super
    end
  end

  class BrowserOrderProcess
    include RubyEventStore::ProcessManager.with_state { BrowserOrderState }

    subscribes_to BrowserOrderPaid, BrowserOrderAddressSet

    private

    def fetch_id(event)
      event.data.fetch(:order_id)
    end

    def apply(event)
      case event
      when BrowserOrderPaid
        state.with(paid: true)
      when BrowserOrderAddressSet
        state.with(address_set: true)
      else
        state
      end
    end

    def act
    end
  end

  def run_process(*events)
    process = BrowserOrderProcess.new(event_store, command_bus)
    events.each do |event|
      event_store.append(event)
      process.call(event)
    end
  end

  specify "renders step by step state of the process" do
    paid = BrowserOrderPaid.new(data: { order_id: "order-1" })
    address = BrowserOrderAddressSet.new(data: { order_id: "order-1" })
    run_process(paid, address)

    response = web_client.get("/process_managers/BrowserOrderProcess%24order-1")

    expect(response.status).to eq(200)
    expect(response.body).to include("Process BrowserOrderProcess")
    expect(response.body).to include("Current state")
    expect(response.body).to include("Step by step")
    expect(response.body).to include(paid.event_id)
    expect(response.body).to include(address.event_id)
    expect(response.body).to include("BrowserOrderPaid")
    expect(response.body).to include("address_set")
  end

  specify "renders initial state for a process stream without events" do
    response = web_client.get("/process_managers/BrowserOrderProcess%24order-42")

    expect(response.status).to eq(200)
    expect(response.body).to include("No events linked to this process stream yet")
    expect(response.body).to include("paid")
  end

  specify "responds with 404 for streams not following the convention" do
    expect(web_client.get("/process_managers/orders").status).to eq(404)
    expect(web_client.get("/process_managers/NoSuchProcess%241").status).to eq(404)
    expect(web_client.get("/process_managers/String%241").status).to eq(404)
  end

  specify "adds a link on the stream page for process manager streams" do
    paid = BrowserOrderPaid.new(data: { order_id: "order-1" })
    run_process(paid)

    response = web_client.get("/streams/BrowserOrderProcess%24order-1")

    expect(response.body).to include("Process state")
    expect(response.body).to include("/process_managers/BrowserOrderProcess%24order-1")
  end

  specify "does not add the link on other streams" do
    event_store.append(BrowserOrderPaid.new(data: { order_id: "order-1" }), stream_name: "orders")

    expect(web_client.get("/streams/orders").body).not_to include("Process state")
  end

  specify "serves its own stylesheet and links it in the layout" do
    response = web_client.get("/process_manager_assets/stylesheet.css")

    expect(response.status).to eq(200)
    expect(response.headers["content-type"]).to eq("text/css")
    expect(web_client.get("/streams/all").body).to include("/process_manager_assets/stylesheet.css")
  end

  specify "links back to the stream and to individual events" do
    paid = BrowserOrderPaid.new(data: { order_id: "order-1" })
    run_process(paid)

    body = web_client.get("/process_managers/BrowserOrderProcess%24order-1").body

    expect(body).to include("/streams/BrowserOrderProcess%24order-1")
    expect(body).to include("/events/#{paid.event_id}")
  end
end
