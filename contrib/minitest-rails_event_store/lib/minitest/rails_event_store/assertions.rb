module Minitest::Assertions
  def assert_published(event_store, expected_events, &block)
    collected_events = []
    event_store.within do
      block.call
    end.subscribe_to_all_events do |event|
      collected_events << event.type
    end.call

    expected_events.each do |expected|
      assert_includes(collected_events, expected.to_s, "bazinga")
    end
  end
end