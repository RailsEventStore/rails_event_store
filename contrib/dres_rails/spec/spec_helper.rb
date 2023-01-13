require_relative "../../../support/helpers/rspec_defaults"
require_relative "../../../support/helpers/migrator"
require_relative "../../../support/helpers/schema_helper"

ENV["DATABASE_URL"] ||= "postgres://localhost/rails_event_store?pool=5"
ENV["DATA_TYPE"] ||= "binary"

$verbose = ENV.has_key?("VERBOSE") ? true : false
ActiveJob::Base.logger = nil unless $verbose
ActiveRecord::Schema.verbose = $verbose
