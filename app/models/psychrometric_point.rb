class PsychrometricPoint < ApplicationRecord
  belongs_to :incident
  has_many :psychrometric_readings, dependent: :destroy

  validates :unit, :room, presence: true

  default_scope { order(:position, :id) }
end
