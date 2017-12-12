Rails.application.routes.draw do
  mount RailsEventStore::Browser::Engine => "/rails_event_store-browser"
end
