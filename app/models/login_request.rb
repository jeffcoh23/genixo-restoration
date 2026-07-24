class LoginRequest < ApplicationRecord
  STATUSES = %w[pending approved rejected].freeze

  belongs_to :reviewed_by_user, class_name: "User", optional: true

  normalizes :email, with: ->(e) { e.strip.downcase }
  # Public-form scalars get trimmed and stripped of control characters:
  # newlines in e.g. company_name would let a requester inject fake lines into
  # the plain-text reviewer notification email. message may keep its newlines —
  # it renders as its own block, never inline.
  normalizes :first_name, :last_name, :company_name, :phone, :title,
    with: ->(v) { v.gsub(/[[:cntrl:]]/, " ").squeeze(" ").strip }

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
  # holders) AND have opted into login-request emails. The opt-in matters:
  # MANAGE_USERS is held broadly, and emailing every holder both spams the
  # company and can burst past the mail provider's rate limit.
  # Deliberately NOT the on-call escalation chain — that carries
  # emergency semantics; a signup form must never page the on-call contact.
  def self.reviewer_recipients
    User.where(active: true)
        .joins(:organization)
        .where(organizations: { organization_type: "mitigation" })
        .select { |u| u.can?(Permissions::MANAGE_USERS) && u.notification_preference("login_request") }
  end
end
