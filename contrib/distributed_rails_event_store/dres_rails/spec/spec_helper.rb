require_relative '../../../../lib/helpers/rspec_defaults'
require_relative '../../../../lib/helpers/migrator'
require_relative '../../../../lib/helpers/schema_helper'

$verbose = ENV.has_key?('VERBOSE') ? true : false
ActiveJob::Base.logger = nil unless $verbose
ActiveRecord::Schema.verbose = $verbose