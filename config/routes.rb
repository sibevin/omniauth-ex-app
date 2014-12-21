Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "users/omniauth_callbacks" }

  namespace :users do
    resources :mail, controller: "omniauth_mail", only: [:new, :create]
  end

  root 'home#index'
end
