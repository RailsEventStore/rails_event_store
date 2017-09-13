require "spec_helper"

module RailsEventStore
  module RSpec
    ::RSpec.describe Matchers do
      let(:matchers) { Object.new.tap { |o| o.extend(Matchers) } }

      specify { expect(matchers.be_an_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.be_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.an_event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(matchers.event(FooEvent.new)).to be_an(BeEvent) }
      specify { expect(FooEvent.new).to matchers.be_an_event(FooEvent) }
      specify { expect([FooEvent.new]).to include(matchers.an_event(FooEvent)) }

      specify "be_an_event default configuration" do
        matcher = matchers.be_an_event(FooEvent.new)
        differ  = matcher.__send__(:differ)

        expect(differ).to be_an(::RSpec::Support::Differ)
        expect(differ.color?).to eq(::RSpec::Matchers.configuration.color?)
      end

      specify { expect(matchers.have_published(matchers.an_event(FooEvent))).to be_an(HavePublished) }

      specify do
        event_store = RailsEventStore::Client.new(repository: RailsEventStore::InMemoryRepository.new)
        event_store.publish_event(FooEvent.new)
        expect(event_store).to matchers.have_published(matchers.an_event(FooEvent))
      end
    end
  end
end
