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
      post :dfr
      get :attachments_page
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
    resources :moisture_readings, only: [] do
      collection do
        post :create_point
        post :batch_save
        patch :update_supervisor
      end
      member do
        patch :update
        delete :destroy
      end
    end
    delete "moisture_points/:id", to: "moisture_readings#destroy_point", as: :moisture_point
    resources :operational_notes, only: %i[create]
    resources :attachments, only: %i[create] do
      collection do
        post :upload_photo
      end
    end
  end

  # Properties
  resources :properties, only: %i[index new create show edit update] do
    resources :assignments, controller: "property_assignments", only: %i[create destroy]
  end

  # Organizations
  resources :organizations, only: %i[index new create show edit update]

  # Users
  resources :users, only: %i[index show update] do
    member do
      patch :deactivate
      patch :reactivate
    end
  end

  # Invitations
  resources :invitations, only: %i[create] do
    member do
      patch :resend
      delete :cancel, action: :destroy
    end
  end
  get "invitations/:token", to: "invitations#show", as: :invitation
  post "invitations/:token/accept", to: "invitations#accept", as: :accept_invitation

  # Settings
  get "settings", to: "settings#show", as: :settings
  patch "settings", to: "settings#update"
  patch "settings/password", to: "settings#update_password", as: :settings_password
  patch "settings/preferences", to: "settings#update_preferences", as: :settings_preferences

  # On-Call (top-level, not nested under settings)
  get "on-call", to: "settings#on_call", as: :on_call_settings
  patch "on-call", to: "settings#update_on_call", as: :update_on_call_settings
  post "on-call/contacts", to: "settings#create_escalation_contact", as: :escalation_contacts
  delete "on-call/contacts/:id", to: "settings#destroy_escalation_contact", as: :escalation_contact
  patch "on-call/contacts/reorder", to: "settings#reorder_escalation_contacts", as: :reorder_escalation_contacts

  # Equipment Items (inventory)
  resources :equipment_items, only: %i[index create update]

  # Equipment Types (top-level, not nested under settings)
  get "equipment-types", to: "settings#equipment_types", as: :equipment_types_settings
  post "equipment-types", to: "settings#create_equipment_type", as: :create_equipment_type
  patch "equipment-types/:id/deactivate", to: "settings#deactivate_equipment_type", as: :deactivate_equipment_type
  patch "equipment-types/:id/reactivate", to: "settings#reactivate_equipment_type", as: :reactivate_equipment_type

  root "incidents#index"
end
