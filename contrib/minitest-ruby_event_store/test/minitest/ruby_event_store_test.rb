require_relative "../test_helper"

DummyEvent = Class.new(RubyEventStore::Event)
AnotherDummyEvent = Class.new(RubyEventStore::Event)

class Minitest::RubyEventStoreTest < Minitest::Test
  cover "Minitest::RubyEventStore*"

  def setup
    @event_store =
      RubyEventStore::Client.new(
        repository: RubyEventStore::InMemoryRepository.new,
        mapper:
          RubyEventStore::Mappers::PipelineMapper.new(
            RubyEventStore::Mappers::Pipeline.new(to_domain_event: RubyEventStore::Transformations::IdentityMap.new)
          ),
        correlation_id_generator: Proc.new {}
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
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    assert_published(@event_store, DummyEvent, foo: "bar")
  end

  def test_assert_published_failure_based_on_data_mismatch
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))

    message = <<-EOM.chomp
Event data mismatch.
Expected: {"foo"=>"foo"}
  Actual: {"foo"=>"bar"}
EOM
    assert_triggered(message) do
      assert_published(@event_store, DummyEvent, foo: "foo")
    end
  end

  def test_assert_published_failure_based_on_type_mismatch
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))

    message = 'Expected some events of AnotherDummyEvent type, none were there'
    assert_triggered(message) do
      assert_published(@event_store, AnotherDummyEvent, foo: "bar")
    end
  end

  def test_assert_not_published
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))

    assert_not_published(@event_store, AnotherDummyEvent)
  end

  def test_assert_not_published_failure
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    message = <<-EOM.chomp
Expected no event of DummyEvent type.
Expected: 0
  Actual: 1
EOM
    assert_triggered(message) do
      assert_not_published(@event_store, DummyEvent)
    end
  end

  def test_assert_published_once
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    @event_store.publish(AnotherDummyEvent.new(data: { "foo" => "bar" }))
    assert_published_once(@event_store, DummyEvent, foo: "bar")
  end

  def test_assert_published_once_failure_based_on_quantity
    2.times { @event_store.publish(DummyEvent.new(data: { "foo" => "bar" })) }
    message = <<-EOM.chomp
Expected only one event of DummyEvent type.
Expected: 1
  Actual: 2
EOM
    assert_triggered(message) do
      assert_published_once(@event_store, DummyEvent, foo: "bar")
    end
  end

  def test_assert_published_once_failure_based_on_data_mismatch
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    message = <<-EOM.chomp
Event data mismatch.
Expected: {"foo"=>"foo"}
  Actual: {"foo"=>"bar"}
EOM
    assert_triggered(message) do
      assert_published_once(@event_store, DummyEvent, foo: "foo")
    end
  end

  def test_assert_nothing_published
    assert_nothing_published(@event_store)
  end

  def test_assert_nothing_published_failure
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    message = <<-EOM.chomp
Expected no events published.
Expected: 0
  Actual: 1
EOM
    assert_triggered(message) do
      assert_nothing_published(@event_store)
    end
  end

  def test_assert_published_once_with_block
    2.times { @event_store.publish(DummyEvent.new(data: { "foo" => "bar" })) }
    assert_published_once(@event_store, DummyEvent, foo: "bar") do
      @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    end
  end

  def test_assert_nothing_published_with_block
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    assert_nothing_published(@event_store) {}
  end

  def test_assert_not_published_with_block
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    assert_not_published(@event_store, DummyEvent) {}
  end

  def test_assert_not_published_to_specific_stream
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    assert_not_published(@event_store, DummyEvent,  "specific-stream")
  end

  def test_assert_published_once_to_specific_stream
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }))
    @event_store.publish(DummyEvent.new(data: { "foo" => "bar" }), stream_name: "specific-stream")
    assert_published_once(@event_store, DummyEvent, { foo: "bar" }, "specific-stream")
  end
end