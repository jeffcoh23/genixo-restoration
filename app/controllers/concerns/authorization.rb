module Authorization
  extend ActiveSupport::Concern

  private

  # --- Visibility scopes ---

  def visible_properties
    case current_user.user_type
    when User::MANAGER, User::OFFICE_SALES
      Property.where(mitigation_org_id: current_user.organization_id)
    when User::TECHNICIAN
      Property.joins(incidents: :incident_assignments)
              .where(incident_assignments: { user_id: current_user.id })
              .distinct
    when *User::PM_TYPES
      Property.joins(:property_assignments)
              .where(property_assignments: { user_id: current_user.id })
    end
  end

  def visible_incidents
    case current_user.user_type
    when User::MANAGER, User::OFFICE_SALES
      Incident.joins(:property)
              .where(properties: { mitigation_org_id: current_user.organization_id })
    when User::TECHNICIAN
      Incident.joins(:incident_assignments)
              .where(incident_assignments: { user_id: current_user.id })
    when *User::PM_TYPES
      property_ids = PropertyAssignment.where(user_id: current_user.id).select(:property_id)
      incident_ids = IncidentAssignment.where(user_id: current_user.id).select(:incident_id)
      Incident.where(property_id: property_ids).or(Incident.where(id: incident_ids))
    end
  end

  # --- Record finders (404 if not in scope) ---

  def find_visible_incident!(id)
    visible_incidents.find(id)
  end

  def find_visible_property!(id)
    visible_properties.find(id)
  end

  # --- Permission checks (backed by Permissions model) ---

  def can_create_incident?
    current_user.can?(Permissions::CREATE_INCIDENT)
  end

  def can_transition_status?
    current_user.can?(Permissions::TRANSITION_STATUS)
  end

  def can_create_property?
    current_user.can?(Permissions::CREATE_PROPERTY)
  end

  def can_view_properties?
    current_user.can?(Permissions::VIEW_PROPERTIES)
  end

  def can_manage_organizations?
    current_user.can?(Permissions::MANAGE_ORGANIZATIONS)
  end

  def can_manage_users?
    current_user.can?(Permissions::MANAGE_USERS)
  end

  def can_create_labor?
    current_user.can?(Permissions::CREATE_LABOR)
  end

  def can_create_equipment?
    current_user.can?(Permissions::CREATE_EQUIPMENT)
  end

  def can_create_operational_note?
    current_user.can?(Permissions::CREATE_OPERATIONAL_NOTE)
  end

  # --- Resource-scoped checks (need a specific record) ---

  def mitigation_admin?
    current_user.organization.mitigation? &&
      current_user.can?(Permissions::CREATE_PROPERTY)
  end

  def mitigation_user?
    current_user.organization.mitigation?
  end

  def can_edit_property?(property)
    return true if mitigation_admin?
    current_user.pm_user? && property.assigned_users.exists?(id: current_user.id)
  end

  def can_assign_to_property?(property)
    return true if mitigation_admin?
    current_user.pm_user? && property.assigned_users.exists?(id: current_user.id)
  end
end
