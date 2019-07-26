module Minitest::Assertions
  def assert_published(event_store, expected_events, &block)
    collected_events = []
    event_store.within do
      block.call
    end.subscribe_to_all_events do |event|
      collected_events << event.type
    end.call

    Array(expected_events).each do |expected|
      assert collected_events.include?(expected.to_s), "bazinga"
    end
  end
end