require 'timeout'

RSpec.configure do |config|
  config.around(:each) do |example|
    Timeout.timeout(10, &example)
  end
end