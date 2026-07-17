# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

module RubyEventStore
  module Browser
    ::RSpec.describe Renderer do
      let(:renderer) { Renderer.new }
      let(:context) { Renderer::Context.new(renderer, {}) }

      describe "Context#safe_json" do
        specify { expect(context.safe_json(Float::INFINITY)).to eq('"Infinity"') }
        specify { expect(context.safe_json(-Float::INFINITY)).to eq('"-Infinity"') }
        specify { expect(context.safe_json(0.0 / 0)).to eq('"NaN"') }
        specify { expect(context.safe_json(1.0)).to eq("1") }
        specify { expect(context.safe_json(-2.0)).to eq("-2") }
        specify { expect(context.safe_json(1.5)).to eq("1.5") }
        specify { expect(context.safe_json("hello")).to eq('"hello"') }
        specify { expect(context.safe_json(42)).to eq("42") }
        specify { expect(context.safe_json(nil)).to eq("null") }
        specify { expect(context.safe_json(true)).to eq("true") }
        specify { expect(context.safe_json({ "key" => "value" })).to eq('{"key":"value"}') }
        specify { expect(context.safe_json(["a", 1])).to eq('["a",1]') }
        specify { expect(context.safe_json({ "n" => Float::INFINITY })).to eq('{"n":"Infinity"}') }
        specify { expect(context.safe_json([Float::INFINITY])).to eq('["Infinity"]') }
        specify { expect(context.safe_json([-(Float::INFINITY)])).to eq('["-Infinity"]') }
      end

      describe "Context#render" do
        specify "delegates to renderer" do
          expect(context.render("not_found")).to include("There's no event with given ID")
        end

        specify "passes locals to nested render" do
          urls = Urls.from_configuration("http://example.com", nil)
          expect(
            context.render("layout", content: "marker-content", urls: urls, extension_stylesheets: [], extension_scripts: []),
          ).to include("marker-content")
        end
      end

      describe "multiple view roots" do
        specify "renders template from an additional root, falling back to the default one" do
          Dir.mktmpdir do |root|
            File.write(File.join(root, "custom.html.erb"), "custom content")
            renderer = Renderer.new([root, Renderer::VIEWS_ROOT])
            expect(renderer.render("custom")).to eq("custom content")
            expect(renderer.render("not_found")).to include("There's no event with given ID")
          end
        end

        specify "earlier roots take precedence" do
          Dir.mktmpdir do |root|
            File.write(File.join(root, "not_found.html.erb"), "overridden")
            renderer = Renderer.new([root, Renderer::VIEWS_ROOT])
            expect(renderer.render("not_found")).to eq("overridden")
          end
        end

        specify "raises when template is not found in any root" do
          expect { renderer.render("nonexistent") }.to raise_error(ArgumentError, /nonexistent/)
        end
      end

      describe "Renderer#render" do
        let(:urls) { Urls.from_configuration("http://example.com", nil) }

        specify "makes locals accessible as methods in template" do
          result = renderer.render("layout", content: "body-text", urls: urls, extension_stylesheets: [], extension_scripts: [])
          expect(result).to include("body-text")
          expect(result).to include("http://example.com")
        end

        specify "supports partial rendering from within a template" do
          result = renderer.render("_timestamp", title: "Created at", time: Time.now, top: true)
          expect(result).to include("Created at")
        end

        specify "uses trim_mode dash to suppress blank lines from control tags" do
          event = TimeEnrichment.with(DummyEvent.new)
          result =
            renderer.render(
              "streams/show",
              urls: urls,
              stream_name: "all",
              events: [event],
              pagination: { prev: nil, first: nil, next: nil, last: nil },
              related_streams: [],
              extension_links: [],
            )
          expect(result).not_to match(/\n\s*\n\s*\n/)
        end
      end
    end
  end
end
