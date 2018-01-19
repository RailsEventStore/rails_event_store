require 'spec_helper'

module RailsEventStore
  RSpec.describe Browser, type: :request do
    include SchemaHelper

    before { load_database_schema }

    specify do
      get '/res'
      expect(response).to have_http_status(200)
    end
  end
end
