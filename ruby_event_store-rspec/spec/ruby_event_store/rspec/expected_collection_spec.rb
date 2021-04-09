require "spec_helper"

module RubyEventStore
  module RSpec
    ::RSpec.describe ExpectedCollection do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }

      specify do
        collection = ExpectedCollection.new([matchers.an_event(FooEvent)])

        collection.exactly(3)

        expect(collection.specified_count?).to be(true)
        expect(collection.count).to eq(3)
      end

      specify do
        collection = ExpectedCollection.new([matchers.an_event(FooEvent)])

        collection.once

        expect(collection.specified_count?).to be(true)
        expect(collection.count).to eq(1)
      end

      specify do
        collection = ExpectedCollection.new([])

        expect(collection.specified_count?).to be(false)
        expect(collection.strict?).to be(false)
        expect(collection.empty?).to be(true)
      end

      specify do
        collection = ExpectedCollection.new([expected_event = matchers.an_event(FooEvent)])

        expect(collection.event).to eq(expected_event)
      end

      specify do
        collection = ExpectedCollection.new([
          matchers.an_event(FooEvent).with_data(a: 1),
          matchers.an_event(FooEvent).with_data(a: 2),
        ])

        expect do
          collection.event
        end.to raise_error(NotSupported)
      end

      specify do
        collection = ExpectedCollection.new([matchers.an_event(FooEvent)])

        expect do
          collection.exactly(0)
        end.to raise_error(NotSupported)
      end

      specify do
        collection = ExpectedCollection.new([matchers.an_event(FooEvent)])

        collection.strict

        expect(collection.strict?).to be(true)
      end

      specify do
        collection = ExpectedCollection.new([
          matchers.an_event(FooEvent).with_data(a: 1),
          matchers.an_event(FooEvent).with_data(a: 2),
        ])

        expect do
          collection.exactly(3)
        end.to raise_error(NotSupported)
      end

      specify do
        collection = ExpectedCollection.new([
          matchers.an_event(FooEvent)
        ])

        expect(collection).not_to be_empty
      end
    end
  end
end
