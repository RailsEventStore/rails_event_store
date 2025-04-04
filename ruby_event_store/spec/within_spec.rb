# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  ::RSpec.describe Client do
    subject(:within) { Client::Within.new(nil, nil) }

    specify "subscribe with handler as object and block" do
      expect { within.subscribe(:handler, to: []) {} }.to raise_error(ArgumentError)
    end

    specify "subscribe with handler as object" do
      expect { within.subscribe(:handler, to: []) }.not_to raise_error
    end

    specify "subscribe with handler as block" do
      expect { within.subscribe(to: []) {} }.not_to raise_error
    end

    specify "within without block" do
      client = Client.new(repository: :something)
      expect { client.within }.to raise_error(ArgumentError)
    end
  end
end
