Rails.application.routes.draw do
  resources :mpesas
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post 'pay', to: 'mpesas#stkpush'
  post 'payment_query', to: 'mpesas#stkquery'
  post 'b2c', to: 'mpesas#b2c'
  post '/callback', to: 'mpesas#mpesa_callback'
end
