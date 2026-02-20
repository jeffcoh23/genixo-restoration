class ApplicationController < ActionController::Base
  include Authentication
  include Authorization
  include TimeFormatting

  allow_browser versions: :modern

  around_action :set_user_timezone

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

  inertia_share permissions: -> {
    return {} unless current_user
    {
      can_create_incident: can_create_incident?,
      can_transition_status: can_transition_status?,
      can_create_property: can_create_property?,
      can_view_properties: can_view_properties?,
      can_manage_organizations: can_manage_organizations?,
      can_manage_users: can_manage_users?,
      can_create_labor: can_create_labor?,
      can_create_equipment: can_create_equipment?,
      can_create_operational_note: can_create_operational_note?
    }
  }

  inertia_share has_unread_incidents: -> {
    next false unless current_user

    has_any_unread_incidents?
  }

  inertia_share today: -> {
    Time.current.to_date.iso8601
  }

  inertia_share now_datetime: -> {
    format_datetime_value(Time.current)
  }


  private

  # Lightweight check: any visible incident with messages/activity newer than the user's read state?
  def has_any_unread_incidents?
    visible_ids = Incident.visible_to(current_user).select(:id)

    # Check for any unread messages
    has_unread_messages = Message.where(incident_id: visible_ids)
      .where.not(user_id: current_user.id)
      .where(
        "NOT EXISTS (SELECT 1 FROM incident_read_states WHERE incident_read_states.incident_id = messages.incident_id AND incident_read_states.user_id = ? AND incident_read_states.last_message_read_at >= messages.created_at)",
        current_user.id
      ).exists?

    return true if has_unread_messages

    # Check for any unread activity
    ActivityEvent.where(incident_id: visible_ids)
      .where.not(performed_by_user_id: current_user.id)
      .where(
        "NOT EXISTS (SELECT 1 FROM incident_read_states WHERE incident_read_states.incident_id = activity_events.incident_id AND incident_read_states.user_id = ? AND incident_read_states.last_activity_read_at >= activity_events.created_at)",
        current_user.id
      ).exists?
  end

  def set_user_timezone(&block)
    zone = current_user&.timezone || "UTC"
    Time.use_zone(zone, &block)
  end

  # Server-side nav filtering — the client just renders what it receives
  def nav_items_for_user(user)
    return [] unless user

    items = [
      { label: "Incidents", href: incidents_path, icon: "AlertTriangle" }
    ]

    if user.can?(Permissions::VIEW_PROPERTIES)
      items << { label: "Properties", href: properties_path, icon: "Building2" }
    end

    if user.can?(Permissions::MANAGE_ORGANIZATIONS)
      items << { label: "Property Management", href: organizations_path, icon: "Building" }
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
