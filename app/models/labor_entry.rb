class LaborEntry < ApplicationRecord
  belongs_to :incident
  belongs_to :user, optional: true
  belongs_to :created_by_user, class_name: "User"

  validates :role_label, presence: true
  validates :log_date, presence: true
  validates :started_at, presence: true
  validates :ended_at, presence: true
  validates :hours, presence: true, numericality: { greater_than: 0 }
end
