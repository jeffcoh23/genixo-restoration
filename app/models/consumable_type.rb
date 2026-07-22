class ConsumableType < ApplicationRecord
  belongs_to :organization

  # Entries keep rendering in historical reports, so a type with entries can
  # be deactivated but never destroyed out from under them.
  has_many :consumable_entries, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :organization_id }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
end
