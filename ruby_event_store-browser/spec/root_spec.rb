require 'spec_helper'

module RubyEventStore
  RSpec.describe Browser, type: :request do
    include SchemaHelper

    before { load_database_schema }

    specify do
      get '/'
      expect(last_response).to be_ok
    end
  end
end
