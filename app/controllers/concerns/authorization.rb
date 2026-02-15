module Authorization
  extend ActiveSupport::Concern

  private

  # --- Visibility scopes ---

  def visible_properties
    case current_user.user_type
    when "manager", "office_sales"
      Property.where(mitigation_org_id: current_user.organization_id)
    when "technician"
      Property.joins(incidents: :incident_assignments)
              .where(incident_assignments: { user_id: current_user.id })
              .distinct
    when "property_manager", "area_manager", "pm_manager"
      Property.joins(:property_assignments)
              .where(property_assignments: { user_id: current_user.id })
    end
  end

  def visible_incidents
    case current_user.user_type
    when "manager", "office_sales"
      Incident.joins(:property)
              .where(properties: { mitigation_org_id: current_user.organization_id })
    when "technician"
      Incident.joins(:incident_assignments)
              .where(incident_assignments: { user_id: current_user.id })
    when "property_manager", "area_manager", "pm_manager"
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

  # --- Role checks ---

  def authorize_mitigation_role!(*allowed_types)
    unless mitigation_admin?(*allowed_types)
      raise ActiveRecord::RecordNotFound
    end
  end

  # True if current user is a mitigation user with one of the given roles.
  # Defaults to manager + office_sales (the admin roles).
  def mitigation_admin?(*roles)
    roles = %w[manager office_sales] if roles.empty?
    current_user.organization.mitigation? &&
      roles.map(&:to_s).include?(current_user.user_type)
  end

  def mitigation_user?
    current_user.organization.mitigation?
  end

  # True if user can create incidents (manager, office_sales, property_manager, area_manager)
  def can_create_incident?
    %w[manager office_sales property_manager area_manager].include?(current_user.user_type)
  end

  # True if user can change incident status (managers only)
  def can_transition_status?
    current_user.user_type == "manager"
  end

  # True if user can edit the given property (mitigation admin OR assigned PM user)
  def can_edit_property?(property)
    return true if mitigation_admin?
    current_user.pm_user? && property.assigned_users.exists?(id: current_user.id)
  end

  # True if user can manage assignments on the given property
  def can_assign_to_property?(property)
    return true if mitigation_admin?
    current_user.pm_user? && property.assigned_users.exists?(id: current_user.id)
  end
end
