require "spec_helper"
require "rails_event_store"

module RailsEventStore
  module RSpec
    ::FooEvent = Class.new(RailsEventStore::Event)
    ::BarEvent = Class.new(RailsEventStore::Event)

    ::RSpec.describe EventMatcher do
      def matcher(expected)
        EventMatcher.new(expected, differ: colorless_differ)
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(
          :object_preparer => lambda { |object| RSpec::Matchers::Composable.surface_descriptions_in(object) },
          :color => false
        )
      end

      specify do
        expect(FooEvent.new).to matcher(FooEvent)
      end

      specify do
        expect(FooEvent.new).not_to matcher(BarEvent)
      end

      specify do
        _matcher = matcher(FooEvent)
        _matcher.matches?(BarEvent.new)

        expect(_matcher.failure_message).to eq(%q{
expected: FooEvent
     got: BarEvent
})
      end

      specify do
        _matcher = matcher(FooEvent)
        _matcher.matches?(FooEvent.new)

        expect(_matcher.failure_message_when_negated).to eq(%q{
expected: not a kind of FooEvent
     got: FooEvent
})
      end

      specify do
        expect(FooEvent.new(data: { baz: "bar" })).to matcher(FooEvent).with_data({ baz: "bar" })
      end

      specify do
        expect(FooEvent.new(data: { baz: "bar" })).not_to matcher(FooEvent).with_data({ baz: "foo" })
      end

      specify do
        expect(FooEvent.new(data: { baz: "bar" })).not_to matcher(FooEvent).with_data({ foo: "bar" })
      end

      specify do
        _matcher = matcher(FooEvent).with_data({ foo: "bar"})
        _matcher.matches?(FooEvent.new)
        expect(_matcher.failure_message).to eq(%q{
expected: FooEvent with data: {:foo=>"bar"}
     got: FooEvent with data: {}

Data diff:
@@ -1,2 +1,2 @@
-{:foo=>"bar"}
+{}
})
      end

      specify do
        expect(FooEvent.new(metadata: { baz: "bar" })).to matcher(FooEvent).with_metadata({ baz: "bar" })
      end

      specify do
        expect(FooEvent.new(metadata: { baz: "bar" })).not_to matcher(FooEvent).with_metadata({ baz: "foo" })
      end

      specify do
        expect(FooEvent.new(metadata: { baz: "bar" })).not_to matcher(FooEvent).with_metadata({ foo: "bar" })
      end

      specify do
        _matcher = matcher(FooEvent).with_metadata({ foo: "bar"})
        _matcher.matches?(FooEvent.new)
        expect(_matcher.failure_message).to eq(%q{
expected: FooEvent with metadata: {:foo=>"bar"}
     got: FooEvent with metadata: {}

Metadata diff:
@@ -1,2 +1,2 @@
-{:foo=>"bar"}
+{}
})
      end

      specify do
        _matcher = matcher(FooEvent).with_data({ foo: "bar" }).with_metadata({ bar: "baz"})
        _matcher.matches?(FooEvent.new)
        expect(_matcher.failure_message).to eq(%q{
expected: FooEvent with metadata: {:bar=>"baz"} data: {:foo=>"bar"}
     got: FooEvent with metadata: {} data: {}

Metadata diff:
@@ -1,2 +1,2 @@
-{:bar=>"baz"}
+{}

Data diff:
@@ -1,2 +1,2 @@
-{:foo=>"bar"}
+{}
})
      end

      specify do
        _matcher = matcher(FooEvent).with_data({ foo: "bar" }).with_metadata({ bar: "baz"})
        _matcher.matches?(FooEvent.new(data: { bar: "baz" }, metadata: { baz: "foo" }))
        expect(_matcher.failure_message).to eq(%q{
expected: FooEvent with metadata: {:bar=>"baz"} data: {:foo=>"bar"}
     got: FooEvent with metadata: {:baz=>"foo"} data: {:bar=>"baz"}

Metadata diff:
@@ -1,2 +1,2 @@
-{:bar=>"baz"}
+{:baz=>"foo"}

Data diff:
@@ -1,2 +1,2 @@
-{:foo=>"bar"}
+{:bar=>"baz"}
})
      end
    end
  end
end
