# frozen_string_literal: true

Rails.application.routes.draw do
  class CanSeeResEvents
    def matches?(request)
      request.headers["HTTP_RES_API_KEY"] == "33bbd0ea-b7ce-49d5-bc9d-198f7884c485"
    end
  end
  mount DresRails::Engine => "/dres_rails", constraints: CanSeeResEvents.new
end