require 'spec_helper'

module RubyEventStore
  module Outbox
    RSpec.describe Metrics::Null do
      specify "doesnt do anything" do
        null_metrics = Metrics::Null.new

        null_metrics.write_point_queue(some_keyargs: 42)
      end
    end
  end
end
