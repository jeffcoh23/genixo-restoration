class MessagesController < ApplicationController
  before_action :set_incident

  def create
    message = @incident.messages.new(
      user: current_user,
      body: params.require(:message).fetch(:body, "").to_s.strip
    )

    message_files = normalized_files(params[:message][:files])
    if message_files.present?
      message_files.each do |file|
        attachment = message.attachments.build(
          uploaded_by_user: current_user,
          category: "general"
        )
        attachment.file.attach(file)
      end
    end

    message.save!
    message.attachments.each { |attachment| attachment.save! unless attachment.persisted? }

    @incident.touch(:last_activity_at)

    MessageNotificationJob.perform_later(message.id)

    redirect_to incident_path(@incident), notice: "Message sent."
  rescue ActionController::ParameterMissing
    redirect_to incident_path(@incident), alert: "Message or attachment required."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to incident_path(@incident), alert: e.record.errors.full_messages.join(", ")
  end

  private

  def set_incident
    @incident = find_visible_incident!(params[:incident_id])
  end

  def normalized_files(raw_files)
    case raw_files
    when nil
      []
    when ActionController::Parameters
      raw_files.values
    when Array
      raw_files
    else
      [ raw_files ]
    end
  end
end
