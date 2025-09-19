# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module RSpec
    ::RSpec.describe Publish do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) do
        Client.new(
          mapper: Mappers::PipelineMapper.new(Mappers::Pipeline.new(to_domain_event: Transformations::IdentityMap.new)),
        )
      end

      def matcher(*expected)
        Publish.new(*expected, failure_message_formatter: RSpec.default_formatter.publish(differ))
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(color: false)
      end

      specify do
        expect { expect { true }.to matcher }.to raise_error(
          "You have to set the event store instance with `in`, e.g. `expect { ... }.to publish(an_event(MyEvent)).in(event_store)`",
        )
      end

      specify { expect { true }.not_to matcher.in(event_store) }

      specify { expect { event_store.publish(FooEvent.new) }.to matcher.in(event_store) }

      specify do
        expect { event_store.publish(FooEvent.new, stream_name: "Foo$1") }.to matcher.in(event_store).in_stream("Foo$1")
      end

      specify do
        expect { event_store.publish(FooEvent.new, stream_name: "Foo$1") }.not_to matcher.in(event_store).in_stream(
          "Bar$1",
        )
      end

      specify { expect { event_store.publish(FooEvent.new) }.not_to matcher.in(event_store).in_streams("Foo$1") }

      specify do
        expect { event_store.publish(FooEvent.new, stream_name: "Foo$1") }.not_to matcher.in(event_store).in_streams(
          %w[Foo$1 Bar$1],
        )
      end

      specify do
        expect {
          event_store.publish(event = FooEvent.new, stream_name: "Foo$1")
          event_store.link(event.event_id, stream_name: "Bar$1")
        }.to matcher.in(event_store).in_streams(%w[Foo$1 Bar$1])
      end

      specify do
        expect { event_store.publish(FooEvent.new) }.not_to matcher(matchers.an_event(BarEvent)).in(event_store)
      end

      specify { expect { event_store.publish(FooEvent.new) }.to matcher(matchers.an_event(FooEvent)).in(event_store) }

      specify do
        expect { event_store.publish(FooEvent.new, stream_name: "Foo$1") }.to matcher(matchers.an_event(FooEvent)).in(
          event_store,
        ).in_stream("Foo$1")
      end

      specify do
        expect { event_store.publish(FooEvent.new) }.not_to matcher(matchers.an_event(FooEvent)).in(
          event_store,
        ).in_stream("Foo$1")
      end

      specify do
        event_store.publish(FooEvent.new)
        event_store.publish(FooEvent.new)
        event_store.publish(FooEvent.new)
        expect { event_store.publish(BarEvent.new) }.to matcher(matchers.an_event(BarEvent)).in(event_store)
        expect { event_store.publish(BarEvent.new) }.not_to matcher(matchers.an_event(FooEvent)).in(event_store)
      end

      specify do
        foo_event = FooEvent.new
        bar_event = BarEvent.new
        expect {
          event_store.publish(foo_event, stream_name: "Foo$1")
          event_store.publish(bar_event, stream_name: "Bar$1")
        }.to matcher(matchers.an_event(FooEvent), matchers.an_event(BarEvent)).in(event_store)
      end

      specify do
        foo_event = FooEvent.new
        bar_event = BarEvent.new

        event_store.publish(foo_event)
        expect { event_store.publish(bar_event) }.not_to matcher(matchers.an_event(FooEvent)).in(event_store)
      end

      specify { expect { true }.not_to matcher.in(event_store) }

      specify do
        matcher_ = matcher.in(event_store)
        matcher_.matches?(Proc.new {})

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS.strip)
          expected block not to have published any events
        EOS
      end

      specify do
        matcher_ = matcher.in(event_store)
        matcher_.matches?(Proc.new {})

        expect(matcher_.failure_message.to_s).to eq(<<~EOS.strip)
          expected block to have published any events
        EOS
      end

      specify do
        matcher_ = matcher(actual = matchers.an_event(FooEvent)).in(event_store)
        matcher_.matches?(Proc.new {})

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
          expected block to have published:

          #{[actual].inspect}

          but published:

          []
        EOS
      end

      specify do
        matcher_ = matcher(actual = matchers.an_event(FooEvent)).in_stream("foo").in(event_store)
        matcher_.matches?(Proc.new {})

        expect(matcher_.failure_message.to_s).to eq(<<~EOS)
          expected block to have published:

          #{[actual].inspect}

          in stream foo but published:

          []
        EOS
      end

      specify do
        foo_event = FooEvent.new
        matcher_ = matcher(actual = matchers.an_event(FooEvent)).in(event_store)
        matcher_.matches?(Proc.new { event_store.publish(foo_event) })

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS)
          expected block not to have published:

          #{[actual].inspect}

          but published:

          #{[foo_event].inspect}
        EOS
      end

      specify do
        foo_event = FooEvent.new
        matcher_ = matcher(actual = matchers.an_event(FooEvent)).in_stream("foo").in(event_store)
        matcher_.matches?(Proc.new { event_store.publish(foo_event, stream_name: "foo") })

        expect(matcher_.failure_message_when_negated.to_s).to eq(<<~EOS)
          expected block not to have published:

          #{[actual].inspect}

          in stream foo but published:

          #{[foo_event].inspect}
        EOS
      end

      specify do
        matcher_ = matcher
        expect(matcher_.description).to eq("publish events")
      end

      specify do
        expect {
          event_store.publish(FooEvent.new)
          event_store.publish(FooEvent.new)
        }.to matcher(matchers.an_event(FooEvent)).in(event_store).exactly(2).times
      end

      specify do
        expect {
          event_store.publish(FooEvent.new)
          event_store.publish(FooEvent.new)
        }.not_to matcher(matchers.an_event(FooEvent)).in(event_store).exactly(3).times
      end

      specify do
        expect do
          expect { event_store.publish(FooEvent.new) }.to matcher(
            matchers.an_event(FooEvent),
            matchers.an_event(FooEvent),
          ).in(event_store).exactly(3).times
        end.to raise_error(NotSupported)
      end

      specify do
        expect do
          expect {}.to matcher(matchers.an_event(FooEvent), matchers.an_event(FooEvent))
            .in(event_store)
            .exactly(3)
            .times
        end.to raise_error(NotSupported)
      end

      specify do
        expect { event_store.publish(FooEvent.new) }.to matcher(matchers.an_event(FooEvent)).once.in(event_store)
      end

      specify do
        expect {
          event_store.publish(FooEvent.new)
          event_store.publish(FooEvent.new)
        }.not_to matcher(matchers.an_event(FooEvent)).once.in(event_store)
      end

      specify do
        expect do
          event_store.publish(FooEvent.new)
          event_store.publish(BarEvent.new)
          event_store.publish(BazEvent.new)
        end.not_to matcher(matchers.an_event(FooEvent), matchers.an_event(BarEvent)).strict.in(event_store)
      end

      specify do
        expect do
          event_store.publish(FooEvent.new)
          event_store.publish(BarEvent.new)
        end.to matcher(matchers.an_event(FooEvent), matchers.an_event(BarEvent)).strict.in(event_store)
      end

      specify do
        event_store.publish(FooEvent.new, stream_name: "Stream$1")
        event_store.publish(FooEvent.new, stream_name: "Stream$2")
        expect do
          event_store.publish(BarEvent.new, stream_name: "Stream$1")
          event_store.publish(BarEvent.new, stream_name: "Stream$3")
        end.to matcher(matchers.an_event(BarEvent)).strict.in(event_store).in_streams(%w[Stream$1 Stream$3])
      end

      it 'is composable' do
        expect do
          event_store.publish(FooEvent.new, stream_name: "Stream$1")
          event_store.publish(BarEvent.new, stream_name: "Stream$2")
        end.to matcher(matchers.an_event(FooEvent)).in(event_store).in_stream("Stream$1")
           .and matcher(matchers.an_event(BarEvent)).in(event_store).in_stream("Stream$2")
      end
    end
  end
end
