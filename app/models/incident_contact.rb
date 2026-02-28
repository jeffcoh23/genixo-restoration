class IncidentContact < ApplicationRecord
  belongs_to :incident
  belongs_to :created_by_user, class_name: "User"

  validates :name, presence: true

  normalizes :phone, with: ->(p) {
    next nil if p.blank?
    digits = p.gsub(/\D/, "")
    digits = digits[1..] if digits.length == 11 && digits[0] == "1"
    digits.presence
  }
end
