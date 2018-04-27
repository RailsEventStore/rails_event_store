require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe BeEvent do
      def matcher(expected)
        BeEvent.new(expected, differ: colorless_differ)
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(color: false)
      end

      specify do
        expect(FooEvent.new).to matcher(FooEvent)
      end

      specify do
        expect(FooEvent.new).not_to matcher(BarEvent)
      end

      specify do
        _matcher = matcher(FooEvent)
        _matcher.matches?("Not an Event object")
        expect(_matcher.failure_message).to eq(%q{
expected: FooEvent
     got: String
})
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
        expect(FooEvent.new(data: { baz: "bar", irrelevant: "ignore" })).to matcher(FooEvent).with_data({ baz: "bar" })
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
        expect(FooEvent.new(metadata: { baz: "bar", timestamp: Time.now })).to matcher(FooEvent).with_metadata({ baz: "bar" })
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

      specify do
        expect(FooEvent.new(metadata: { baz: "bar" })).to matcher(FooEvent).with_metadata({ baz: kind_of(String) })
      end

      specify do
        expect(FooEvent.new(metadata: { baz: 99 })).not_to matcher(FooEvent).with_metadata({ baz: kind_of(String) })
      end

      specify do
        expect(FooEvent.new(data: { foo: "bar" }, metadata: { timestamp: Time.now }))
          .to(matcher(FooEvent).with_data(foo: "bar")
            .and(matcher(FooEvent).with_metadata(timestamp: kind_of(Time))))
      end

      specify { expect(FooEvent.new(data: { foo: "bar", baz: "bar" })).not_to matcher(FooEvent).with_data(foo: "bar").strict }
      specify { expect(FooEvent.new(metadata: { foo: "bar", baz: "bar" })).not_to matcher(FooEvent).with_metadata(foo: "bar").strict }

      specify do
        expect(FooEvent.new(data: { foo: "bar" }, metadata: { timestamp: Time.now, foo: "bar" }))
          .to(matcher(FooEvent).with_data(foo: "bar").strict
            .and(matcher(FooEvent).with_metadata(foo: "bar")))
      end
    end
  end
end
