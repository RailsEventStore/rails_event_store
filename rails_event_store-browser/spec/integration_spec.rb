require 'spec_helper'

module RailsEventStore
  RSpec.describe Browser, type: :request do
    specify do
      get '/res'
      expect(response).to be_successful
    end
  end
end