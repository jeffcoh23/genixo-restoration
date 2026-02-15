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
        role_label: User::ROLE_LABELS[current_user.user_type],
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
      invitations: invitations_path,
      settings: settings_path,
      on_call: on_call_settings_path,
      equipment_types: equipment_types_settings_path,
      login: login_path,
      logout: logout_path
    }
  }

  inertia_share nav_items: -> {
    nav_items_for_user(current_user)
  }


  private

  # Server-side nav filtering — the client just renders what it receives
  def nav_items_for_user(user)
    return [] unless user

    items = [
      { label: "Dashboard", href: dashboard_path, icon: "LayoutDashboard" },
      { label: "Incidents", href: incidents_path, icon: "AlertTriangle" },
    ]

    if user.can?(Permissions::VIEW_PROPERTIES)
      items << { label: "Properties", href: properties_path, icon: "Building2" }
    end

    if user.can?(Permissions::MANAGE_ORGANIZATIONS)
      items << { label: "Organizations", href: organizations_path, icon: "Building" }
      items << { label: "Users", href: users_path, icon: "Users" }
    end

    if user.can?(Permissions::MANAGE_ON_CALL)
      items << { label: "On-Call", href: on_call_settings_path, icon: "Phone" }
    end

    if user.can?(Permissions::MANAGE_EQUIPMENT_TYPES)
      items << { label: "Equipment Types", href: equipment_types_settings_path, icon: "Wrench" }
    end

    items << { label: "Settings", href: settings_path, icon: "Settings" }

    items
  end
end
