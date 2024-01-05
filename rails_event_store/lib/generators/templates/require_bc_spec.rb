# frozen_string_literal: true

require "rails_helper"

path = Rails.root.join("<%= bounded_context_name %>/spec")
Dir.glob("#{path}/**/*_spec.rb") { |file| require file }
