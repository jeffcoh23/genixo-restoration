class LoginRequest < ApplicationRecord
  STATUSES = %w[pending approved rejected].freeze

  belongs_to :reviewed_by_user, class_name: "User", optional: true
  # optional: true keeps legacy free-text requests (no org) approvable; new
  # requests are forced to pick a real client via the on: :create validations.
  belongs_to :organization, optional: true

  normalizes :email, with: ->(e) { e.strip.downcase }

  # The requester picks their company from a dropdown of PM (client) orgs, so we
  # store the real org and snapshot its name into company_name for display/email
  # and as a historical record if the org is later renamed.
  before_validation :snapshot_company_name, on: :create

  # Length caps: this is a public unauthenticated form. Unbounded input would
  # bloat storage, the notification email, and the Users-page JSON payload.
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true },
    length: { maximum: 255 }
  validates :first_name, :last_name, presence: true, length: { maximum: 100 }
  validates :company_name, length: { maximum: 200 }
  # Errors attach to :organization_id so they surface on the form's dropdown.
  validates :organization_id, presence: true, on: :create
  validate :organization_is_a_client, on: :create
  validates :phone, length: { maximum: 50 }
  validates :message, length: { maximum: 2000 }
  validates :status, inclusion: { in: STATUSES }
  validates :email, uniqueness: {
    conditions: -> { where(status: "pending") },
    message: "already has a pending request"
  }, if: :pending?

  scope :pending, -> { where(status: "pending") }

  def pending? = status == "pending"
  def approved? = status == "approved"
  def rejected? = status == "rejected"

  # with_lock (SELECT ... FOR UPDATE) closes the check-then-update race: two
  # admins acting on the same request can't both pass the pending? gate.
  def approve!(reviewer)
    with_lock do
      raise ArgumentError, "only pending requests can be approved" unless pending?
      update!(status: "approved", reviewed_by_user: reviewer, reviewed_at: Time.current)
    end
  end

  def reject!(reviewer, reason: nil)
    with_lock do
      raise ArgumentError, "only pending requests can be rejected" unless pending?
      update!(status: "rejected", reviewed_by_user: reviewer, reviewed_at: Time.current,
        rejection_reason: reason.presence)
    end
  end

  def full_name
    "#{first_name} #{last_name}"
  end

  # Active mitigation-org users who can act on a request (MANAGE_USERS
  # holders). Deliberately NOT the on-call escalation chain — that carries
  # emergency semantics; a signup form must never page the on-call contact.
  def self.reviewer_recipients
    User.where(active: true)
        .joins(:organization)
        .where(organizations: { organization_type: "mitigation" })
        .select { |u| u.can?(Permissions::MANAGE_USERS) }
  end

  private

  def snapshot_company_name
    self.company_name = organization&.name
  end

  def organization_is_a_client
    return if organization_id.blank? # presence validation handles the blank case
    errors.add(:organization_id, "is not a valid company") unless organization&.property_management?
  end
end
