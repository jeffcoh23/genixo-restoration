class MoistureMeasurementPoint < ApplicationRecord
  belongs_to :incident
  has_many :moisture_readings, dependent: :destroy

  validates :unit, :room, :item, :material, :goal, :measurement_unit, presence: true
  validates :measurement_unit, inclusion: { in: %w[% Pts] }

  default_scope { order(:position, :id) }
end
