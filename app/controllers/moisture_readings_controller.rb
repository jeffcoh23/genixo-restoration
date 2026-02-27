class MoistureReadingsController < ApplicationController
  before_action :set_incident
  before_action :authorize_moisture!

  def create_point
    point = @incident.moisture_measurement_points.new(point_params)
    point.position ||= (@incident.moisture_measurement_points.maximum(:position) || 0) + 1
    point.save!

    # Optionally create a first reading if value + date provided
    if params[:reading_value].present? && params[:reading_date].present?
      point.moisture_readings.create!(
        log_date: params[:reading_date],
        value: params[:reading_value],
        recorded_by_user: current_user
      )
    end

    ActivityLogger.log(
      incident: @incident,
      event_type: "moisture_point_created",
      user: current_user,
      metadata: { unit: point.unit, room: point.room, item: point.item }
    )

    redirect_to incident_path(@incident), notice: "Measurement point added."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not create measurement point."
  end

  def destroy_point
    point = @incident.moisture_measurement_points.find(params[:id])
    point.destroy!

    ActivityLogger.log(
      incident: @incident,
      event_type: "moisture_point_deleted",
      user: current_user,
      metadata: { unit: point.unit, room: point.room, item: point.item }
    )

    redirect_to incident_path(@incident), notice: "Measurement point removed."
  end

  def batch_save
    date = Date.parse(params[:log_date])
    readings_params = params[:readings] || []

    readings_params.each do |reading_data|
      point = @incident.moisture_measurement_points.find(reading_data[:point_id])
      reading = point.moisture_readings.find_or_initialize_by(log_date: date)
      reading.value = reading_data[:value]
      reading.recorded_by_user = current_user
      reading.save!
    end

    ActivityLogger.log(
      incident: @incident,
      event_type: "moisture_readings_recorded",
      user: current_user,
      metadata: { date: date.iso8601, count: readings_params.size }
    )

    redirect_to incident_path(@incident), notice: "Readings saved."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not save readings."
  end

  def update
    reading = find_reading!
    reading.update!(value: params[:value])

    ActivityLogger.log(
      incident: @incident,
      event_type: "moisture_reading_updated",
      user: current_user,
      metadata: { date: reading.log_date.iso8601, value: reading.value&.to_f }
    )

    redirect_to incident_path(@incident), notice: "Reading updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not update reading."
  end

  def destroy
    reading = find_reading!
    reading.destroy!

    ActivityLogger.log(
      incident: @incident,
      event_type: "moisture_reading_deleted",
      user: current_user,
      metadata: { date: reading.log_date.iso8601 }
    )

    redirect_to incident_path(@incident), notice: "Reading deleted."
  end

  def update_supervisor
    @incident.update!(moisture_supervisor_pm: params[:moisture_supervisor_pm])

    ActivityLogger.log(
      incident: @incident,
      event_type: "moisture_supervisor_updated",
      user: current_user,
      metadata: { supervisor_pm: @incident.moisture_supervisor_pm }
    )

    redirect_to incident_path(@incident), notice: "Supervisor/PM updated."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def authorize_moisture!
    raise ActiveRecord::RecordNotFound unless can_manage_moisture_readings?
  end

  def find_reading!
    point_ids = @incident.moisture_measurement_points.select(:id)
    MoistureReading.where(moisture_measurement_point_id: point_ids).find(params[:id])
  end

  def point_params
    params.require(:point).permit(:unit, :room, :item, :material, :goal, :measurement_unit, :position)
  end
end
