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

  private

  def end_after_start
    return unless started_at && ended_at
    errors.add(:ended_at, "must be after start time") if ended_at <= started_at
  end
end
