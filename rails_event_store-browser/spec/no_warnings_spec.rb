require 'spec_helper'

module RubyEventStore
  RSpec.describe 'no warnings' do
    specify do
      expect(rails_event_store_browser_warnings).to eq([])
    end

    def rails_event_store_browser_warnings
      warnings.select { |w| w =~ %r{lib/rails_event_store/browser} }
    end

    def warnings
      `ruby -Ilib -w lib/rails_event_store/browser.rb 2>&1`.split("\n")
    end
  end
end
