Rails.application.routes.draw do
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "home#index"

  # Dashboard route for the main app page
  get "dashboard" => "home#dashboard"

  # Habits resource routes
   resources :habits do
    member do
      get :calendar, to: 'habits#individual_calendar'
      post :toggle_record_for_date, to: 'habits#toggle_record_for_date'
    end
    resources :habit_records, except: [:index, :new, :edit]
    end

  # Posts resource routes for community posts
  resources :posts, only: [:index, :new, :create, :edit, :update, :destroy]

  # バッジ関連のルーティング
  resources :badges, only: [:index, :show] do
    collection do
      post :check_awards
    end
  end
end
