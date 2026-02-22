Rails.application.routes.draw do
  resource :session, only: [ :new, :create, :destroy ] do
    post :challenge, on: :collection
  end

  resources :activities

  get "up" => "rails/health#show", as: :rails_health_check

  root "activities#index"
end
