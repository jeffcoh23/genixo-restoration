class ActivityEvent < ApplicationRecord
  EVENT_TYPES = %w[
    incident_created status_changed
    user_assigned user_unassigned
    labor_created labor_updated
    equipment_placed equipment_removed equipment_updated
    attachment_uploaded
    operational_note_added
    escalation_attempted
    contact_added contact_removed
  ].freeze

  belongs_to :incident
  belongs_to :performed_by_user, class_name: "User"

  validates :event_type, presence: true, inclusion: { in: EVENT_TYPES }
end
