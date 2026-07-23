class LaborEntry < ApplicationRecord
  belongs_to :incident
  belongs_to :user, optional: true
  belongs_to :created_by_user, class_name: "User"

  validates :role_label, presence: true
  validates :log_date, presence: true
  validates :started_at, presence: true
  validates :ended_at, presence: true
  validates :hours, presence: true, numericality: { greater_than: 0 }
  validate :end_after_start
  validate :user_must_be_eligible_for_incident

  private

  def end_after_start
    return unless started_at && ended_at
    errors.add(:ended_at, "must be after start time") if ended_at <= started_at
  end

  def user_must_be_eligible_for_incident
    return unless user && incident

    eligible = user.organization_id == incident.property.mitigation_org_id &&
      [ User::MANAGER, User::TECHNICIAN ].include?(user.user_type)
    errors.add(:user, "must be an eligible mitigation worker") unless eligible
  end
end
