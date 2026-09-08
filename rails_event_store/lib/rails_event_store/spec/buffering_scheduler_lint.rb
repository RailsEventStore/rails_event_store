# frozen_string_literal: true

RSpec.shared_examples "buffering scheduler" do |scheduler|
  specify "declares itself buffering" do
    expect(RailsEventStore::BufferingScheduler === scheduler).to be(true)
  end

  specify "#ship" do
    expect(scheduler.respond_to?(:ship, true)).to be(true)
  end
end
