require "aggregate_root"
require "rails_event_store"
require "rails_event_store/rspec"
require_relative '../../support/helpers/rspec_defaults'
require_relative '../../support/helpers/mutant_timeout'

FooEvent = Class.new(RailsEventStore::Event)
BarEvent = Class.new(RailsEventStore::Event)
BazEvent = Class.new(RailsEventStore::Event)

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
    ::RubyEventStore::Mappers::Transformation::Item.new(
      event_id:   domain_event.event_id,
      metadata:   domain_event.metadata.to_h,
      data:       domain_event.data,
      event_type: domain_event.event_type
    )
  end

  def load(item)
    @identity_map.fetch(item.event_id)
  end
end
