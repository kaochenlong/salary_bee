Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :users, only: [ :new, :create ]

  get "dashboard", to: "dashboard#index"
  resources :companies

  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"
  get "welcome", to: "home#index", as: :welcome
end
