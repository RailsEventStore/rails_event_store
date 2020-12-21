require "aggregate_root"
require "ruby_event_store"
require "ruby_event_store/rspec"
require_relative '../../support/helpers/rspec_defaults'

FooEvent = Class.new(RubyEventStore::Event)
BarEvent = Class.new(RubyEventStore::Event)
BazEvent = Class.new(RubyEventStore::Event)

class TestAggregate
  include AggregateRoot

  def foo
    apply(FooEvent.new)
  end

  def bar
    apply(BarEvent.new)
  end

  def baz
    apply(BazEvent.new)
  end

  private

  def apply_foo_event(*)
  end

  def apply_bar_event(*)
  end

  def apply_baz_event(*)
  end
end

class IdentityMapTransformation
  def initialize
    @identity_map = {}
  end

  def dump(domain_event)
    @identity_map[domain_event.event_id] = domain_event
    RubyEventStore::Record.new(
      event_id:   domain_event.event_id,
      metadata:   domain_event.metadata.to_h,
      data:       domain_event.data,
      event_type: domain_event.event_type,
      timestamp:  domain_event.timestamp,
      valid_at:   domain_event.valid_at,
    )
  end

  def load(record)
    @identity_map.fetch(record.event_id)
  end
end


class Handler
  def call(event)
  end
end
