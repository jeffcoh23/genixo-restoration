class ConsumableType < ApplicationRecord
  # The standard sheet, in sheet order. Referenced by db/seeds.rb; the
  # CreateConsumables migration keeps its own frozen copy on purpose
  # (migrations must not depend on evolving model constants).
  DEFAULT_NAMES = [
    "HEPA Filter Air Scrubber Small",
    "HEPA Filter Air Scrubber Large",
    "HEPA Vacuum Small",
    "HEPA Vacuum Large",
    "Hydroxyl Unit",
    "Portable Water Extractor",
    "Truck Mount Unit",
    "Truck/Van Vehicle",
    "Decontamination of Equipment",
    "Filter Replacement",
    "Disposal"
  ].freeze

  belongs_to :organization

  # Entries keep rendering in historical reports, so a type with entries can
  # be deactivated but never destroyed out from under them.
  has_many :consumable_entries, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :organization_id }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }
end
