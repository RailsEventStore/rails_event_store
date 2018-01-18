RailsEventStore::Browser::Engine.routes.draw do
  root to: 'root#welcome'

  resources :events,  only: [:index, :show]
  resources :streams, only: [:index]

  get '/streams/:id(/:position/:direction/:count)', to: "streams#show", as: :stream
end
