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

      def matcher(*expected)
        Publish.new(*expected)
      end

      specify do
        expect {
          expect {
            true
          }.to matcher
        }.to raise_error(SyntaxError, "You have to set the event store instance with `in`, e.g. `expect { ... }.to publish(an_event(MyEvent)).in(event_store)`")
      end

      specify do
        expect {
          true
        }.not_to matcher.in(event_store)
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new)
        }.to matcher.in(event_store)
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new, stream_name: 'Foo$1')
        }.to matcher.in(event_store).in_stream('Foo$1')
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new, stream_name: 'Foo$1')
        }.not_to matcher.in(event_store).in_stream('Bar$1')
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new)
        }.not_to matcher(matchers.an_event(BarEvent)).in(event_store)
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new)
        }.to matcher(matchers.an_event(FooEvent)).in(event_store)
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new, stream_name: "Foo$1")
        }.to matcher(matchers.an_event(FooEvent)).in(event_store).in_stream("Foo$1")
      end

      specify do
        expect {
          event_store.publish_event(FooEvent.new)
        }.not_to matcher(matchers.an_event(FooEvent)).in(event_store).in_stream("Foo$1")
      end

      specify do
        foo_event = FooEvent.new
        bar_event = BarEvent.new
        expect {
          event_store.publish_event(foo_event, stream_name: "Foo$1")
          event_store.publish_event(bar_event, stream_name: "Bar$1")
        }.to matcher(matchers.an_event(FooEvent), matchers.an_event(BarEvent)).in(event_store)
      end

      specify do
        foo_event = FooEvent.new
        bar_event = BarEvent.new

        event_store.publish_event(foo_event)
        expect {
          event_store.publish_event(bar_event)
        }.not_to matcher(matchers.an_event(FooEvent)).in(event_store)
      end

      specify do
        expect {
          true
        }.not_to matcher.in(event_store)
      end

      specify do
        _matcher = matcher.in(event_store)
        _matcher.matches?(Proc.new { })

        expect(_matcher.failure_message_when_negated.to_s).to eq(<<~EOS.strip)
          expected block not to have published any events
        EOS
      end

      specify do
        _matcher = matcher.in(event_store)
        _matcher.matches?(Proc.new { })

        expect(_matcher.failure_message.to_s).to eq(<<~EOS.strip)
          expected block to have published any events
        EOS
      end

      specify do
        _matcher = matcher(actual = matchers.an_event(FooEvent)).in(event_store)
        _matcher.matches?(Proc.new { })

        expect(_matcher.failure_message.to_s).to eq(<<~EOS)
          expected block to have published:

          #{[actual].inspect}

          but published:

          []
        EOS
      end

      specify do
        _matcher = matcher(actual = matchers.an_event(FooEvent)).in_stream('foo').in(event_store)
        _matcher.matches?(Proc.new { })

        expect(_matcher.failure_message.to_s).to eq(<<~EOS)
          expected block to have published:

          #{[actual].inspect}

          in stream foo but published:

          []
        EOS
      end

      specify do
        foo_event = FooEvent.new
        _matcher = matcher(actual = matchers.an_event(FooEvent)).in(event_store)
        _matcher.matches?(Proc.new { event_store.publish_event(foo_event) })

        expect(_matcher.failure_message_when_negated.to_s).to eq(<<~EOS)
          expected block not to have published:

          #{[actual].inspect}

          but published:

          #{[foo_event].inspect}
        EOS
      end

      specify do
        foo_event = FooEvent.new
        _matcher = matcher(actual = matchers.an_event(FooEvent)).in_stream('foo').in(event_store)
        _matcher.matches?(Proc.new { event_store.publish_event(foo_event, stream_name: 'foo') })

        expect(_matcher.failure_message_when_negated.to_s).to eq(<<~EOS)
          expected block not to have published:

          #{[actual].inspect}

          in stream foo but published:

          #{[foo_event].inspect}
        EOS
      end

      specify do
        _matcher = matcher
        expect(_matcher.description).to eq("publish events")
      end
    end
  end
end
