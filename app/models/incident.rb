class Incident < ApplicationRecord
  STATUSES = %w[
    new acknowledged active on_hold completed completed_billed paid closed
    proposal_requested proposal_submitted proposal_signed
  ].freeze
  PROJECT_TYPES = %w[emergency_response mitigation_rfq buildback_rfq capex_rfq other].freeze
  DAMAGE_TYPES = %w[flood fire smoke mold odor other not_applicable].freeze
  QUOTE_PROJECT_TYPES = %w[mitigation_rfq buildback_rfq capex_rfq].freeze

  STATUS_LABELS = {
    "new" => "New", "acknowledged" => "Acknowledged",
    "active" => "Active", "on_hold" => "On Hold", "completed" => "Completed",
    "completed_billed" => "Billed", "paid" => "Paid", "closed" => "Closed",
    "proposal_requested" => "Proposal Requested", "proposal_submitted" => "Proposal Submitted",
    "proposal_signed" => "Proposal Signed"
  }.freeze

  PROJECT_TYPE_LABELS = {
    "emergency_response" => "Emergency Response",
    "mitigation_rfq" => "Mitigation RFQ",
    "buildback_rfq" => "Buildback RFQ",
    "capex_rfq" => "CapEx RFQ",
    "other" => "Other"
  }.freeze

  DAMAGE_LABELS = {
    "flood" => "Flood", "fire" => "Fire", "smoke" => "Smoke",
    "mold" => "Mold", "odor" => "Odor", "other" => "Other",
    "not_applicable" => "Not Applicable"
  }.freeze

  belongs_to :property
  belongs_to :created_by_user, class_name: "User"

  has_many :incident_assignments, dependent: :destroy
  has_many :assigned_users, through: :incident_assignments, source: :user
  has_many :incident_contacts, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :activity_events, dependent: :destroy
  has_many :activity_entries, dependent: :destroy
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

  def quote?
    QUOTE_PROJECT_TYPES.include?(project_type)
  end

  def display_status_label
    if emergency && %w[new acknowledged].include?(status)
      "Emergency"
    else
      STATUS_LABELS[status]
    end
  end
end
