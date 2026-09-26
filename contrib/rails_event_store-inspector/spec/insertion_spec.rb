# frozen_string_literal: true

module RailsEventStore
  module Inspector
    ::RSpec.describe Insertion do
      class RecordingProxy
        def initialize = @operations = []
        attr_reader :operations

        def use(middleware, *args) = @operations << [:use, middleware, args]
      end

      specify "attaches the panel innermost, closest to the application" do
        proxy = RecordingProxy.new

        Insertion.call(proxy, Middleware)

        expect(proxy.operations).to eq([[:use, Middleware, []]])
      end

      specify "names no anchor middleware, so no application can boot-fail on it" do
        proxy = RecordingProxy.new

        Insertion.call(proxy, Middleware)

        expect(proxy).not_to respond_to(:insert_after)
      end
    end
  end
end
