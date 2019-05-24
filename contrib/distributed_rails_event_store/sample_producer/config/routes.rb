Rails.application.routes.draw do
  mount RailsEventStore::Browser => '/res' if Rails.env.development?

  class CanSeeResEvents
    def matches?(request)
      request.headers["HTTP_RES_API_KEY"] == ENV['DRES_API_KEY']
    end
  end
  mount DresRails::Engine => "/res_events", constraints: CanSeeResEvents.new
end
