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
          expect(context.render("not_found", message: "There's no event with given ID")).to include(
            "There&#39;s no event with given ID",
          )
        end

        specify "passes locals to nested render" do
          urls = Urls.from_configuration("http://example.com", nil)
          expect(
            context.render("layout", content: "marker-content", urls: urls, extension_stylesheets: [], extension_scripts: [], extension_nav_links: []),
          ).to include("marker-content")
        end
      end

      describe "_json_tree" do
        def tree(hash) = Nokogiri::HTML.fragment(renderer.render("_json_tree", hash: hash))

        specify "renders nested objects in key order and arrays in element order" do
          rows =
            tree({ "owner" => { "tags" => ["z", { "z" => false, "a" => [2, 1] }], "id" => 1 }, active: true })
              .xpath("div/ul/li")

          expect(rows.map { |row| row.at_xpath("span[1]").text }).to eq(%w[active owner])
          expect(rows.first.at_xpath("span[2]").text).to eq("true")

          owner = rows.last.xpath("ul/li")
          expect(owner.map { |row| row.at_xpath("span[1]").text }).to eq(%w[id tags])
          expect(owner.first.at_xpath("span[2]").text).to eq("1")

          tags = owner.last.xpath("ul/li")
          expect(tags.first.at_xpath("span").text).to eq('"z"')

          nested = tags.last.xpath("ul/li")
          expect(nested.map { |row| row.at_xpath("span[1]").text }).to eq(%w[a z])
          expect(nested.first.at_xpath("ul").text).to eq("2,1,")
          expect(nested.last.at_xpath("span[2]").text).to eq("false")
        end

        specify "expands Hash and Array subclasses as collections" do
          hash_class = Class.new(Hash)
          array_class = Class.new(Array)
          html = tree(hash_class["items" => array_class.new([hash_class["id" => 1]])])

          expect(html.at_xpath("div/ul/li/span[1]").text).to eq("items")
          row = html.at_xpath("div/ul/li/ul/li/ul/li")
          expect(row.at_xpath("span[1]").text).to eq("id")
          expect(row.at_xpath("span[2]").text).to eq("1")
        end

        specify "renders empty collections inline" do
          rows = tree({ "object" => {}, "array" => [] }).xpath("div/ul/li")

          expect(rows.map { |row| row.at_xpath("span[2]").text }).to eq(["[]", "{}"])
          expect(rows.flat_map { |row| row.xpath("ul") }).to be_empty
          expect(tree({}).at_xpath("div").text.strip).to eq("{}")
        end

        specify "escapes nested keys and values without changing their text" do
          key = "<img data-json-injection src=x>"
          value = "<script data-json-injection>alert(1)</script>&"
          html = tree({ "outer" => { key => [value, "  a  b  "] } })

          expect(html.css("[data-json-injection]")).to be_empty
          expect(html.at_xpath("div/ul/li/ul/li/span[1]").text).to eq(key)
          expect(html.xpath("div/ul/li/ul/li/ul/li/span").map(&:text)).to eq(
            ['"<script data-json-injection>alert(1)</script>&"', '"  a  b  "'],
          )
        end

        specify "renders JSON scalar values inside collections" do
          html = tree({ "values" => [nil, Float::INFINITY, -Float::INFINITY, Float::NAN, 1.0, 1.25] })

          expect(html.xpath("div/ul/li/ul/li/span").map(&:text)).to eq(
            ["null", '"Infinity"', '"-Infinity"', '"NaN"', "1", "1.25"],
          )
        end

        specify "displays nested JSON with punctuation, indentation, colors and preserved whitespace", :js do
          event_store = Client.new
          event =
            DummyEvent.new(
              data: {
                "a  b" => { "s" => "  x  " },
                "a b" => 2,
                "empty" => [{}, []],
                "values" => [1, 2.5, true, false, nil],
              },
              metadata: { details: { "m  n" => "  metadata  " } },
            )
          event_store.publish(event)
          session = Capybara::Session.new(:cuprite, App.for(event_store_locator: -> { event_store }))

          session.visit("/events/#{event.event_id}")

          raw_data = session.find("section", text: /Raw Data/i).find("div > div")
          presentation = raw_data.evaluate_script(<<~JS)
            (() => {
              const spans = Array.from(this.querySelectorAll("span"));
              const lists = Array.from(this.querySelectorAll("ul"));
              const color = value => getComputedStyle(spans.find(span => span.textContent === value)).color;
              return {
                text: this.innerText,
                colors: ['"  x  "', '1', '2.5', 'true', 'false', 'null'].map(color),
                emptyColors: ['{}', '[]'].map(color),
                surroundingColor: getComputedStyle(this).color,
                indents: lists.map(list => list.getBoundingClientRect().left -
                  (list.parentElement.closest("ul") || this).getBoundingClientRect().left),
                markers: lists.map(list => getComputedStyle(list).listStyleType)
              };
            })()
          JS

          expect(presentation.fetch("text")).to eq(<<~TEXT.chomp)
            {
            a  b: {
            s: "  x  ",
            },
            a b: 2,
            empty: [
            {},
            [],
            ],
            values: [
            1,
            2.5,
            true,
            false,
            null,
            ],
            }
          TEXT
          expect(presentation.fetch("colors")).to eq(
            ["rgb(0, 128, 0)", "rgb(0, 0, 255)", "rgb(0, 0, 255)", "rgb(178, 34, 34)", "rgb(178, 34, 34)", "rgb(128, 128, 128)"],
          )
          expect(presentation.fetch("emptyColors")).to eq([presentation.fetch("surroundingColor")] * 2)
          expect(presentation.fetch("indents")).to eq([26, 26, 26, 26])
          expect(presentation.fetch("markers")).to eq(%w[none none none none])
          raw_metadata = session.find("section", text: /Raw Metadata/i)
          expect(raw_metadata.evaluate_script("this.innerText")).to include('m  n: "  metadata  "')
        rescue Ferrum::BinaryNotFoundError => exc
          skip exc.message
        end
      end

      describe "multiple view roots" do
        specify "renders template from an additional root, falling back to the default one" do
          Dir.mktmpdir do |root|
            File.write(File.join(root, "custom.html.erb"), "custom content")
            renderer = Renderer.new([root, Renderer::VIEWS_ROOT])
            expect(renderer.render("custom")).to eq("custom content")
            expect(renderer.render("not_found", message: "There's no event with given ID")).to include(
              "There&#39;s no event with given ID",
            )
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
          result = renderer.render("layout", content: "body-text", urls: urls, extension_stylesheets: [], extension_scripts: [], extension_nav_links: [])
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
