class StatusChangeNotificationJob < ApplicationJob
  queue_as :default

  def perform(incident_id, old_status, new_status)
    incident = Incident.find_by(id: incident_id)
    return unless incident

    incident.incident_assignments.includes(:user).each do |assignment|
      user = assignment.user
      next unless user.active?
      next unless assignment.effective_notification_preference("status_change")
      IncidentMailer.status_changed(user, incident, old_status, new_status).deliver_later
    end
  end
end
