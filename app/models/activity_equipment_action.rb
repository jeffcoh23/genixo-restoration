class ActivityEquipmentAction < ApplicationRecord
  ACTION_TYPES = %w[add remove move other].freeze

  belongs_to :activity_entry
  belongs_to :equipment_type, optional: true
  belongs_to :equipment_entry, optional: true

  validates :action_type, presence: true, inclusion: { in: ACTION_TYPES }
  validates :quantity, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate :equipment_type_xor
  validate :equipment_entry_belongs_to_incident

  def type_name
    equipment_entry&.type_name || equipment_type&.name || equipment_type_other
  end

  private

  def equipment_type_xor
    return unless equipment_type_id.present? && equipment_type_other.present?

    errors.add(:base, "Choose either equipment type or other equipment type")
  end

  def equipment_entry_belongs_to_incident
    return if equipment_entry.blank? || activity_entry.blank?
    return if equipment_entry.incident_id == activity_entry.incident_id

    errors.add(:equipment_entry_id, "must belong to this incident")
  end
end
