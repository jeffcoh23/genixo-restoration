class MessagesController < ApplicationController
  before_action :set_incident

  def create
    @incident.messages.create!(
      user: current_user,
      body: params.require(:message).require(:body)
    )
    @incident.touch(:last_activity_at)

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
