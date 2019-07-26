require "test_helper"
require "ruby_event_store"

DummyEvent = Class.new(RubyEventStore::Event)

class Minitest::RailsEventStoreTest < Minitest::Test
  def test_assert_published
    event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

    assert_published(event_store, [DummyEvent]) do
      event_store.publish(DummyEvent.new)
    end
  end

  def test_assert_published_failure
    event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

    assert_raises(Minitest::Assertion, /bazinga/) do
      assert_published(event_store, [DummyEvent]) do
      end
    end
  end

  def test_assert_published_singular_argument
    event_store = RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new)

    assert_published(event_store, DummyEvent) do
      event_store.publish(DummyEvent.new)
    end
  end
end
