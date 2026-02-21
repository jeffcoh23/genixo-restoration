class AttachmentsController < ApplicationController
  before_action :set_incident

  def upload_photo
    unless params[:file].present?
      render json: { errors: [ "File is required" ] }, status: :unprocessable_entity
      return
    end

    attachment = @incident.attachments.new(
      file: params[:file],
      category: "photo",
      description: params[:description].presence,
      log_date: params[:log_date],
      uploaded_by_user: current_user
    )

    if attachment.save
      ActivityLogger.log(
        incident: @incident,
        event_type: "attachment_uploaded",
        user: current_user,
        metadata: { filename: attachment.file.filename.to_s, category: "photo" }
      )
      render json: { id: attachment.id, filename: attachment.file.filename.to_s }, status: :created
    else
      render json: { errors: attachment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def create
    attachment = @incident.attachments.new(attachment_params)
    attachment.uploaded_by_user = current_user

    attachment.save!

    ActivityLogger.log(
      incident: @incident,
      event_type: "attachment_uploaded",
      user: current_user,
      metadata: {
        filename: attachment.file.filename.to_s,
        category: attachment.category,
        description: attachment.description
      }
    )

    redirect_to incident_path(@incident), notice: "File uploaded."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident),
      inertia: { errors: e.record.errors.to_hash },
      alert: "Could not upload file."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def attachment_params
    params.require(:attachment).permit(:file, :category, :description, :log_date)
  end
end
