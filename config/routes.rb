Rails.application.routes.draw do
  resources :activities

  get "up" => "rails/health#show", as: :rails_health_check

  root "activities#index"
end
