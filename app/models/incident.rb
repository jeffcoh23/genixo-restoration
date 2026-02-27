class Incident < ApplicationRecord
  STATUSES = %w[
    new acknowledged active job_started on_hold completed completed_billed paid closed
    proposal_requested proposal_submitted proposal_signed
  ].freeze
  PROJECT_TYPES = %w[emergency_response mitigation_rfq buildback_rfq capex_rfq other].freeze
  DAMAGE_TYPES = %w[flood fire smoke mold odor other not_applicable].freeze
  QUOTE_PROJECT_TYPES = %w[mitigation_rfq buildback_rfq capex_rfq].freeze

  STATUS_LABELS = {
    "new" => "New", "acknowledged" => "Acknowledged",
    "active" => "Active", "job_started" => "Job Started", "on_hold" => "On Hold", "completed" => "Completed",
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
  has_many :moisture_measurement_points, dependent: :destroy
  has_many :escalation_events, dependent: :destroy
  has_many :incident_read_states, dependent: :destroy

  scope :visible_to, ->(user) {
    case user.user_type
    when User::MANAGER, User::OFFICE_SALES
      joins(:property).where(properties: { mitigation_org_id: user.organization_id })
    when User::TECHNICIAN
      joins(:incident_assignments).where(incident_assignments: { user_id: user.id })
    when *User::PM_TYPES
      property_ids = PropertyAssignment.where(user_id: user.id).select(:property_id)
      incident_ids = IncidentAssignment.where(user_id: user.id).select(:incident_id)
      where(property_id: property_ids).or(where(id: incident_ids))
    end
  }

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
