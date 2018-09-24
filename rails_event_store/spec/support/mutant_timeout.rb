require 'timeout'

RSpec.configure do |config|
  config.around(:each) do |example|
    if ENV["MUTATING"]
      Timeout.timeout(10, &example)
    else
      example.call
    end
  end
end
