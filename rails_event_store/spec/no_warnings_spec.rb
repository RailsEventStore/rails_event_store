require "spec_helper"

module RubyEventStore
  RSpec.describe "no warnings" do
    specify { expect(rails_event_store_warnings).to eq([]) }

    def rails_event_store_warnings
      warnings.select { |w| w =~ %r{lib/rails_event_store} }
    end

    def warnings
      `ruby -Ilib -w lib/rails_event_store.rb 2>&1`.split("\n")
    end
  end
end
