require 'rails_helper'

path = Rails.root.join('orders/spec')
Dir.glob("#{path}/**/*_spec.rb") do |file|
  require file
end
