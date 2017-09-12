require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe Matchers do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }

      specify { expect(matchers.be_an_event(BazEvent.new)).to be_an(EventMatcher) }
      specify { expect(matchers.be_event(BazEvent.new)).to be_an(EventMatcher) }
      specify { expect(matchers.an_event(BazEvent.new)).to be_an(EventMatcher) }
      specify { expect(matchers.event(BazEvent.new)).to be_an(EventMatcher) }
      specify { expect(BazEvent.new).to matchers.be_an_event(BazEvent) }
      specify { expect([BazEvent.new]).to include(matchers.an_event(BazEvent)) }

      specify "be_an_event default configuration" do
        matcher = matchers.be_an_event(BazEvent.new)
        differ  = matcher.__send__(:differ)

        expect(differ).to be_an(::RSpec::Support::Differ)
        expect(differ.color?).to eq(::RSpec::Matchers.configuration.color?)
      end
    end
  end
end
