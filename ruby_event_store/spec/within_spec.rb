require "spec_helper"

module RubyEventStore
  RSpec.describe Client do
    subject(:within) { Client::Within.new(nil, nil) }

    specify "subscribe with handler as object and block" do
      expect do
        within.subscribe(:handler, to: []) do
        end
      end.to raise_error(ArgumentError)
    end

    specify "within without block" do
      client = Client.new(repository: :something)
      expect do
        client.within()
      end.to raise_error(ArgumentError)
    end

  end
end