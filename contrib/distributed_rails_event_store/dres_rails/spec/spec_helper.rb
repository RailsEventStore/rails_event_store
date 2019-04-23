require_relative '../../../../support/helpers/rspec_defaults'
require_relative '../../../../support/helpers/migrator'
require_relative '../../../../support/helpers/schema_helper'

$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveJob::Base.logger = nil unless $verbose
ActiveRecord::Schema.verbose = $verbose