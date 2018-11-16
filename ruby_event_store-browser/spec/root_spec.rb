require 'spec_helper'

module RubyEventStore
  RSpec.describe Browser do
    include Rack::Test::Methods

    specify do
      get '/'
      expect(last_response).to be_ok
    end

    def app
      APP_BUILDER.call(RubyEventStore::Client.new(repository: RubyEventStore::InMemoryRepository.new))
    end
  end
end
