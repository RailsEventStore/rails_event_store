# frozen_string_literal: true

module RubyEventStore
  module RSpec
    module CrudeFailureMessageFormatter
      def self.have_published
        HavePublished::CrudeFailureMessageFormatter
      end
    end
  end
end
