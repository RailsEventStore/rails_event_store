require "aggregate_root"
require "ruby_event_store"
require "ruby_event_store/rspec"
require "ruby_event_store/transformations"
require_relative "../../support/helpers/rspec_defaults"

FooEvent = Class.new(RubyEventStore::Event)
BarEvent = Class.new(RubyEventStore::Event)
BazEvent = Class.new(RubyEventStore::Event)

class TestAggregate
  include AggregateRoot.with_non_strict_default_apply_strategy

  def foo
    apply(FooEvent.new)
  end

  def bar
    apply(BarEvent.new)
  end

  def baz
    apply(BazEvent.new)
  end
end

class Handler
  def call(event); end
end
