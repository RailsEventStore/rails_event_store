# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe "no warnings" do
    specify { expect(ruby_event_store_browser_warnings).to eq([]) }

    def ruby_event_store_browser_warnings
      warnings.select { |w| w =~ %r{lib/ruby_event_store/browser} }
    end

    def warnings
      `ruby -Ilib -w lib/ruby_event_store/browser.rb 2>&1`.split("\n")
    end
  end
end
