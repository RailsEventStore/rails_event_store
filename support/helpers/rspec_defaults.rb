# frozen_string_literal: true

require_relative "silence_warnings"

RSpec.configure do |config|
  config.include SilenceWarnings

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed

  config.before(:each) { RubyEventStore::Deprecations.reset! if defined?(RubyEventStore::Deprecations) }

  # The global configuration is memoized on first use and its variant is
  # decided then. Leaving it around would make the outcome of an example
  # depend on which kind of client another example happened to build first.
  reset_configuration = -> do
    %w[RubyEventStore RailsEventStore].each do |name|
      Object.const_get(name).instance_variable_set(:@configuration, nil) if Object.const_defined?(name)
    end
  end

  config.around do |example|
    reset_configuration.call
    example.run
  ensure
    reset_configuration.call
  end
end
