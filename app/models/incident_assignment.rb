class IncidentAssignment < ApplicationRecord
  belongs_to :incident
  belongs_to :user
  belongs_to :assigned_by_user, class_name: "User"

  validates :user_id, uniqueness: { scope: :incident_id }

  OVERRIDABLE_NOTIFICATION_KEYS = %w[status_change new_message].freeze

  def effective_notification_preference(key)
    key = key.to_s
    if notification_overrides.key?(key)
      notification_overrides[key]
    else
      user.notification_preference(key)
    end
  end
end
