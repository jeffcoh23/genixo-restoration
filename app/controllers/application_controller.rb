class ApplicationController < ActionController::Base
  include Authentication
  include Authorization

  allow_browser versions: :modern

  inertia_share flash: -> {
    {
      notice: flash[:notice],
      alert: flash[:alert]
    }
  }

  inertia_share auth: -> {
    {
      user: current_user ? {
        id: current_user.id,
        email: current_user.email_address,
        first_name: current_user.first_name,
        last_name: current_user.last_name,
        full_name: current_user.full_name,
        initials: current_user.initials,
        user_type: current_user.user_type,
        organization_type: current_user.organization.organization_type,
        organization_name: current_user.organization.name,
        timezone: current_user.timezone
      } : nil,
      authenticated: !!current_user
    }
  }

  inertia_share routes: -> {
    {
      dashboard: dashboard_path,
      incidents: incidents_path,
      new_incident: new_incident_path,
      properties: properties_path,
      new_property: new_property_path,
      organizations: organizations_path,
      new_organization: new_organization_path,
      users: users_path,
      settings: settings_path,
      on_call: on_call_settings_path,
      equipment_types: equipment_types_settings_path,
      login: login_path,
      logout: logout_path
    }
  }
end
