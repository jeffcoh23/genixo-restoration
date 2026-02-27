class MoistureReading < ApplicationRecord
  belongs_to :moisture_measurement_point
  belongs_to :recorded_by_user, class_name: "User"

  validates :log_date, presence: true
  validates :moisture_measurement_point_id, uniqueness: { scope: :log_date }
  validates :value, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
end
