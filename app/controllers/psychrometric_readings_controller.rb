class PsychrometricReadingsController < ApplicationController
  before_action :set_incident
  before_action :authorize_psychrometric!

  def create_point
    point = @incident.psychrometric_points.new(point_params)
    point.position ||= (@incident.psychrometric_points.maximum(:position) || 0) + 1
    point.save!

    if params[:reading_temperature].present? && params[:reading_relative_humidity].present? && params[:reading_date].present?
      point.psychrometric_readings.create!(
        log_date: params[:reading_date],
        temperature: params[:reading_temperature],
        relative_humidity: params[:reading_relative_humidity],
        recorded_by_user: current_user
      )
    end

    ActivityLogger.log(
      incident: @incident,
      event_type: "psychrometric_point_created",
      user: current_user,
      metadata: { unit: point.unit, room: point.room }
    )

    respond_to do |format|
      format.json do
        render json: {
          id: point.id, unit: point.unit, room: point.room,
          dehumidifier_label: point.dehumidifier_label, position: point.position,
          readings: {},
          destroy_path: incident_psychrometric_point_path(@incident, point)
        }
      end
      format.any { redirect_to incident_path(@incident), notice: "Psychrometric point added." }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.json { render json: { errors: e.record.errors.to_hash }, status: :unprocessable_entity }
      format.any do
        redirect_to incident_path(@incident),
          inertia: { errors: e.record.errors.to_hash },
          alert: "Could not create psychrometric point."
      end
    end
  end

  def destroy_point
    point = @incident.psychrometric_points.find(params[:id])
    point.destroy!

    ActivityLogger.log(
      incident: @incident,
      event_type: "psychrometric_point_deleted",
      user: current_user,
      metadata: { unit: point.unit, room: point.room }
    )

    redirect_to incident_path(@incident), notice: "Psychrometric point removed."
  end

  def batch_save
    date = Date.parse(params[:log_date])
    readings_params = params[:readings] || []

    readings_params.each do |reading_data|
      point = @incident.psychrometric_points.find(reading_data[:point_id])
      reading = point.psychrometric_readings.find_or_initialize_by(log_date: date)
      reading.temperature = reading_data[:temperature]
      reading.relative_humidity = reading_data[:relative_humidity]
      reading.recorded_by_user = current_user
      reading.save!
    end

    ActivityLogger.log(
      incident: @incident,
      event_type: "psychrometric_readings_recorded",
      user: current_user,
      metadata: { date: date.iso8601, count: readings_params.size }
    )

    redirect_to incident_path(@incident), notice: "Psychrometric readings saved."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not save psychrometric readings."
  end

  def update
    reading = find_reading!
    reading.update!(reading_update_params)

    ActivityLogger.log(
      incident: @incident,
      event_type: "psychrometric_reading_updated",
      user: current_user,
      metadata: { date: reading.log_date.iso8601, temperature: reading.temperature&.to_f, relative_humidity: reading.relative_humidity&.to_f, gpp: reading.gpp&.to_f }
    )

    redirect_to incident_path(@incident), notice: "Psychrometric reading updated."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not update psychrometric reading."
  end

  def destroy
    reading = find_reading!
    reading.destroy!

    ActivityLogger.log(
      incident: @incident,
      event_type: "psychrometric_reading_deleted",
      user: current_user,
      metadata: { date: reading.log_date.iso8601 }
    )

    redirect_to incident_path(@incident), notice: "Psychrometric reading deleted."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def authorize_psychrometric!
    raise ActiveRecord::RecordNotFound unless can_manage_psychrometric_readings?
  end

  def find_reading!
    point_ids = @incident.psychrometric_points.select(:id)
    PsychrometricReading.where(psychrometric_point_id: point_ids).find(params[:id])
  end

  def point_params
    params.require(:point).permit(:unit, :room, :dehumidifier_label, :position)
  end

  def reading_update_params
    params.permit(:temperature, :relative_humidity)
  end
end
