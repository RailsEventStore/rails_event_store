RailsEventStore::Browser::Engine.routes.draw do
  root to: 'root#welcome'

  resources :events,  only: [:index, :show]
  resources :streams, only: [:index, :show]
end
