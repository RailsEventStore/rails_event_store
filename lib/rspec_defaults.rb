require_relative 'silence_warnings'

RSpec.configure do |config|
  config.include SilenceWarnings

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior     = :apply_to_host_groups
  config.example_status_persistence_file_path = '.rspec_status'
  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed
end
