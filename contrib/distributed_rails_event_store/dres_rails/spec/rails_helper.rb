# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
require File.expand_path "../dummy/config/environment", __FILE__
ENV["RAILS_ROOT"] ||= File.dirname(__FILE__) + "/dummy"

require "spec_helper"
require "rspec/rails"
require "dres_rails"

RSpec.configure do |config|
  config.include AbstractController::Translation
  config.include ActiveSupport::Testing::TimeHelpers
  config.include ActiveJob::TestHelper, type: :job
  config.infer_spec_type_from_file_location!
end
