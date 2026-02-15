class DashboardService
  def initialize(user:)
    @user = user
  end

  def grouped_incidents
    scope = base_scope

    {
      emergency: scope.where(emergency: true, status: %w[new acknowledged active]),
      active: scope.where(status: "active", emergency: false),
      needs_attention: scope.where(status: %w[new acknowledged], emergency: false),
      on_hold: scope.where(status: "on_hold"),
      recent_completed: scope.where(status: %w[completed completed_billed paid closed]).limit(20)
    }
  end

  private

  def base_scope
    visible_incidents
      .includes(:property)
      .order(last_activity_at: :desc)
  end

  def visible_incidents
    case @user.user_type
    when "manager", "office_sales"
      Incident.joins(:property)
              .where(properties: { mitigation_org_id: @user.organization_id })
    when "technician"
      Incident.joins(:incident_assignments)
              .where(incident_assignments: { user_id: @user.id })
    when "property_manager", "area_manager", "pm_manager"
      property_ids = PropertyAssignment.where(user_id: @user.id).select(:property_id)
      incident_ids = IncidentAssignment.where(user_id: @user.id).select(:incident_id)
      Incident.where(property_id: property_ids).or(Incident.where(id: incident_ids))
    end
  end
end
