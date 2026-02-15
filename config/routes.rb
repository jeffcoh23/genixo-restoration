Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # Auth
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # Dashboard
  get "dashboard", to: "dashboard#show", as: :dashboard

  # Incidents
  resources :incidents, only: %i[index new create show]

  # Properties
  resources :properties, only: %i[index new create show edit update] do
    resources :assignments, controller: "property_assignments", only: %i[create destroy]
  end

  # Organizations
  resources :organizations, only: %i[index new create show edit update]

  # Users
  resources :users, only: %i[index show] do
    member do
      patch :deactivate
      patch :reactivate
    end
  end

  # Invitations
  resources :invitations, only: %i[create] do
    member do
      patch :resend
    end
  end
  get "invitations/:token", to: "invitations#show", as: :invitation
  post "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation

  # Settings
  get "settings", to: "settings#show", as: :settings
  get "settings/on-call", to: "settings#on_call", as: :on_call_settings
  get "settings/equipment-types", to: "settings#equipment_types", as: :equipment_types_settings

  root "sessions#new"
end
