class IncidentsController < ApplicationController
  before_action :authorize_creation!, only: %i[new create]

  def index
    render inertia: "Incidents/Index"
  end

  def new
    render inertia: "Incidents/New", props: {
      properties: creatable_properties.map { |p| { id: p.id, name: p.name } },
      project_types: Incident::PROJECT_TYPES.map { |t| { value: t, label: Incident::PROJECT_TYPE_LABELS[t] } },
      damage_types: Incident::DAMAGE_TYPES.map { |t| { value: t, label: Incident::DAMAGE_LABELS[t] } }
    }
  end

  def create
    property = creatable_properties.find(params[:incident][:property_id])
    incident = IncidentCreationService.new(
      property: property,
      user: current_user,
      params: incident_params
    ).call

    redirect_to incident_path(incident), notice: "Incident created."
  rescue ActiveRecord::RecordNotFound
    redirect_to new_incident_path, alert: "Property not found."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to new_incident_path,
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not create incident."
  end

  def show
    @incident = find_visible_incident!(params[:id])
    render inertia: "Incidents/Show"
  end

  private

  def authorize_creation!
    allowed = %w[manager office_sales property_manager area_manager]
    raise ActiveRecord::RecordNotFound unless allowed.include?(current_user.user_type)
  end

  def creatable_properties
    visible_properties
  end

  def incident_params
    params.require(:incident).permit(
      :project_type, :damage_type, :description, :cause,
      :requested_next_steps, :units_affected, :affected_room_numbers
    ).to_h.symbolize_keys
  end
end
