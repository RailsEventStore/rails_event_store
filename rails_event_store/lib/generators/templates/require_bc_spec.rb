require 'rails_helper'

path = Rails.root.join('<%= bounded_context_name %>/spec')
Dir.glob("#{path}/**/*_spec.rb") do |file|
  require file
end
