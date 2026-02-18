class User < ApplicationRecord
  # --- User type constants ---
  MANAGER           = "manager"
  TECHNICIAN        = "technician"
  OFFICE_SALES      = "office_sales"
  PROPERTY_MANAGER  = "property_manager"
  AREA_MANAGER      = "area_manager"
  PM_MANAGER        = "pm_manager"

  MITIGATION_TYPES = [ MANAGER, TECHNICIAN, OFFICE_SALES ].freeze
  PM_TYPES = [ PROPERTY_MANAGER, AREA_MANAGER, PM_MANAGER ].freeze
  ALL_TYPES = (MITIGATION_TYPES + PM_TYPES).freeze

  ROLE_LABELS = {
    MANAGER => "Manager",
    TECHNICIAN => "Technician",
    OFFICE_SALES => "Office/Sales",
    PROPERTY_MANAGER => "Property Manager",
    AREA_MANAGER => "Area Manager",
    PM_MANAGER => "PM Manager"
  }.freeze

  # Sort order for labor-related dropdowns (technicians first)
  LABOR_SORT_ORDER = [ TECHNICIAN, MANAGER, OFFICE_SALES, PROPERTY_MANAGER, AREA_MANAGER, PM_MANAGER ].freeze

  has_secure_password validations: false

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

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  scope :active, -> { where(active: true) }

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

  def can?(permission)
    Permissions.has?(user_type, permission)
  end

  def notification_preference(key)
    notification_preferences.fetch(key.to_s, true)
  end

  private

  def user_type_matches_org_type
    return unless organization && user_type.present?

    if organization.mitigation? && !MITIGATION_TYPES.include?(user_type)
      errors.add(:user_type, "#{user_type} is not valid for a mitigation organization")
    elsif organization.property_management? && !PM_TYPES.include?(user_type)
      errors.add(:user_type, "#{user_type} is not valid for a property management organization")
    end
  end
end
