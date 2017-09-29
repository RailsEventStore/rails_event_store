require 'spec_helper'
require 'ruby_event_store'

RSpec.describe RubyEventStore::InvalidHandler do
  specify "InvalidHandler message" do
    object = Object.new
    inspect = object.inspect
    expect(
      RubyEventStore::InvalidHandler.new(object).message
    ).to eq("#call method not found in #{object.inspect} subscriber. Are you sure it is a valid subscriber?")
  end

  specify "InvalidHandler message" do
    expect(
      RubyEventStore::InvalidHandler.new(:symbol).message
    ).to eq("#call method not found in :symbol subscriber. Are you sure it is a valid subscriber?")
  end
end