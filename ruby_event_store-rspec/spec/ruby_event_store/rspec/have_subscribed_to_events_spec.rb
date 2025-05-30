# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module RSpec
    ::RSpec.describe HaveSubscribedToEvents do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }
      let(:event_store) do
        Client.new(
          mapper:
            Mappers::BatchMapper.new(
              Mappers::PipelineMapper.new(Mappers::Pipeline.new(to_domain_event: Transformations::IdentityMap.new)),
            ),
        )
      end
      let(:handler) { Handler.new }

      def matcher(*expected)
        HaveSubscribedToEvents.new(*expected, differ: colorless_differ, phraser: phraser)
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(color: false)
      end

      def phraser
        Matchers::ListPhraser
      end

      specify { expect(handler).not_to matcher(FooEvent, BarEvent, BazEvent).in(event_store) }

      specify do
        event_store.subscribe(handler, to: [FooEvent])
        expect(handler).to matcher(FooEvent).in(event_store)
        expect(handler).not_to matcher(BarEvent).in(event_store)
      end

      specify do
        event_store.subscribe(handler, to: [FooEvent, BarEvent])
        expect(handler).to matcher(FooEvent).in(event_store)
        expect(handler).to matcher(BarEvent).in(event_store)
        expect(handler).to matcher(FooEvent, BarEvent).in(event_store)
        expect(handler).not_to matcher(FooEvent, BarEvent, BazEvent).in(event_store)
      end

      describe "messages" do
        specify do
          event_store.subscribe(handler, to: [FooEvent])
          matcher_ = matcher(FooEvent, BarEvent).in(event_store)
          matcher_.matches?(handler)

          expect(matcher_.failure_message).to eq(<<~EOS)
            expected #{handler} to be subscribed to events, diff:
            @@ -1,2 +1,2 @@
            -[FooEvent]
            +[FooEvent, BarEvent]
          EOS
        end

        specify do
          event_store.subscribe(handler, to: [FooEvent])
          matcher_ = matcher(FooEvent, BarEvent).in(event_store)
          matcher_.matches?(handler)

          expect(matcher_.failure_message_when_negated).to eq(<<~EOS)
            expected #{handler} not to be subscribed to events, diff:
            @@ -1,2 +1,2 @@
            -[FooEvent]
            +[FooEvent, BarEvent]
          EOS
        end

        specify do
          matcher_ = matcher(FooEvent, BarEvent).in(event_store)
          matcher_.matches?(handler)

          expect(matcher_.description).to eq("have subscribed to events that have to (be a FooEvent and be a BarEvent)")
        end
      end
    end
  end
end
