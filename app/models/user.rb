class User < ApplicationRecord
  MITIGATION_TYPES = %w[manager technician office_sales].freeze
  PM_TYPES = %w[property_manager area_manager pm_manager].freeze
  ALL_TYPES = (MITIGATION_TYPES + PM_TYPES).freeze

  has_secure_password validations: false

  belongs_to :organization

  has_many :sessions, dependent: :destroy
  has_many :property_assignments, dependent: :destroy
  has_many :assigned_properties, through: :property_assignments, source: :property
  has_many :incident_assignments, dependent: :destroy
  has_many :assigned_incidents, through: :incident_assignments, source: :incident

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

  def mitigation_user?
    MITIGATION_TYPES.include?(user_type)
  end

  def pm_user?
    PM_TYPES.include?(user_type)
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
