class DashboardController < ApplicationController
  def show
    groups = DashboardService.new(user: current_user).grouped_incidents

    serialized = serialize_groups(groups)
    total_count = serialized.values.sum(&:length)

    render inertia: "Dashboard", props: {
      groups: serialized,
      total_count: total_count,
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
      organization_name: incident.property.property_management_org.name,
      description: incident.description.truncate(80),
      status: incident.status,
      status_label: incident.display_status_label,
      project_type_label: Incident::PROJECT_TYPE_LABELS[incident.project_type],
      damage_label: Incident::DAMAGE_LABELS[incident.damage_type],
      emergency: incident.emergency,
      last_activity_label: format_relative_time(incident.last_activity_at)
    }
  end
end
