require 'rails_helper'

path = Rails.root.join('payments/spec')
Dir.glob("#{path}/**/*_spec.rb") do |file|
  require file
end
