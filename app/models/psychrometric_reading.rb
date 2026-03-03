class PsychrometricReading < ApplicationRecord
  belongs_to :psychrometric_point
  belongs_to :recorded_by_user, class_name: "User"

  validates :log_date, presence: true
  validates :psychrometric_point_id, uniqueness: { scope: :log_date }
  validates :temperature, numericality: true, allow_nil: true
  validates :relative_humidity, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true

  before_save :calculate_gpp

  private

  def calculate_gpp
    if temperature.present? && relative_humidity.present?
      t_c = (temperature - 32) * 5.0 / 9.0
      p_sat = 610.94 * Math.exp(17.625 * t_c / (243.04 + t_c))
      sh = 0.622 * (relative_humidity / 100.0 * p_sat) / (101_325.0 - relative_humidity / 100.0 * p_sat)
      self.gpp = (sh * 7000).round(1)
    else
      self.gpp = nil
    end
  end
end
