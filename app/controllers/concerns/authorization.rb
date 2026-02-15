module Authorization
  extend ActiveSupport::Concern

  private

  # Returns properties visible to the current user
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

  # Returns incidents visible to the current user
  def visible_incidents
    case current_user.user_type
    when "manager", "office_sales"
      Incident.joins(:property)
              .where(properties: { mitigation_org_id: current_user.organization_id })
    when "technician"
      Incident.joins(:incident_assignments)
              .where(incident_assignments: { user_id: current_user.id })
    when "property_manager", "area_manager", "pm_manager"
      # Use subqueries so both sides of .or are structurally compatible
      property_ids = PropertyAssignment.where(user_id: current_user.id).select(:property_id)
      incident_ids = IncidentAssignment.where(user_id: current_user.id).select(:incident_id)
      Incident.where(property_id: property_ids).or(Incident.where(id: incident_ids))
    end
  end

  # For finding a specific record — raises RecordNotFound (404) if not in scope
  def find_visible_incident!(id)
    visible_incidents.find(id)
  end

  def find_visible_property!(id)
    visible_properties.find(id)
  end

  # Guard for mitigation-only actions
  def authorize_mitigation_role!(*allowed_types)
    unless current_user.organization.mitigation? &&
           allowed_types.map(&:to_s).include?(current_user.user_type)
      raise ActiveRecord::RecordNotFound
    end
  end
end
