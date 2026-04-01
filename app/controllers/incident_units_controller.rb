class IncidentUnitsController < ApplicationController
  before_action :set_incident
  before_action :authorize_timeline!

  def create
    unit = @incident.incident_units.new(unit_params)
    unit.created_by_user = current_user
    unit.position = @incident.incident_units.maximum(:position).to_i + 1
    unit.save!

    ActivityLogger.log(
      incident: @incident,
      event_type: "timeline_unit_created",
      user: current_user,
      metadata: { unit_number: unit.unit_number }
    )

    redirect_to timeline_incident_path(@incident), notice: "Unit added."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to timeline_incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not add unit."
  end

  def update
    unit = @incident.incident_units.find(params[:id])
    unit.update!(unit_params)

    ActivityLogger.log(
      incident: @incident,
      event_type: "timeline_unit_updated",
      user: current_user,
      metadata: { unit_number: unit.unit_number }
    )

    redirect_to timeline_incident_path(@incident), notice: "Unit updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to timeline_incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not update unit."
  end

  def destroy
    unit = @incident.incident_units.find(params[:id])
    unit_number = unit.unit_number
    unit.destroy!

    ActivityLogger.log(
      incident: @incident,
      event_type: "timeline_unit_deleted",
      user: current_user,
      metadata: { unit_number: unit_number }
    )

    redirect_to timeline_incident_path(@incident), notice: "Unit removed."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def authorize_timeline!
    raise ActiveRecord::RecordNotFound unless can_manage_timeline?
  end

  def unit_params
    params.require(:incident_unit).permit(:unit_number, :needs_vacant)
  end
end
