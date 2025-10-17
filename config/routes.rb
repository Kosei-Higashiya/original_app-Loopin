Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # 開発環境でのみLetterOpenerWebをマウント
  mount LetterOpenerWeb::Engine, at: '/letter_opener' if Rails.env.development?

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Defines the root path route ("/")
  root 'home#index'

  # Dashboard route for the main app page
  get 'dashboard' => 'home#dashboard'

  # 習慣関連のルーティング
  resources :habits do
    member do
      get :calendar, to: 'habits#individual_calendar'
      post :toggle_record_for_date, to: 'habits#toggle_record_for_date'
    end
    resources :habit_records, except: %i[index new edit]
  end

  # ポスト関連のルーティング
  resources :posts, only: %i[index new create edit update destroy] do
    resource :like, only: %i[create destroy]
    collection do
      get :liked
    end
  end

  # バッジ関連のルーティング
  resources :badges, only: %i[index show]
end
