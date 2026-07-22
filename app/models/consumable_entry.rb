class ConsumableEntry < ApplicationRecord
  belongs_to :incident
  belongs_to :consumable_type, optional: true
  belongs_to :logged_by_user, class_name: "User"

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :log_date, presence: true
  validate :type_xor_custom

  scope :for_date, ->(date) { where(log_date: date) }

  def display_name
    consumable_type&.name || custom_name
  end

  private

  # Mirrors the DB check constraint: an entry is either a standard type or a
  # free-text write-in, never both, never neither.
  def type_xor_custom
    if consumable_type_id.present? && custom_name.present?
      errors.add(:base, "Cannot specify both a consumable type and a custom name")
    elsif consumable_type_id.blank? && custom_name.blank?
      errors.add(:base, "Must specify either a consumable type or a custom name")
    end
  end
end
