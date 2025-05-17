# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe EventTypeResolver do
    specify "resolves event type from class" do
      expect(EventTypeResolver.new.call(TestEvent)).to eq("TestEvent")
    end
  end
end
