Rails.application.routes.draw do
  root 'main#home'
  get 'main/home'
  get 'main/workorder'
  get 'main/new_staff_event'
  match 'new_staff_event', to: 'main#new_staff_event', as: 'new_staff_event', via: [:get, :post], :format => 'js'
  get 'events/list'
  get 'events/by_room'
  match 'events/create', to: 'events#create', via: [:get, :post]
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  match 'auth/failure', to: redirect('/'), via: [:get, :post]
  match 'signout', to: 'sessions#destroy', as: 'signout', via: [:get, :post]
end