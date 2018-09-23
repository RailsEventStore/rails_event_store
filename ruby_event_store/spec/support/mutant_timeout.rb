require 'timeout'

RSpec.configure do |config|
  config.around(:each) do |example|
    if ENV["MUTATING"]
      timeout = example.metadata[:timeout] || 5
      Timeout.timeout(timeout, &example)
    else
      example.call
    end
  end
end
