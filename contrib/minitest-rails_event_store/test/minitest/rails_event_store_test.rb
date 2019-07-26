require "test_helper"

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

  def test_assert_published
    assert_published(event_store, [DummyEvent]) { event_store.publish(DummyEvent.new) }
  end

  def test_assert_published_failure
    assert_triggered "bazinga" do
      assert_published(event_store, [DummyEvent]) { }
    end
  end

  def test_assert_published_singular_argument
    assert_published(event_store, DummyEvent) { event_store.publish(DummyEvent.new) }
  end
end
