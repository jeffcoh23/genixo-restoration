class WeatherSnapshot < ApplicationRecord
  belongs_to :incident

  validates :date, presence: true
  validates :fetched_at, presence: true
  validates :incident_id, uniqueness: { scope: :date }

  # One-line summary for the DFR header, e.g.
  # "88°F / 71°F  ·  Partly cloudy  ·  0.12 in precip  ·  wind 9 mph".
  # Returns nil when there's nothing worth printing.
  def summary_line
    parts = []
    if temp_max.present? && temp_min.present?
      parts << "#{temp_max.round}°F / #{temp_min.round}°F"
    elsif temp_avg.present?
      parts << "#{temp_avg.round}°F"
    end
    parts << conditions if conditions.present?
    parts << "#{format('%g', precip.to_f)} in precip" if precip.present? && precip.to_f.positive?
    parts << "wind #{wind_speed.round} mph" if wind_speed.present?
    parts.presence&.join("  ·  ")
  end
end
