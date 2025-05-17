# frozen_string_literal: true

require_relative "../test_helper"

DummyEvent = Class.new(RubyEventStore::Event)
AnotherDummyEvent = Class.new(RubyEventStore::Event)

class Minitest::RubyEventStoreTest < Minitest::Test
  cover "Minitest::RubyEventStore*"

  def setup
    @event_store =
      RubyEventStore::Client.new(
        mapper:
          RubyEventStore::Mappers::PipelineMapper.new(
            RubyEventStore::Mappers::Pipeline.new(to_domain_event: RubyEventStore::Transformations::IdentityMap.new),
          ),
        correlation_id_generator: Proc.new {},
      )
  end

  def assert_triggered(expected, klass = Minitest::Assertion)
    e = assert_raises(klass) { yield }

    case expected
    when Regexp
      assert_match expected, e.message
    else
      assert_equal expected, e.message
    end
  end

  def test_assert_dispatched
    assert_dispatched(@event_store, [DummyEvent]) { @event_store.publish(DummyEvent.new) }
  end

  def test_assert_dispatched_failure
    message = <<-EOM
Expected 
  []
to include 
  DummyEvent
    EOM
    assert_triggered(message) { assert_dispatched(@event_store, [DummyEvent]) {} }
  end

  def test_assert_dispatched_singular_argument
    assert_dispatched(@event_store, DummyEvent) { @event_store.publish(DummyEvent.new) }
  end

  def test_assert_not_dispatched
    assert_not_dispatched(@event_store, [DummyEvent]) {}
  end

  def test_assert_not_dispatched_failure
    dummy_event = TimeEnrichment.with(DummyEvent.new(metadata: { correlation_id: nil }))
    message = <<-EOM
Expected 
  [#{dummy_event.inspect}]
to NOT include 
  DummyEvent
    EOM
    assert_triggered(message) do
      assert_not_dispatched(@event_store, [DummyEvent]) { @event_store.publish(dummy_event) }
    end
  end

  def test_assert_not_dispatched_singular_argument
    assert_not_dispatched(@event_store, DummyEvent) {}
  end

  def test_assert_published
    @event_store.publish(DummyEvent.new)
    assert_published(@event_store, DummyEvent)
  end

  def test_assert_published_failure_based_on_data_mismatch
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))

    message = <<-EOM.chomp
Event data mismatch.
Expected: #{{ "foo" => "foo" }}
  Actual: #{{ "foo" => "bar" }}
    EOM
    assert_triggered(message) { assert_published(@event_store, DummyEvent, with_data: { "foo" => "foo" }) }
  end

  def test_assert_published_failure_based_on_metadata_mismatch
    @event_store.with_metadata(foo: "bar") { @event_store.publish(DummyEvent.new) }

    message = <<-EOM.chomp
Event metadata mismatch.
Expected: #{{ "foo" => "foo" }}
  Actual: #{{ "foo" => "bar" }}
    EOM
    assert_triggered(message) { assert_published(@event_store, DummyEvent, with_metadata: { "foo" => "foo" }) }
  end

  def test_assert_published_failure_based_on_type_mismatch
    @event_store.publish(DummyEvent.new)

    message = "Expected some events of AnotherDummyEvent type, none were there"
    assert_triggered(message) { assert_published(@event_store, AnotherDummyEvent) }
  end

  def test_assert_not_published
    @event_store.publish(DummyEvent.new)

    assert_not_published(@event_store, AnotherDummyEvent)
  end

  def test_assert_not_published_failure
    @event_store.publish(DummyEvent.new)
    message = <<-EOM.chomp
Expected no event of DummyEvent type.
Expected: 0
  Actual: 1
    EOM
    assert_triggered(message) { assert_not_published(@event_store, DummyEvent) }
  end

  def test_assert_published_once
    @event_store.publish(DummyEvent.new)
    @event_store.publish(AnotherDummyEvent.new)
    assert_published_once(@event_store, DummyEvent)
  end

  def test_assert_published_once_failure_based_on_quantity
    2.times { @event_store.publish(DummyEvent.new) }
    message = <<-EOM.chomp
Expected only one event of DummyEvent type.
Expected: 1
  Actual: 2
    EOM
    assert_triggered(message) { assert_published_once(@event_store, DummyEvent) }
  end

  def test_assert_published_once_failure_based_on_data_mismatch
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    message = <<-EOM.chomp
Event data mismatch.
Expected: #{{ "foo" => "foo" }}
  Actual: #{{ "foo" => "bar" }}
    EOM
    assert_triggered(message) { assert_published_once(@event_store, DummyEvent, with_data: { foo: "foo" }) }
  end

  def test_assert_published_once_failure_based_on_metadata_mismatch
    @event_store.with_metadata(foo: "bar") { @event_store.publish(DummyEvent.new) }
    message = <<-EOM.chomp
Event metadata mismatch.
Expected: #{{ "foo" => "foo" }}
  Actual: #{{ "foo" => "bar" }}
    EOM
    assert_triggered(message) { assert_published_once(@event_store, DummyEvent, with_metadata: { foo: "foo" }) }
  end

  def test_assert_nothing_published
    assert_nothing_published(@event_store)
  end

  def test_assert_nothing_published_failure
    @event_store.publish(DummyEvent.new)
    message = <<-EOM.chomp
Expected no events published.
Expected: 0
  Actual: 1
    EOM
    assert_triggered(message) { assert_nothing_published(@event_store) }
  end

  def test_assert_published_once_with_block
    2.times { @event_store.publish(DummyEvent.new) }
    assert_published_once(@event_store, DummyEvent) { @event_store.publish(DummyEvent.new) }
  end

  def test_assert_nothing_published_with_block
    @event_store.publish(DummyEvent.new)
    assert_nothing_published(@event_store) {}
  end

  def test_assert_not_published_with_block
    @event_store.publish(DummyEvent.new)
    assert_not_published(@event_store, DummyEvent) {}
  end

  def test_assert_not_published_to_specific_stream
    @event_store.publish(DummyEvent.new)
    assert_not_published(@event_store, DummyEvent, within_stream: "specific-stream")
  end

  def test_assert_published_once_to_specific_stream
    @event_store.publish(DummyEvent.new)
    @event_store.publish(DummyEvent.new, stream_name: "specific-stream")
    assert_published_once(@event_store, DummyEvent, within_stream: "specific-stream")
  end

  def test_assert_event_in_stream
    event = DummyEvent.new
    @event_store.publish(event, stream_name: "specific-stream")

    assert_event_in_stream(@event_store, event, "specific-stream")
  end

  def test_assert_event_in_stream_failure
    event = DummyEvent.new
    @event_store.publish(event)

    message = <<-EOM.strip
      Expected event #{event.event_id} in specific-stream stream, none was there
    EOM

    assert_triggered(message) { assert_event_in_stream(@event_store, event, "specific-stream") }
  end

  def test_assert_event_not_in_stream
    event = DummyEvent.new
    @event_store.publish(event)

    assert_event_not_in_stream(@event_store, event, "specific-stream")
  end

  def test_assert_event_not_in_stream_failure
    event = DummyEvent.new
    @event_store.publish(event, stream_name: "specific-stream")

    message = <<-EOM.strip
      Expected event #{event.event_id} not to be in specific-stream stream, but it was there
    EOM

    assert_triggered(message) { assert_event_not_in_stream(@event_store, event, "specific-stream") }
  end

  def test_exact_new_events
    events = [DummyEvent.new, DummyEvent.new]
    events.each { |event| @event_store.publish(event) }

    new_events = [AnotherDummyEvent.new, AnotherDummyEvent.new]

    assert_exact_new_events(@event_store, new_events.map(&:class)) do
      new_events.each { |event| @event_store.publish(event) }
    end
  end

  def test_exact_new_events_failure
    events = [DummyEvent.new, DummyEvent.new]
    events.each { |event| @event_store.publish(event) }

    new_events = [AnotherDummyEvent.new, AnotherDummyEvent.new]

    message = <<-EOM.chomp
Expected new events weren't found.
--- expected
+++ actual
@@ -1 +1 @@
-[AnotherDummyEvent, AnotherDummyEvent]
+[]

    EOM

    assert_triggered(message) { assert_exact_new_events(@event_store, new_events.map(&:class)) {} }
  end

  def test_new_events_include
    events = [DummyEvent.new, DummyEvent.new]
    events.each { |event| @event_store.publish(event) }

    new_events = [AnotherDummyEvent.new, AnotherDummyEvent.new, DummyEvent.new]

    assert_new_events_include(@event_store, [DummyEvent]) { new_events.each { |event| @event_store.publish(event) } }
  end

  def test_new_events_include_failure_no_new_messages
    events = [DummyEvent.new, DummyEvent.new]
    events.each { |event| @event_store.publish(event) }

    message = <<-EOM.chomp
Didn't include all of: [DummyEvent] in []
    EOM

    assert_triggered(message) { assert_new_events_include(@event_store, [DummyEvent]) {} }
  end

  def test_new_events_include_failure_expected_message_not_included
    events = [DummyEvent.new, DummyEvent.new]
    events.each { |event| @event_store.publish(event) }

    message = <<-EOM.chomp
Didn't include all of: [DummyEvent] in [AnotherDummyEvent]
    EOM

    assert_triggered(message) do
      assert_new_events_include(@event_store, [DummyEvent]) { @event_store.publish(AnotherDummyEvent.new) }
    end
  end

  def test_equal_event
    expected_event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

    @event_store.publish(DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" }))
    actual_event = @event_store.read.backward.first

    assert_equal_event(expected_event, actual_event)
  end

  def test_equal_event_failure
    expected_event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

    @event_store.publish(DummyEvent.new(data: { foo: "bar" }, metadata: { bar: "foo" }))
    actual_event = @event_store.read.backward.first

    message = <<-EOM.chomp
Expected: #{{ foo: "foo" }}
  Actual: #{{ foo: "bar" }}
    EOM

    assert_triggered(message) { assert_equal_event(expected_event, actual_event) }
  end

  def test_equal_event_failure_on_class
    expected_event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

    @event_store.publish(AnotherDummyEvent.new(data: { foo: "bar" }, metadata: { bar: "foo" }))
    actual_event = @event_store.read.backward.first

    message = <<-EOM.chomp
Expected: DummyEvent
  Actual: AnotherDummyEvent
    EOM

    assert_triggered(message) { assert_equal_event(expected_event, actual_event) }
  end

  def test_equal_event_with_id
    event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

    @event_store.publish(event)
    actual_event = @event_store.read.backward.first

    assert_equal_event(event, actual_event, verify_id: true)
  end

  def test_equal_event_with_id_failure
    expected_event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

    dummy_event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })
    @event_store.publish(dummy_event)
    actual_event = @event_store.read.backward.first
    message = <<-EOM
--- expected
+++ actual
@@ -1,3 +1,3 @@
 # encoding: US-ASCII
 #    valid: true
-#{expected_event.event_id.inspect}
+#{dummy_event.event_id.inspect}
    EOM

    assert_triggered(message) { assert_equal_event(expected_event, actual_event, verify_id: true) }
  end

  def test_equal_events
    event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })
    second_event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

    @event_store.publish(event)
    @event_store.publish(second_event)
    events = @event_store.read.backward.limit(2).to_a

    assert_equal_events([event, second_event], events)
  end

  def test_equal_events_failure
    event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })
    second_event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

    @event_store.publish(event)
    events = @event_store.read.backward.limit(2).to_a

    message = <<-EOM.chomp
Expected: 2
  Actual: 1
    EOM

    assert_triggered(message) { assert_equal_events([event, second_event], events) }
  end

  def test_equal_events_with_id_verification
    event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

    @event_store.publish(event)
    events = @event_store.read.backward.limit(2).to_a

    assert_equal_events([event], events, verify_id: true)
  end

  def test_equal_events_with_id_verification_failure
    event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })
    second_event = DummyEvent.new(data: { foo: "foo" }, metadata: { bar: "bar" })

    @event_store.publish(event)
    @event_store.publish(second_event)
    events = @event_store.read.backward.limit(2).to_a

    message = <<-EOM.chomp
--- expected
+++ actual
@@ -1,3 +1,3 @@
 # encoding: US-ASCII
 #    valid: true
-#{event.event_id.inspect}
+#{second_event.event_id.inspect}

    EOM

    assert_triggered(message) { assert_equal_events([event, second_event], events, verify_id: true) }
  end
end
