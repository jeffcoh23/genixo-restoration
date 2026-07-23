class LaborEntriesController < ApplicationController
  before_action :set_incident
  before_action :authorize_labor!

  def create
    entry = @incident.labor_entries.new(labor_entry_params)
    entry.created_by_user = current_user
    calculate_hours!(entry)

    entry.save!

    ActivityLogger.log(
      incident: @incident,
      event_type: "labor_created",
      user: current_user,
      metadata: {
        role_label: entry.role_label,
        hours: entry.hours.to_f,
        user_name: entry.user&.full_name
      }
    )

    redirect_to incident_path(@incident), notice: "Labor entry created."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not create labor entry."
  end

  def update
    entry = find_editable_entry!

    entry.assign_attributes(labor_entry_params)
    calculate_hours!(entry)

    entry.save!

    ActivityLogger.log(
      incident: @incident,
      event_type: "labor_updated",
      user: current_user,
      metadata: {
        role_label: entry.role_label,
        hours: entry.hours.to_f,
        user_name: entry.user&.full_name
      }
    )

    redirect_to incident_path(@incident), notice: "Labor entry updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not update labor entry."
  end

  def destroy
    entry = find_editable_entry!
    entry.destroy!

    ActivityLogger.log(
      incident: @incident,
      event_type: "labor_deleted",
      user: current_user,
      metadata: {
        role_label: entry.role_label,
        hours: entry.hours.to_f,
        user_name: entry.user&.full_name
      }
    )

    redirect_to incident_path(@incident), notice: "Labor entry deleted."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def authorize_labor!
    raise ActiveRecord::RecordNotFound unless can_create_labor?
  end

  def find_editable_entry!
    @incident.labor_entries.find(params[:id])
  end

  def labor_entry_params
    params.require(:labor_entry).permit(
      :role_label, :log_date, :started_at, :ended_at, :notes, :user_id
    )
  end

  def calculate_hours!(entry)
    if entry.started_at.present? && entry.ended_at.present?
      entry.hours = ((entry.ended_at - entry.started_at) / 1.hour).round(2)
    end
  end
end
