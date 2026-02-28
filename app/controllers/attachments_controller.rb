class AttachmentsController < ApplicationController
  before_action :set_incident
  before_action :authorize_attachment_upload!, only: %i[create upload_photo]
  before_action :authorize_attachment_management!, only: %i[update destroy]

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

  def update
    attachment = @incident.attachments.find(params[:id])
    attachment.update!(params.require(:attachment).permit(:log_date, :description))
    redirect_to incident_path(@incident), notice: "Attachment updated."
  end

  def destroy
    attachment = @incident.attachments.find(params[:id])
    ActivityLogger.log(
      incident: @incident,
      event_type: "attachment_deleted",
      user: current_user,
      metadata: { filename: attachment.file.filename.to_s }
    )
    attachment.file.purge
    attachment.destroy!
    redirect_to incident_path(@incident), notice: "Attachment deleted."
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def authorize_attachment_upload!
    raise ActiveRecord::RecordNotFound unless can_manage_attachments?
  end

  def authorize_attachment_management!
    raise ActiveRecord::RecordNotFound unless can_manage_attachments?
  end

  def attachment_params
    params.require(:attachment).permit(:file, :category, :description, :log_date)
  end
end
