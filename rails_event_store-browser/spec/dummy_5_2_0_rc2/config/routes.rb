Rails.application.routes.draw do
  mount RailsEventStore::Browser::Engine => "/res"
end
