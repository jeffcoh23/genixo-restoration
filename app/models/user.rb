class User < ApplicationRecord
  # --- User type constants ---
  MANAGER           = "manager"
  TECHNICIAN        = "technician"
  OFFICE_SALES      = "office_sales"
  PROPERTY_MANAGER  = "property_manager"
  AREA_MANAGER      = "area_manager"
  OTHER             = "other"

  GUEST             = "guest"

  MITIGATION_TYPES = [ MANAGER, TECHNICIAN, OFFICE_SALES ].freeze
  PM_TYPES = [ PROPERTY_MANAGER, AREA_MANAGER, OTHER ].freeze
  EXTERNAL_TYPES = [ GUEST ].freeze
  ALL_TYPES = (MITIGATION_TYPES + PM_TYPES + EXTERNAL_TYPES).freeze

  ROLE_LABELS = {
    MANAGER => "Manager",
    TECHNICIAN => "Technician",
    OFFICE_SALES => "Office/Sales",
    PROPERTY_MANAGER => "Property Manager",
    AREA_MANAGER => "Area Manager",
    OTHER => "Other",
    GUEST => "Guest"
  }.freeze

  # Sort order for labor-related dropdowns (technicians first)
  LABOR_SORT_ORDER = [ TECHNICIAN, MANAGER, OFFICE_SALES, PROPERTY_MANAGER, AREA_MANAGER, OTHER ].freeze

  has_secure_password validations: false

  generates_token_for :password_reset, expires_in: 2.hours do
    password_salt&.last(10)
  end

  belongs_to :organization

  has_many :sessions, dependent: :destroy
  has_many :property_assignments, dependent: :destroy
  has_many :assigned_properties, through: :property_assignments, source: :property
  has_many :incident_assignments, dependent: :destroy
  has_many :assigned_incidents, through: :incident_assignments, source: :incident
  has_many :activity_entries, foreign_key: :performed_by_user_id

  validates :email_address, presence: true, uniqueness: { case_sensitive: false }
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :user_type, presence: true, inclusion: { in: ALL_TYPES }
  validates :timezone, presence: true
  validate :user_type_matches_org_type
  validate :auto_assign_only_for_mitigation

  before_validation :set_default_permissions, on: :create

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :phone, with: ->(p) {
    next nil if p.blank?
    digits = p.gsub(/\D/, "")
    digits = digits[1..] if digits.length == 11 && digits[0] == "1"
    digits.presence
  }

  attribute :timezone, default: "Central Time (US & Canada)"

  scope :active, -> { where(active: true) }
  scope :auto_assigned, -> { where(auto_assign: true) }

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name[0]}#{last_name[0]}".upcase
  end

  def manager?
    user_type == MANAGER
  end

  def technician?
    user_type == TECHNICIAN
  end

  def mitigation_user?
    MITIGATION_TYPES.include?(user_type)
  end

  def pm_user?
    PM_TYPES.include?(user_type)
  end

  def guest?
    user_type == GUEST
  end

  def can?(permission)
    permissions.include?(permission.to_s)
  end

  NOTIFICATION_DEFAULTS = {
    "status_change" => false,
    "new_message" => false,
    "incident_user_assignment" => false
  }.freeze

  NOTIFICATION_LABELS = {
    "status_change" => { label: "Status changes", description: "Get notified when an incident status changes" },
    "new_message" => { label: "New messages", description: "Get notified when someone sends a message on your incidents" },
    "incident_user_assignment" => { label: "Assignment alerts", description: "Get notified when you're assigned to or a new incident is created for you" }
  }.freeze

  def notification_preference(key)
    notification_preferences.fetch(key.to_s, NOTIFICATION_DEFAULTS.fetch(key.to_s, true))
  end

  private

  def set_default_permissions
    self.permissions = Permissions.defaults_for(user_type) if permissions.blank? && user_type.present?
  end

  def user_type_matches_org_type
    return unless organization && user_type.present?

    if organization.mitigation? && !MITIGATION_TYPES.include?(user_type)
      errors.add(:user_type, "#{user_type} is not valid for a mitigation organization")
    elsif organization.property_management? && !PM_TYPES.include?(user_type)
      errors.add(:user_type, "#{user_type} is not valid for a property management organization")
    elsif organization.external? && !EXTERNAL_TYPES.include?(user_type)
      errors.add(:user_type, "#{user_type} is not valid for an external organization")
    end
  end

  def auto_assign_only_for_mitigation
    if auto_assign? && !MITIGATION_TYPES.include?(user_type)
      errors.add(:auto_assign, "can only be enabled for mitigation users")
    end
  end
end
