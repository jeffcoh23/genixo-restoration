class IncidentMailer < ApplicationMailer
  def creation_confirmation(incident)
    @incident = incident
    @user = incident.created_by_user
    @property = incident.property
    mail(to: @user.email_address, subject: "Incident created: #{@property.name}")
  end

  def status_changed(user, incident, old_status, new_status)
    @user = user
    @incident = incident
    @property = incident.property
    @old_label = Incident::STATUS_LABELS[old_status]
    @new_label = Incident::STATUS_LABELS[new_status]
    mail(to: user.email_address, subject: "Status changed to #{@new_label}: #{@property.name}")
  end

  def user_assigned(incident, user)
    @incident = incident
    @user = user
    @property = incident.property
    mail(to: user.email_address, subject: "You've been assigned: #{@property.name}")
  end

  def new_message(user, message)
    @user = user
    @message = message
    @incident = message.incident
    @property = @incident.property
    @sender = message.user
    mail(to: user.email_address, subject: "New message on #{@property.name}")
  end

  def escalation_alert(incident, user)
    @incident = incident
    @user = user
    @property = incident.property
    mail(to: user.email_address, subject: "EMERGENCY: #{@property.name} requires immediate attention")
  end
end
