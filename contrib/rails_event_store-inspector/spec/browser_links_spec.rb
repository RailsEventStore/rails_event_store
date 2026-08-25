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
