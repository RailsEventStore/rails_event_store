# RubyEventStore::Profiler

Simplistic profiler hooking into RubyEventStore instrumenation infrastructure.

```ruby
DummyEvent = Class.new(RubyEventStore::Event)

instrumenter = ActiveSupport::Notifications
event_store =
  RubyEventStore::Client.new(
    repository: RubyEventStore::InstrumentedRepository.new(RubyEventStore::InMemoryRepository.new, instrumenter),
    mapper: RubyEventStore::Mappers::InstrumentedMapper.new(RubyEventStore::Mappers::Default.new, instrumenter),
    dispatcher: RubyEventStore::InstrumentedDispatcher.new(RubyEventStore::Dispatcher.new, instrumenter),
  )

repository = AggregateRoot::InstrumentedRepository.new(AggregateRoot::Repository.new(event_store), instrumenter)

class Bazinga
  include AggregateRoot

  def do_the_dummy
    apply(DummyEvent.new)
  end

  on DummyEvent do |event|
  end
end

profiler = RubyEventStore::Profiler.new(instrumenter)
profiler.measure do
  aggregate = repository.load(Bazinga.new, "bazinga")
  aggregate.do_the_dummy
  repository.store(aggregate, "bazinga")
end
```
