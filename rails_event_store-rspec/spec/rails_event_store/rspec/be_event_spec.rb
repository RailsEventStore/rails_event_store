require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe BeEvent do
      def matcher(expected)
        BeEvent.new(expected, differ: colorless_differ, formatter: formatter)
      end

      def colorless_differ
        ::RSpec::Support::Differ.new(color: false)
      end

      def formatter
        ::RSpec::Support::ObjectFormatter.method(:format)
      end

      specify do
        expect(FooEvent.new).to matcher(FooEvent)
      end

      specify do
        expect(FooEvent.new).not_to matcher(BarEvent)
      end

      specify do
        matcher_ = matcher(FooEvent)
        matcher_.matches?("Not an Event object")
        expect(matcher_.failure_message).to eq(%q{
expected: FooEvent
     got: String
})
      end

      specify do
        matcher_ = matcher(FooEvent)
        matcher_.matches?(BarEvent.new)

        expect(matcher_.failure_message).to eq(%q{
expected: FooEvent
     got: BarEvent
})
      end

      specify do
        matcher_ = matcher(FooEvent)
        matcher_.matches?(FooEvent.new)

        expect(matcher_.failure_message_when_negated).to eq(%q{
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
        matcher_ = matcher(FooEvent).with_data({ foo: "bar"})
        matcher_.matches?(FooEvent.new)
        expect(matcher_.failure_message).to eq(%q{
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
        matcher_ = matcher(FooEvent).with_metadata({ foo: "bar"})
        matcher_.matches?(FooEvent.new)
        expect(matcher_.failure_message).to eq(%q{
expected: FooEvent with metadata: {:foo=>"bar"}
     got: FooEvent with metadata: {}

Metadata diff:
@@ -1,2 +1,2 @@
-{:foo=>"bar"}
+{}
})
      end

      specify do
        matcher_ = matcher(FooEvent).with_data({ foo: "bar" }).with_metadata({ bar: "baz"})
        matcher_.matches?(FooEvent.new)
        expect(matcher_.failure_message).to eq(%q{
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
        matcher_ = matcher(FooEvent).with_data({ foo: "bar" }).with_metadata({ bar: "baz"})
        matcher_.matches?(FooEvent.new(data: { bar: "baz" }, metadata: { baz: "foo" }))
        expect(matcher_.failure_message).to eq(%q{
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

      specify { expect(matcher(FooEvent).description).to eq("be an event FooEvent") }

      specify { expect(matcher(kind_of(FooEvent)).description).to eq("be an event kind of FooEvent") }

      specify do
        expect(matcher(FooEvent).with_data(foo: kind_of(String)).description)
            .to eq("be an event FooEvent (with data including {:foo=>kind of String})")
      end

      specify do
        expect(matcher(FooEvent).with_data(foo: "bar").description)
          .to eq("be an event FooEvent (with data including {:foo=>\"bar\"})")
      end

      specify do
        expect(matcher(FooEvent).with_data(foo: "bar").strict.description)
          .to eq("be an event FooEvent (with data matching {:foo=>\"bar\"})")
      end

      specify do
        expect(matcher(FooEvent).with_metadata(foo: kind_of(String)).description)
            .to eq("be an event FooEvent (with metadata including {:foo=>kind of String})")
      end

      specify do
        expect(matcher(FooEvent).with_metadata(foo: "bar").description)
          .to eq("be an event FooEvent (with metadata including {:foo=>\"bar\"})")
      end

      specify do
        expect(matcher(FooEvent).with_metadata(foo: "bar").strict.description)
          .to eq("be an event FooEvent (with metadata matching {:foo=>\"bar\"})")
      end

      specify do
        expect(matcher(FooEvent).with_metadata(foo: "bar").with_data(bar: "foo").description)
          .to eq("be an event FooEvent (with data including {:bar=>\"foo\"} and with metadata including {:foo=>\"bar\"})")
      end

      specify do
        expect(matcher(FooEvent).with_data(bar: "foo").with_metadata(foo: "baz").strict.description)
            .to eq("be an event FooEvent (with data matching {:bar=>\"foo\"} and with metadata matching {:foo=>\"baz\"})")
      end
    end
  end
end
