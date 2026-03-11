class StatusChangeNotificationJob < ApplicationJob
  queue_as :default

  # Only notify for meaningful status changes — skip early internal workflow steps
  NOTIFIABLE_STATUSES = %w[
    active job_started on_hold completed completed_billed paid closed
    proposal_requested proposal_submitted proposal_signed
  ].freeze

  def perform(incident_id, old_status, new_status)
    incident = Incident.find_by(id: incident_id)
    return unless incident
    return unless NOTIFIABLE_STATUSES.include?(new_status)

    incident.incident_assignments.includes(:user).each do |assignment|
      user = assignment.user
      next unless user.active?
      next unless assignment.effective_notification_preference("status_change")
      IncidentMailer.status_changed(user, incident, old_status, new_status).deliver_later
    end
  end
end
