require 'spec_helper'

module RubyEventStore
  RSpec.describe Browser do
    include Rack::Test::Methods
    include SchemaHelper

    before { load_database_schema }

    specify do
      get '/'
      expect(last_response).to be_ok
    end
  end
end
