class ActivityEvent < ApplicationRecord
  EVENT_TYPES = %w[
    incident_created status_changed
    user_assigned user_unassigned
    labor_created labor_updated labor_deleted
    activity_logged activity_updated
    equipment_placed equipment_removed equipment_updated
    attachment_uploaded
    operational_note_added
    escalation_attempted escalation_skipped escalation_exhausted
    contact_added contact_removed
  ].freeze
  DAILY_LOG_NOTIFICATION_EVENT_TYPES = %w[activity_logged].freeze

  belongs_to :incident
  belongs_to :performed_by_user, class_name: "User"

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }

  scope :for_daily_log_notifications, -> { where(event_type: DAILY_LOG_NOTIFICATION_EVENT_TYPES) }

  after_create_commit :expire_unread_cache, if: :for_daily_log_notifications?

  private

  def for_daily_log_notifications?
    DAILY_LOG_NOTIFICATION_EVENT_TYPES.include?(event_type)
  end

  def expire_unread_cache
    UnreadCacheService.expire_for_incident(incident, exclude_user: performed_by_user)
  end
end
