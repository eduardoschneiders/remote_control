Rails.application.routes.draw do
  root "planes#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/block', to: 'application#block'
  get '/unblock', to: 'application#unblock'

  get '/planes', to: 'planes#index'
  get '/plane/:id', to: 'planes#show', as: :plane
  get '/planes/:plane_id/try_to_reserve/:seat_number', to: 'planes#try_to_reserve', as: :try_to_reserve
  post '/planes/reserved', to: 'planes#reserved', as: :reserved

  get '/signup', to: 'users#signup'

  get '/admin', to: 'admin#show'
  post '/admin', to: 'admin#create'
end
