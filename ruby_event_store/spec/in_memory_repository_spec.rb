require 'spec_helper'
require 'ruby_event_store/spec/event_repository_lint'

module RubyEventStore
  RSpec.describe InMemoryRepository do
    # There is no way to use in-memory adapter in a
    # lock-free, unlimited concurrency way
    let(:test_race_conditions_any)   { false }
    let(:test_race_conditions_auto)  { true }
    let(:test_expected_version_auto) { true }

    it_behaves_like :event_repository, InMemoryRepository

    def verify_conncurency_assumptions
    end

    def cleanup_concurrency_test
    end

    def additional_limited_concurrency_for_auto_check
    end
  end
end
