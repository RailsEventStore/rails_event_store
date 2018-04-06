require 'timeout'

RSpec.configure do |config|
  config.around(:each) do |example|
    Timeout.timeout(5, &example)
  end
end