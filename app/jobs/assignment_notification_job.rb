class AssignmentNotificationJob < ApplicationJob
  queue_as :default

  def perform(assignment_id, force: false)
    assignment = IncidentAssignment.find_by(id: assignment_id)
    return unless assignment

    user = assignment.user
    return unless user.active?
    # Auto-assign / on-call users get notified regardless of preference (force: true)
    return unless force || user.notification_preference("incident_user_assignment")

    IncidentMailer.user_assigned(assignment.incident, user).deliver_later
  end
end
