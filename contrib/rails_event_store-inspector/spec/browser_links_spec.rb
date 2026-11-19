# frozen_string_literal: true

module RailsEventStore
  module Inspector
    ::RSpec.describe BrowserLinks do
      describe "when the Browser is not mounted" do
        let(:links) { BrowserLinks.new(nil) }

        specify { expect(links.event("e1")).to be_nil }
        specify { expect(links.by_correlation("c1")).to be_nil }
      end

      describe "when the Browser is mounted" do
        let(:links) { BrowserLinks.new("/res") }

        specify { expect(links.event("e1")).to eq("/res/events/e1") }
        specify { expect(links.event(nil)).to be_nil }
        specify { expect(links.by_correlation("c1")).to eq("/res/streams/%24by_correlation_id_c1") }
        specify { expect(links.by_correlation(nil)).to be_nil }

        specify "escapes what would otherwise break the url" do
          expect(links.event("a/b?c")).to eq("/res/events/a%2Fb%3Fc")
        end
      end

      describe "swimlane" do
        let(:links) { BrowserLinks.new("/res") }

        specify "offered when the installed Browser serves that route" do
          allow(links).to receive(:swimlane_available?).and_return(true)

          expect(links.swimlane(["a", "b"])).to eq("/res/swimlane?streams[]=a&streams[]=b")
        end

        specify "withheld when the installed Browser does not know it" do
          allow(links).to receive(:swimlane_available?).and_return(false)

          expect(links.swimlane(["a"])).to be_nil
        end

        specify "withheld when there are no streams to show" do
          allow(links).to receive(:swimlane_available?).and_return(true)

          expect(links.swimlane([])).to be_nil
        end

        specify "withheld when the Browser is not mounted" do
          expect(BrowserLinks.new(nil).swimlane(["a"])).to be_nil
        end

        specify "detected from the gem rather than from a version number" do
          stub_const("RubyEventStore::Browser::Urls", Class.new { def swimlane_url(*) = nil })

          expect(BrowserLinks.new("/res").swimlane_available?).to be(true)
        end

        specify "absent when the Browser has no such helper" do
          stub_const("RubyEventStore::Browser::Urls", Class.new)

          expect(BrowserLinks.new("/res").swimlane_available?).to be(false)
        end
      end

      describe "discovering the mount point" do
        specify "gives nothing when Rails is absent" do
          expect(BrowserLinks.discover_root).to be_nil
        end

        specify "gives nothing rather than raising when the routes cannot be read" do
          stub_const("Rails", double(application: double))
          allow(Rails.application).to receive(:routes).and_raise("no routes here")

          expect(BrowserLinks.discover_root).to be_nil
        end
      end
    end
  end
end
