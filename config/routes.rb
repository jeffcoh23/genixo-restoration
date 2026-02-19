Rails.application.routes.draw do
  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?

  get "up" => "rails/health#show", as: :rails_health_check

  # Auth
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # Password reset
  get "forgot-password", to: "password_resets#new", as: :forgot_password
  post "forgot-password", to: "password_resets#create"
  get "reset-password/:token", to: "password_resets#edit", as: :edit_password_reset
  patch "reset-password/:token", to: "password_resets#update", as: :password_reset

  # Dashboard
  get "dashboard", to: "dashboard#show", as: :dashboard

  # Incidents
  resources :incidents, only: %i[index new create show update] do
    member do
      patch :transition
      patch :mark_read
      get :dfr, defaults: { format: :pdf }
    end
    resources :assignments, controller: "incident_assignments", only: %i[create destroy]
    resources :contacts, controller: "incident_contacts", only: %i[create update destroy]
    resources :messages, only: %i[create]
    resources :activity_entries, only: %i[create update]
    resources :labor_entries, only: %i[create update destroy]
    resources :equipment_entries, only: %i[create update] do
      member do
        patch :remove
      end
    end
    resources :operational_notes, only: %i[create]
    resources :attachments, only: %i[create]
  end

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
  patch "settings", to: "settings#update"
  patch "settings/password", to: "settings#update_password", as: :settings_password
  get "settings/on-call", to: "settings#on_call", as: :on_call_settings
  patch "settings/on-call", to: "settings#update_on_call", as: :update_on_call_settings
  post "settings/on-call/contacts", to: "settings#create_escalation_contact", as: :escalation_contacts
  delete "settings/on-call/contacts/:id", to: "settings#destroy_escalation_contact", as: :escalation_contact
  patch "settings/on-call/contacts/reorder", to: "settings#reorder_escalation_contacts", as: :reorder_escalation_contacts
  patch "settings/preferences", to: "settings#update_preferences", as: :settings_preferences
  get "settings/equipment-types", to: "settings#equipment_types", as: :equipment_types_settings
  post "settings/equipment-types", to: "settings#create_equipment_type", as: :create_equipment_type
  patch "settings/equipment-types/:id/deactivate", to: "settings#deactivate_equipment_type", as: :deactivate_equipment_type
  patch "settings/equipment-types/:id/reactivate", to: "settings#reactivate_equipment_type", as: :reactivate_equipment_type

  root "sessions#new"
end
