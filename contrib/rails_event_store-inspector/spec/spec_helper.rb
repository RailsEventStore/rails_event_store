# frozen_string_literal: true

require "rails_event_store/inspector"

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.order = :random
end
