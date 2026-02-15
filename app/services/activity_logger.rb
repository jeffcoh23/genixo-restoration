class ActivityLogger
  def self.log(incident:, event_type:, user:, metadata: {})
    incident.activity_events.create!(
      event_type: event_type,
      performed_by_user: user,
      metadata: metadata
    )
    incident.touch(:last_activity_at)
  end
end
