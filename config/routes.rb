Rails.application.routes.draw do
  resource :session, only: [ :new, :create, :destroy ] do
    post :challenge, on: :collection
  end

  resource :profile, only: [ :show, :edit, :update ]

  resources :activities do
    patch :quick_update, on: :member
    post :duplicate, on: :member
    post :estimate_calories, on: :collection
    get :diet_tips, on: :collection
  end

  get "up" => "rails/health#show", as: :rails_health_check

  root "activities#index"
end
