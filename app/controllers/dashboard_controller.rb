class DashboardController < ApplicationController
  def show
    groups = DashboardService.new(user: current_user).grouped_incidents

    render inertia: "Dashboard", props: {
      groups: serialize_groups(groups),
      can_create_incident: can_create_incident?
    }
  end

  private

  def serialize_groups(groups)
    groups.transform_values { |scope| scope.map { |i| serialize_incident(i) } }
  end

  def serialize_incident(incident)
    {
      id: incident.id,
      path: incident_path(incident),
      property_name: incident.property.name,
      description: incident.description.truncate(80),
      status: incident.status,
      status_label: Incident::STATUS_LABELS[incident.status],
      project_type_label: Incident::PROJECT_TYPE_LABELS[incident.project_type],
      damage_label: Incident::DAMAGE_LABELS[incident.damage_type],
      emergency: incident.emergency,
      last_activity_at: incident.last_activity_at&.iso8601
    }
  end
end
