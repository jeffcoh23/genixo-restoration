class EquipmentType < ApplicationRecord
  belongs_to :organization

  has_many :equipment_entries, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :organization_id }

  scope :active, -> { where(active: true) }
end
