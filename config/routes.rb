Rails.application.routes.draw do
  resources :mpesas
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post 'pay', to: 'mpesas#stkpush'
  post 'payment_query', to: 'callbacks#stkquery'
  post 'b2c', to: 'b2c_transactions#b2c'
  post 'callback', to: 'callbacks#mpesa_callback'
end
