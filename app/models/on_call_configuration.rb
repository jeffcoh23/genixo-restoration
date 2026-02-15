class OnCallConfiguration < ApplicationRecord
  belongs_to :organization
  belongs_to :primary_user, class_name: "User"

  has_many :escalation_contacts, -> { order(:position) }, dependent: :destroy

  validates :escalation_timeout_minutes, presence: true, numericality: { greater_than: 0 }
  validates :organization_id, uniqueness: true
end
