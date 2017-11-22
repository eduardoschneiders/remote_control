Rails.application.routes.draw do
  root "planes#index"
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/block', to: 'application#block'
  get '/unblock', to: 'application#unblock'

  get '/planes', to: 'planes#index'
  get '/planes/:plane_name/try_to_reserve/:seat_number', to: 'planes#try_to_reserve', as: :try_to_reserve
  post '/planes/reserved', to: 'planes#reserved', as: :reserved

  get '/signup', to: 'users#signup'
end
