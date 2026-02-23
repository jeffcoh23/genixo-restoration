class AssignmentNotificationJob < ApplicationJob
  queue_as :default

  def perform(assignment_id)
    assignment = IncidentAssignment.find_by(id: assignment_id)
    return unless assignment

    user = assignment.user
    return unless user.active?
    return unless user.notification_preference("user_assignment")

    IncidentMailer.user_assigned(assignment.incident, user).deliver_later
  end
end
