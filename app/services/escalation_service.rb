class EscalationService
  def initialize(incident:, escalation_contact_index: 0)
    @incident = incident
    @index = escalation_contact_index
  end

  def call
    config = @incident.property.mitigation_org.on_call_configuration
    return log_no_config if config.nil?

    user = contact_at_index(config)
    return log_exhausted if user.nil?

    notify_user(user)
    create_escalation_event(user)

    ActivityLogger.log(
      incident: @incident, event_type: "escalation_attempted", user: user,
      metadata: { contact_index: @index, user_name: user.full_name }
    )

    EscalationTimeoutJob.set(wait: config.escalation_timeout_minutes.minutes)
                        .perform_later(@incident.id, @index + 1)
  end

  private

  def contact_at_index(config)
    if @index == 0
      config.primary_user
    else
      config.escalation_contacts.find_by(position: @index)&.user
    end
  end

  def notify_user(user)
    IncidentMailer.escalation_alert(@incident, user).deliver_later
    NotificationService.send_sms(to: user.phone, message: escalation_message) if user.phone.present?
  end

  def create_escalation_event(user)
    @incident.escalation_events.create!(
      user: user,
      contact_method: "email",
      status: "pending",
      attempted_at: Time.current
    )
  end

  def log_no_config
    ActivityLogger.log(
      incident: @incident, event_type: "escalation_skipped",
      user: @incident.created_by_user,
      metadata: { reason: "no_on_call_configuration" }
    )
  end

  def log_exhausted
    ActivityLogger.log(
      incident: @incident, event_type: "escalation_exhausted",
      user: @incident.created_by_user,
      metadata: { contacts_tried: @index }
    )
  end

  def escalation_message
    property = @incident.property
    "EMERGENCY: #{property.name} — #{Incident::DAMAGE_LABELS[@incident.damage_type]} incident requires immediate attention."
  end
end
