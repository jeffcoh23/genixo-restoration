class IncidentTask < ApplicationRecord
  belongs_to :incident_unit
  belongs_to :created_by_user, class_name: "User"

  validates :activity, presence: true
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_not_before_start_date

  default_scope { order(:position, :start_date) }

  delegate :incident, to: :incident_unit

  # Gantt drag-and-drop sends duration in days; compute end_date server-side.
  def duration_days=(days)
    return unless start_date && days.to_i > 0
    self.end_date = start_date + (days.to_i - 1).days
  end

  private

  def end_date_not_before_start_date
    return unless start_date && end_date
    errors.add(:end_date, "cannot be before start date") if end_date < start_date
  end
end
