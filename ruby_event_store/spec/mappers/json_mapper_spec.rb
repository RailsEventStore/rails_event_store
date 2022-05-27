# frozen_string_literal: true

require "spec_helper"
require "ruby_event_store/spec/mapper_lint"

SomethingHappenedJSON = Class.new(RubyEventStore::Event)

module RubyEventStore
  module Mappers
    RSpec.describe JSONMapper do
      specify { expect { JSONMapper.new }.to output(<<~EOW).to_stderr }
          Please replace RubyEventStore::Mappers::JSONMapper with RubyEventStore::Mappers::Default

          They're now identical and the former will be removed in next major release.
        EOW
    end
  end
end
