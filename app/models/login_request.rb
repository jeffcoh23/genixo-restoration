class LoginRequest < ApplicationRecord
  STATUSES = %w[pending approved rejected].freeze

  belongs_to :reviewed_by_user, class_name: "User", optional: true

  normalizes :email, with: ->(e) { e.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :first_name, :last_name, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :email, uniqueness: {
    conditions: -> { where(status: "pending") },
    message: "already has a pending request"
  }, if: :pending?

  scope :pending, -> { where(status: "pending") }

  def pending? = status == "pending"
  def approved? = status == "approved"
  def rejected? = status == "rejected"

  def approve!(reviewer)
    raise ArgumentError, "only pending requests can be approved" unless pending?
    update!(status: "approved", reviewed_by_user: reviewer, reviewed_at: Time.current)
  end

  def reject!(reviewer, reason: nil)
    raise ArgumentError, "only pending requests can be rejected" unless pending?
    update!(status: "rejected", reviewed_by_user: reviewer, reviewed_at: Time.current,
      rejection_reason: reason.presence)
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
end
