# frozen_string_literal: true

module RubyEventStore
  module RSpec
    module StepByStepFailureMessageFormatter
      def self.have_published
        HavePublished::StepByStepFailureMessageFormatter
      end
    end
  end
end
