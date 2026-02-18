class MessageNotificationJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = Message.find_by(id: message_id)
    return unless message

    incident = message.incident
    sender = message.user

    incident.assigned_users.active.find_each do |user|
      next if user.id == sender.id
      next unless user.notification_preference("new_message")
      IncidentMailer.new_message(user, message).deliver_later
    end
  end
end
