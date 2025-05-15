# frozen_string_literal: true

module RubyEventStore
  ::RSpec.describe Flipper do
    it "has a version number" do
      expect(RubyEventStore::Flipper::VERSION).not_to be_nil
    end
  end
end
