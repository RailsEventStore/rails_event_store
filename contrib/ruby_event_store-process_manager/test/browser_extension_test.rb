# frozen_string_literal: true

require_relative "test_helper"
require "ruby_event_store/browser/app"
require "ruby_event_store/process_manager/browser_extension"

class BrowserExtensionTest < Minitest::Test
  cover "RubyEventStore::ProcessManager*"

  BrowserOrderPaid = Class.new(RubyEventStore::Event)
  BrowserOrderAddressSet = Class.new(RubyEventStore::Event)
  BrowserDynamicStateChanged = Class.new(RubyEventStore::Event)

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

  class BrowserDynamicStateProcess
    include RubyEventStore::ProcessManager.with_state { Hash }

    subscribes_to BrowserDynamicStateChanged

    private

    def fetch_id(event) = event.data.fetch(:process_id)

    def apply(event) = state.merge(event.data.fetch(:state))

    def act
    end
  end

  def setup
    @event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
    extension = RubyEventStore::ProcessManager::BrowserExtension.new
    app = RubyEventStore::Browser::App.for(event_store_locator: -> { @event_store }, extensions: [extension])
    @web_client = Rack::MockRequest.new(app)
  end

  def test_renders_step_by_step_state_of_the_process
    paid = BrowserOrderPaid.new(data: { order_id: "order-1" })
    address = BrowserOrderAddressSet.new(data: { order_id: "order-1" })
    run_process(paid, address)

    response = @web_client.get("/process_managers/BrowserExtensionTest%3A%3ABrowserOrderProcess%24order-1")

    assert_equal(200, response.status)
    assert_includes(response.body, "Process BrowserExtensionTest::BrowserOrderProcess")
    assert_includes(response.body, "Current state")
    assert_includes(response.body, "Step by step")
    assert_includes(response.body, paid.event_id)
    assert_includes(response.body, address.event_id)
    assert_includes(response.body, "BrowserExtensionTest::BrowserOrderPaid")
    assert_includes(response.body, "address_set")
  end

  def test_renders_initial_state_for_a_process_stream_without_events
    response = @web_client.get("/process_managers/BrowserExtensionTest%3A%3ABrowserOrderProcess%24order-42")

    assert_equal(200, response.status)
    assert_includes(response.body, "No events linked to this process stream yet")
    assert_includes(response.body, "paid")
  end

  def test_escapes_html_in_process_state_keys_and_values
    malicious_key = "<img data-xss-key src=x>"
    malicious_value = "<script>document.body.dataset.xss=1</script>"
    event = BrowserDynamicStateChanged.new(
      data: { process_id: "process-1", state: { malicious_key => malicious_value } },
    )
    @event_store.append(event)
    BrowserDynamicStateProcess.new.with(event_store: @event_store, command_bus: ->(_command) {}).call(event)

    body =
      @web_client.get(
        "/process_managers/BrowserExtensionTest%3A%3ABrowserDynamicStateProcess%24process-1",
      ).body

    refute_includes(body, malicious_key)
    refute_includes(body, malicious_value)
    assert_includes(body, "&lt;img data-xss-key src=x&gt;")
    assert_includes(body, "&lt;script&gt;document.body.dataset.xss=1&lt;/script&gt;")
  end

  def test_responds_with_the_styled_not_found_page_for_streams_not_following_the_convention
    response = @web_client.get("/process_managers/orders")

    assert_equal(404, response.status)
    assert_includes(response.body, "Page not found")
    assert_equal(404, @web_client.get("/process_managers/NoSuchProcess%241").status)
    assert_equal(404, @web_client.get("/process_managers/String%241").status)
  end

  def test_adds_a_link_on_the_stream_page_for_process_manager_streams
    paid = BrowserOrderPaid.new(data: { order_id: "order-1" })
    run_process(paid)

    response = @web_client.get("/streams/BrowserExtensionTest%3A%3ABrowserOrderProcess%24order-1")

    assert_includes(response.body, "Process state")
    assert_includes(
      response.body,
      "/process_managers/BrowserExtensionTest%3A%3ABrowserOrderProcess%24order-1",
    )
  end

  def test_does_not_add_the_link_on_other_streams
    @event_store.append(BrowserOrderPaid.new(data: { order_id: "order-1" }), stream_name: "orders")

    refute_includes(@web_client.get("/streams/orders").body, "Process state")
  end

  def test_serves_its_stylesheet_by_convention_and_links_it_in_the_layout
    asset_path = "/extension_assets/0/ruby_event_store_process_manager.css"

    assert_includes(@web_client.get("/streams/all").body, asset_path)
    assert_equal(200, @web_client.get(asset_path).status)
  end

  def test_links_back_to_the_stream_and_to_individual_events
    paid = BrowserOrderPaid.new(data: { order_id: "order-1" })
    run_process(paid)

    body = @web_client.get("/process_managers/BrowserExtensionTest%3A%3ABrowserOrderProcess%24order-1").body

    assert_includes(body, "/streams/BrowserExtensionTest%3A%3ABrowserOrderProcess%24order-1")
    assert_includes(body, "/events/#{paid.event_id}")
  end

  private

  def run_process(*events)
    process = BrowserOrderProcess.new.with(event_store: @event_store, command_bus: ->(_command) {})
    events.each do |event|
      @event_store.append(event)
      process.call(event)
    end
  end
end
