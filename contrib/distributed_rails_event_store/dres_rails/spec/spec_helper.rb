require_relative '../../../../lib/rspec_defaults'
require_relative '../../../../lib/migrator'
require_relative '../../../../lib/schema_helper'

$stdout = File.new("/dev/null", "w") if ENV["SUPPRESS_STDOUT"] == "enabled"
$stderr = File.new("/dev/null", "w") if ENV["SUPPRESS_STDERR"] == "enabled"