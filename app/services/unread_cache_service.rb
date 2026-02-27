class UnreadCacheService
  # Level 1: nav badge — does this user have ANY unread content?
  def self.has_unread?(user)
    Rails.cache.fetch("has_unread:#{user.id}", expires_in: 5.minutes) do
      compute_has_unread(user)
    end
  end

  # Level 2: per-incident counts — only used on dashboard/incidents list
  def self.unread_counts(user)
    Rails.cache.fetch("unread_counts:#{user.id}", expires_in: 5.minutes) do
      DashboardService.new(user: user).unread_counts
    end
  end

  # Called when content is created (message, activity event)
  def self.expire_for_incident(incident, exclude_user:)
    visible_user_ids = incident_visible_user_ids(incident) - [ exclude_user.id ]
    visible_user_ids.each do |uid|
      Rails.cache.delete("has_unread:#{uid}")
      Rails.cache.delete("unread_counts:#{uid}")
    end
  end

  # Called when user marks an incident as read
  def self.expire_for_user(user)
    Rails.cache.delete("has_unread:#{user.id}")
    Rails.cache.delete("unread_counts:#{user.id}")
  end

  private

  def self.compute_has_unread(user)
    visible_ids = Incident.visible_to(user).select(:id)

    has_unread_messages = Message.where(incident_id: visible_ids)
      .where.not(user_id: user.id)
      .where(
        "NOT EXISTS (SELECT 1 FROM incident_read_states WHERE incident_read_states.incident_id = messages.incident_id AND incident_read_states.user_id = ? AND incident_read_states.last_message_read_at >= messages.created_at)",
        user.id
      ).exists?

    return true if has_unread_messages

    ActivityEvent.where(incident_id: visible_ids)
      .for_daily_log_notifications
      .where.not(performed_by_user_id: user.id)
      .where(
        "NOT EXISTS (SELECT 1 FROM incident_read_states WHERE incident_read_states.incident_id = activity_events.incident_id AND incident_read_states.user_id = ? AND incident_read_states.last_activity_read_at >= activity_events.created_at)",
        user.id
      ).exists?
  end

  def self.incident_visible_user_ids(incident)
    property = incident.property
    mitigation_org_id = property.mitigation_org_id

    # Mitigation org managers/office_sales can see all incidents for their org's properties
    mitigation_user_ids = User.where(organization_id: mitigation_org_id, active: true)
      .where(user_type: [ User::MANAGER, User::OFFICE_SALES ])
      .pluck(:id)

    # Technicians assigned to this incident
    technician_ids = incident.incident_assignments
      .joins(:user).where(users: { user_type: User::TECHNICIAN, active: true })
      .pluck(:user_id)

    # PM users assigned to the property or incident
    pm_property_user_ids = PropertyAssignment.where(property_id: property.id)
      .joins(:user).where(users: { active: true, user_type: User::PM_TYPES })
      .pluck(:user_id)

    pm_incident_user_ids = incident.incident_assignments
      .joins(:user).where(users: { active: true, user_type: User::PM_TYPES })
      .pluck(:user_id)

    (mitigation_user_ids + technician_ids + pm_property_user_ids + pm_incident_user_ids).uniq
  end
end
