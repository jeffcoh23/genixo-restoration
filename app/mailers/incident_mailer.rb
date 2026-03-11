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

  def public_report_received(user, report, is_emergency)
    @user = user
    @report = report
    @is_emergency = is_emergency
    @project_label = Incident::PROJECT_TYPE_LABELS[report[:project_type]] || report[:project_type]
    @damage_label = Incident::DAMAGE_LABELS[report[:damage_type]] || report[:damage_type]
    subject = is_emergency ? "EMERGENCY: Public Incident Report — Immediate Review Needed" : "New Public Incident Report Submitted"
    mail(to: user.email_address, subject: subject)
  end

  def escalation_alert(incident, user)
    @incident = incident
    @user = user
    @property = incident.property
    mail(to: user.email_address, subject: "EMERGENCY: #{@property.name} requires immediate attention")
  end
end
