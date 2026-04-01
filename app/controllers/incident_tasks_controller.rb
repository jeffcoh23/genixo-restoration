class IncidentTasksController < ApplicationController
  before_action :set_incident_and_unit
  before_action :authorize_timeline!

  def create
    task = @unit.incident_tasks.new(task_params)
    task.created_by_user = current_user
    task.position = @unit.incident_tasks.maximum(:position).to_i + 1
    task.save!

    ActivityLogger.log(
      incident: @unit.incident,
      event_type: "timeline_task_created",
      user: current_user,
      metadata: { unit_number: @unit.unit_number, activity: task.activity }
    )

    redirect_to timeline_incident_path(@unit.incident), notice: "Task added."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to timeline_incident_path(@unit.incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not add task."
  end

  def update
    task = @unit.incident_tasks.find(params[:id])
    task.update!(task_params)

    ActivityLogger.log(
      incident: @unit.incident,
      event_type: "timeline_task_updated",
      user: current_user,
      metadata: { unit_number: @unit.unit_number, activity: task.activity }
    )

    redirect_to timeline_incident_path(@unit.incident), notice: "Task updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to timeline_incident_path(@unit.incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not update task."
  end

  def destroy
    task = @unit.incident_tasks.find(params[:id])
    activity = task.activity
    task.destroy!

    ActivityLogger.log(
      incident: @unit.incident,
      event_type: "timeline_task_deleted",
      user: current_user,
      metadata: { unit_number: @unit.unit_number, activity: activity }
    )

    redirect_to timeline_incident_path(@unit.incident), notice: "Task removed."
  end

  private

  def set_incident_and_unit
    incident = find_visible_incident!(params[:incident_id])
    @unit = incident.incident_units.find(params[:incident_unit_id])
  end

  def authorize_timeline!
    raise ActiveRecord::RecordNotFound unless can_manage_timeline?
  end

  def task_params
    params.require(:incident_task).permit(:activity, :start_date, :end_date, :duration_days)
  end
end
