# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
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

      specify { expect(FooEvent.new).to matcher(FooEvent) }

      specify { expect(FooEvent.new).not_to matcher(BarEvent) }

      specify do
        matcher_ = matcher(FooEvent)
        matcher_.matches?("Not an Event object")
        expect(matcher_.failure_message).to eq(
          "
expected: FooEvent
     got: String
",
        )
      end

      specify do
        matcher_ = matcher(FooEvent)
        matcher_.matches?(BarEvent.new)

        expect(matcher_.failure_message).to eq(
          "
expected: FooEvent
     got: BarEvent
",
        )
      end

      specify do
        matcher_ = matcher(FooEvent)
        matcher_.matches?(FooEvent.new)

        expect(matcher_.failure_message_when_negated).to eq(
          "
expected: not a kind of FooEvent
     got: FooEvent
",
        )
      end

      specify { expect(FooEvent.new(data: { baz: "bar" })).to matcher(FooEvent).with_data({ baz: "bar" }) }

      specify do
        expect(FooEvent.new(data: { baz: "bar", irrelevant: "ignore" })).to matcher(FooEvent).with_data({ baz: "bar" })
      end

      specify { expect(FooEvent.new(data: { baz: "bar" })).not_to matcher(FooEvent).with_data({ baz: "foo" }) }

      specify { expect(FooEvent.new(data: { baz: "bar" })).not_to matcher(FooEvent).with_data({ foo: "bar" }) }

      specify do
        matcher_ = matcher(FooEvent).with_data({ foo: "bar" })
        matcher_.matches?(FooEvent.new)
        expect(matcher_.failure_message).to eq(
          "
expected: FooEvent with data: #{formatter[foo: "bar"]}
     got: FooEvent with data: {}

Data diff:
@@ -1,2 +1,2 @@
-#{formatter[foo: "bar"]}
+{}
",
        )
      end

      specify { expect(FooEvent.new(metadata: { baz: "bar" })).to matcher(FooEvent).with_metadata({ baz: "bar" }) }

      specify do
        expect(FooEvent.new(metadata: { baz: "bar", timestamp: Time.now })).to matcher(FooEvent).with_metadata(
          { baz: "bar" },
        )
      end

      specify { expect(FooEvent.new(metadata: { baz: "bar" })).not_to matcher(FooEvent).with_metadata({ baz: "foo" }) }

      specify { expect(FooEvent.new(metadata: { baz: "bar" })).not_to matcher(FooEvent).with_metadata({ foo: "bar" }) }

      specify do
        matcher_ = matcher(FooEvent).with_metadata({ foo: "bar" })
        matcher_.matches?(FooEvent.new)
        expect(matcher_.failure_message).to eq(
          "
expected: FooEvent with metadata: #{formatter[foo: "bar"]}
     got: FooEvent with metadata: {}

Metadata diff:
@@ -1,2 +1,2 @@
-#{formatter[foo: "bar"]}
+{}
",
        )
      end

      specify do
        matcher_ = matcher(FooEvent).with_data({ foo: "bar" }).with_metadata({ bar: "baz" })
        matcher_.matches?(FooEvent.new)
        expect(matcher_.failure_message).to eq(
          "
expected: FooEvent with metadata: #{formatter[bar: "baz"]} data: #{formatter[foo: "bar"]}
     got: FooEvent with metadata: {} data: {}

Metadata diff:
@@ -1,2 +1,2 @@
-#{formatter[bar: "baz"]}
+{}

Data diff:
@@ -1,2 +1,2 @@
-#{formatter[foo: "bar"]}
+{}
",
        )
      end

      specify do
        matcher_ = matcher(FooEvent).with_data({ foo: "bar" }).with_metadata({ bar: "baz" })
        matcher_.matches?(FooEvent.new(data: { bar: "baz" }, metadata: { baz: "foo" }))
        expect(matcher_.failure_message).to eq(
          "
expected: FooEvent with metadata: #{formatter[bar: "baz"]} data: #{formatter[foo: "bar"]}
     got: FooEvent with metadata: #{formatter[baz: "foo"]} data: #{formatter[bar: "baz"]}

Metadata diff:
@@ -1,2 +1,2 @@
-#{formatter[bar: "baz"]}
+#{formatter[baz: "foo"]}

Data diff:
@@ -1,2 +1,2 @@
-#{formatter[foo: "bar"]}
+#{formatter[bar: "baz"]}
",
        )
      end

      specify do
        expect(FooEvent.new(metadata: { baz: "bar" })).to matcher(FooEvent).with_metadata({ baz: kind_of(String) })
      end

      specify do
        expect(FooEvent.new(metadata: { baz: 99 })).not_to matcher(FooEvent).with_metadata({ baz: kind_of(String) })
      end

      specify do
        expect(FooEvent.new(data: { foo: "bar" }, metadata: { timestamp: Time.now })).to(
          matcher(FooEvent).with_data(foo: "bar").and(matcher(FooEvent).with_metadata(timestamp: kind_of(Time))),
        )
      end

      specify do
        expect(FooEvent.new(data: { foo: "bar", baz: "bar" })).not_to matcher(FooEvent).with_data(foo: "bar").strict
      end

      specify do
        expect(FooEvent.new(metadata: { foo: "bar", baz: "bar" })).not_to matcher(FooEvent).with_metadata(
          foo: "bar",
        ).strict
      end

      specify do
        expect(FooEvent.new(data: { foo: "bar" }, metadata: { timestamp: Time.now, foo: "bar" })).to(
          matcher(FooEvent).with_data(foo: "bar").strict.and(matcher(FooEvent).with_metadata(foo: "bar")),
        )
      end

      specify { expect(matcher(FooEvent).description).to eq("be an event FooEvent") }

      specify { expect(matcher(kind_of(FooEvent)).description).to eq("be an event kind of FooEvent") }

      specify do
        expect(matcher(FooEvent).with_data(foo: kind_of(String)).description).to eq(
          "be an event FooEvent (with data including #{formatter[foo: kind_of(String)]})",
        )
      end

      specify do
        expect(matcher(FooEvent).with_data(foo: "bar").description).to eq(
          "be an event FooEvent (with data including #{formatter[foo: "bar"]})",
        )
      end

      specify do
        expect(matcher(FooEvent).with_data(foo: "bar").strict.description).to eq(
          "be an event FooEvent (with data matching #{formatter[foo: "bar"]})",
        )
      end

      specify do
        expect(matcher(FooEvent).with_metadata(foo: kind_of(String)).description).to eq(
          "be an event FooEvent (with metadata including #{formatter[foo: kind_of(String)]})",
        )
      end

      specify do
        expect(matcher(FooEvent).with_metadata(foo: "bar").description).to eq(
          "be an event FooEvent (with metadata including #{formatter[foo: "bar"]})",
        )
      end

      specify do
        expect(matcher(FooEvent).with_metadata(foo: "bar").strict.description).to eq(
          "be an event FooEvent (with metadata matching #{formatter[foo: "bar"]})",
        )
      end

      specify do
        expect(matcher(FooEvent).with_metadata(foo: "bar").with_data(bar: "foo").description).to eq(
          "be an event FooEvent (with data including #{formatter[bar: "foo"]} and with metadata including #{formatter[foo: "bar"]})",
        )
      end

      specify do
        expect(matcher(FooEvent).with_data(bar: "foo").with_metadata(foo: "baz").strict.description).to eq(
          "be an event FooEvent (with data matching #{formatter[bar: "foo"]} and with metadata matching #{formatter[foo: "baz"]})",
        )
      end
    end
  end
end
