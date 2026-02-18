class MessagesController < ApplicationController
  before_action :set_incident

  def create
    message = @incident.messages.create!(
      user: current_user,
      body: params.require(:message).require(:body)
    )

    if params[:message][:files].present?
      Array(params[:message][:files]).each do |file|
        attachment = message.attachments.new(
          uploaded_by_user: current_user,
          category: "general"
        )
        attachment.file.attach(file)
        attachment.save!
      end
    end

    @incident.touch(:last_activity_at)

    MessageNotificationJob.perform_later(message.id)

    redirect_to incident_path(@incident), notice: "Message sent."
  rescue ActionController::ParameterMissing
    redirect_to incident_path(@incident), alert: "Message body can't be blank."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident), alert: e.record.errors.full_messages.join(", ")
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end
end
