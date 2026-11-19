# frozen_string_literal: true

module RailsEventStore
  module Inspector
    ::RSpec.describe "memoized browser links" do
      after { Inspector.reset_browser_links! }

      specify "are resolved once and kept" do
        expect(Inspector.browser_links).to be(Inspector.browser_links)
      end

      specify "are resolved again after a reset" do
        before_reset = Inspector.browser_links

        Inspector.reset_browser_links!

        expect(Inspector.browser_links).not_to be(before_reset)
      end

      specify "pick up a Browser mounted while the server was already running" do
        Inspector.instance_variable_set(:@browser_links, BrowserLinks.new(nil))
        expect(Inspector.browser_links.event("e1")).to be_nil

        Inspector.reset_browser_links!
        allow(BrowserLinks).to receive(:from_rails).and_return(BrowserLinks.new("/res"))

        expect(Inspector.browser_links.event("e1")).to eq("/res/events/e1")
      end

      specify "resetting them is not part of the deal" do
        Inspector.buffer.push(kind: :event)
        Inspector.configuration.enabled = ->(_env) { :marker }

        Inspector.reset_browser_links!

        expect(Inspector.buffer.to_a).not_to be_empty
        expect(Inspector.configuration.enabled.call({})).to eq(:marker)
      end
    end
  end
end
