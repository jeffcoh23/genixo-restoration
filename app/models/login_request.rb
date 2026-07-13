class LoginRequest < ApplicationRecord
  STATUSES = %w[pending approved rejected].freeze

  belongs_to :reviewed_by_user, class_name: "User", optional: true

  normalizes :email, with: ->(e) { e.strip.downcase }

  # Length caps: this is a public unauthenticated form. Unbounded input would
  # bloat storage, the notification email, and the Users-page JSON payload.
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true },
    length: { maximum: 255 }
  validates :first_name, :last_name, presence: true, length: { maximum: 100 }
  # Free-text company name. A public unauthenticated form must NOT expose a
  # dropdown of client orgs (that leaks the customer list), so the requester
  # types their company and the admin links it to an org when approving.
  validates :company_name, presence: true, on: :create
  validates :company_name, length: { maximum: 200 }
  validates :phone, length: { maximum: 50 }
  validates :phone, presence: true, on: :create
  validates :title, length: { maximum: 100 }
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
end
