require_relative '../../../../lib/rspec_defaults'
require_relative '../../../../lib/migrator'
require_relative '../../../../lib/schema_helper'

$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveJob::Base.logger = nil unless $verbose
ActiveRecord::Schema.verbose = $verbose