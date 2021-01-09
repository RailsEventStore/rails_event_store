require_relative "../test_helper"

DummyEvent = Class.new(RubyEventStore::Event)

class Minitest::RailsEventStoreTest < Minitest::Test
  attr_reader :event_store

  def setup
    @event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)
  end

  def assert_triggered(expected, klass = Minitest::Assertion)
    e = assert_raises(klass) do
      yield
    end

    case expected
    when Regexp
      assert_match expected, e.message
    else
      assert_equal expected, e.message
    end
  end

  def test_assert_dispatched
    assert_dispatched(event_store, [DummyEvent]) { event_store.publish(DummyEvent.new) }
  end

  def test_assert_dispatched_failure
    assert_triggered "bazinga" do
      assert_dispatched(event_store, [DummyEvent]) { }
    end
  end

  def test_assert_dispatched_singular_argument
    assert_dispatched(event_store, DummyEvent) { event_store.publish(DummyEvent.new) }
  end

  def test_assert_not_dispatched
    assert_not_dispatched(event_store, [DummyEvent]) { }
  end

  def test_assert_not_dispatched_failure
    assert_triggered "bazinga" do
      assert_not_dispatched(event_store, DummyEvent) { event_store.publish(DummyEvent.new) }
    end
  end

  def test_assert_not_dispatched_singular
    assert_not_dispatched(event_store, DummyEvent) { }
  end
end
