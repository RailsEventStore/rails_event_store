# frozen_string_literal: true

require "spec_helper"

module RubyEventStore
  module ActiveRecord
    ::RSpec.describe WithDefaultModels do
      specify do
        event_klass, stream_klass = WithDefaultModels.new.call

        expect(event_klass).to eq(Event)
        expect(stream_klass).to eq(EventInStream)
      end
    end
  end
end
