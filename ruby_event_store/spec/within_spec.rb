require "spec_helper"

module RubyEventStore
  RSpec.describe Client do
    subject(:within) { Client::Within.new(nil, nil) }

    specify "subscribe with handler as object and block" do
      expect { within.subscribe(:handler, to: []) {} }.to raise_error(ArgumentError)
    end

    specify "within without block" do
      client = Client.new(repository: :something)
      expect { client.within }.to raise_error(ArgumentError)
    end
  end
end
