class EquipmentEntry < ApplicationRecord
  belongs_to :incident
  belongs_to :equipment_type, optional: true
  belongs_to :logged_by_user, class_name: "User"

  before_validation :normalize_equipment_type

  validates :placed_at, presence: true
  validate :equipment_type_xor

  def type_name
    equipment_type&.name || equipment_type_other
  end

  private

  def normalize_equipment_type
    self.equipment_type_other = nil if equipment_type_other.blank?
  end

  def equipment_type_xor
    if equipment_type_id.present? && equipment_type_other.present?
      errors.add(:base, "Cannot specify both equipment type and other")
    elsif equipment_type_id.blank? && equipment_type_other.blank?
      errors.add(:base, "Must specify either equipment type or other")
    end
  end
end
