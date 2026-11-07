Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
  get "/calendar", to: "home#calendar", as: :calendar
  get "households/:household_id/calendar", to: "calendars#show"
  resources :households, only: [] do
    resources :events, only: %i[index create]
    resources :chores, only: %i[index create edit update destroy]
  end
  resources :events, only: %i[update destroy]
  root "home#index"

  get "/signup", to: "registrations#new", as: :signup
  post "/signup", to: "registrations#create"

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"

  delete "/logout", to: "sessions#destroy", as: :logout
  resources :households, only: [ :index, :new, :create, :show ] do
  member do
   patch :regenerate_invite_code
   delete :leave
  end

  resources :household_memberships, only: :destroy
  resource :dashboard, only: :show
  resource :invitation, only: :create, controller: "household_invitations"
    resources :inventory_items, path: "inventory",
            only: %i[index create update destroy] do
     member do
       patch :adjust
     end
    end
    resources :shopping_items, path: "shopping", only: %i[create destroy] do
      member do
        patch :purchase
      end
    end

    resources :expenses do
      member do
        patch :mark_paid  # For marking individual portions as paid
      end
      collection do
        get :balances  # For viewing outstanding balances
      end
    end

    resources :rules do
      member do
        post :vote
        get :amend
        post :amend, to: "rules#create_amendment"
        get :history
      end
    end
  end

  get "/join-household",
      to: "household_joins#new",
      as: :join_household

  post "/join-household",
      to: "household_joins#create"
end
