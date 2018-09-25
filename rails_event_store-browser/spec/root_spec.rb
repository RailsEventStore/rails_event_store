require 'spec_helper'

module RailsEventStore
  RSpec.describe Browser, type: :request do
    include SchemaHelper

    def silence_stderr
      $stderr = StringIO.new
      yield
      $stderr = STDERR
    end

    around(:each) do |example|
      begin
        load_database_schema
        silence_stderr { example.run }
      end
    end

    specify do
      get '/res'
      expect(response).to have_http_status(200)
    end
  end
end
