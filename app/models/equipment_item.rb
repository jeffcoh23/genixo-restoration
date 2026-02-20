class EquipmentItem < ApplicationRecord
  belongs_to :equipment_type
  belongs_to :organization

  has_many :equipment_entries

  validates :identifier, presence: true, uniqueness: { scope: :organization_id }
  validates :equipment_type, presence: true

  scope :active, -> { where(active: true) }
end
