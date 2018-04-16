RailsEventStore::Browser::Engine.routes.draw do
  root to: 'root#welcome'

  resources :events, only: [:index, :show]

  get '/streams/:id(/:position/:direction/:count)',
    to: "streams#show",
    as: :stream,
    format: false,
    constraints: { id: %r{[^\/]+} }

  resources :streams, only: [:index]
end
