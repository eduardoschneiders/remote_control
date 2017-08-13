Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  get '/block', to: 'application#block'
  get '/unblock', to: 'application#unblock'
end
