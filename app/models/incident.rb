class Incident < ApplicationRecord
  STATUSES = %w[new acknowledged quote_requested active on_hold completed completed_billed paid closed].freeze
  PROJECT_TYPES = %w[emergency_response mitigation_rfq buildback_rfq other].freeze
  DAMAGE_TYPES = %w[flood fire smoke mold odor other].freeze

  STATUS_LABELS = {
    "new" => "New", "acknowledged" => "Acknowledged", "quote_requested" => "Quote Requested",
    "active" => "Active", "on_hold" => "On Hold", "completed" => "Completed",
    "completed_billed" => "Billed", "paid" => "Paid", "closed" => "Closed"
  }.freeze

  DAMAGE_LABELS = {
    "flood" => "Flood", "fire" => "Fire", "smoke" => "Smoke",
    "mold" => "Mold", "odor" => "Odor", "other" => "Other"
  }.freeze

  belongs_to :property
  belongs_to :created_by_user, class_name: "User"

  has_many :incident_assignments, dependent: :destroy
  has_many :assigned_users, through: :incident_assignments, source: :user
  has_many :incident_contacts, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :activity_events, dependent: :destroy
  has_many :labor_entries, dependent: :destroy
  has_many :equipment_entries, dependent: :destroy
  has_many :operational_notes, dependent: :destroy
  has_many :attachments, as: :attachable, dependent: :destroy
  has_many :escalation_events, dependent: :destroy
  has_many :incident_read_states, dependent: :destroy

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :project_type, presence: true, inclusion: { in: PROJECT_TYPES }
  validates :damage_type, presence: true, inclusion: { in: DAMAGE_TYPES }
  validates :description, presence: true
end
