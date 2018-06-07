require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe Publish do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) do
        RailsEventStore::Client.new(
          repository: RailsEventStore::InMemoryRepository.new,
          mapper: RubyEventStore::Mappers::NullMapper.new
        )
      end

      def matcher(*events, &block)
        Publish.new(events, &block)
      end

      specify do
        expect {
          expect {
            true
          }.to Publish.new()
        }.to raise_error(SyntaxError, "You have to set the event store instance with `in`, e.g. `expect { ... }.to publish(an_event(MyEvent)).in(event_store)`")
      end

      specify do
        expect {
          true
        }.not_to Publish.new.in(event_store)
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new)
        }.to Publish.new.in(event_store)
      end

      specify do
        expect {
          true
        }.to Publish.new{ |events|
          expect(events).to eq []
        }.in(event_store)
      end

      specify do
        foo_event = FooEvent.new
        bar_event = BarEvent.new
        expect {
          event_store.publish_event(foo_event)
          event_store.publish_event(bar_event)
        }.to Publish.new.in(event_store){ |events|
          expect(events).to eq [foo_event, bar_event]
        }
      end

      specify do
        foo_event = FooEvent.new
        bar_event = BarEvent.new
        event_store.publish_event(foo_event)
        expect {
          event_store.publish_event(bar_event)
        }.to Publish.new.in(event_store){ |events|
          expect(events).to eq [bar_event]
        }
      end

      specify do
        foo_event = FooEvent.new
        bar_event = BarEvent.new
        expect {
          event_store.publish_event(foo_event, stream_name: "Foo$1")
          event_store.publish_event(bar_event, stream_name: "Bar$1")
        }.to Publish.new.in(event_store).in_stream("Foo$1"){ |events|
          expect(events).to eq [foo_event]
        }
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new, stream_name: 'Foo$1')
        }.to Publish.new.in(event_store).in_stream('Foo$1')
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new, stream_name: 'Foo$1')
        }.not_to Publish.new.in(event_store).in_stream('Bar$1')
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new)
        }.to Publish.new(matchers.an_event(FooEvent)).in(event_store)
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new, stream_name: "Foo$1")
        }.to Publish.new(matchers.an_event(FooEvent)).in(event_store).in_stream("Foo$1")
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new)
        }.not_to Publish.new(matchers.an_event(FooEvent)).in(event_store).in_stream("Foo$1")
      end
    end
  end
end
