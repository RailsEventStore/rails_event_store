RailsEventStore::Browser::Engine.routes.draw do
  root to: 'root#welcome'

  resources :events,  only: [:index, :show]

  get '/streams/:id(/:position/:direction/:count)', to: "streams#show",  as: :stream
  get '/streams(/:position/:direction/:count)',     to: "streams#index", as: :streams
end
