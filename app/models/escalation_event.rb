class EscalationEvent < ApplicationRecord
  CONTACT_METHODS = %w[voice sms email].freeze
  STATUSES = %w[pending sent delivered failed].freeze

  belongs_to :incident
  belongs_to :user
  belongs_to :resolved_by_user, class_name: "User", optional: true

  validates :contact_method, presence: true, inclusion: { in: CONTACT_METHODS }
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :attempted_at, presence: true
end
