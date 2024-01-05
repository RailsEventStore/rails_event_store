# frozen_string_literal: true

ENV["RAILS_ENV"] = "test"

$LOAD_PATH.push File.expand_path("../../../spec", __FILE__)
require File.expand_path("../../../config/environment", __FILE__)
require File.expand_path("../../../spec/rails_helper", __FILE__)

require_relative "../lib/<%= bounded_context_name %>"
