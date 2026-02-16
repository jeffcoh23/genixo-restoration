class ActivityEntry < ApplicationRecord
  STATUSES = %w[active completed].freeze

  belongs_to :incident
  belongs_to :performed_by_user, class_name: "User"
  has_many :equipment_actions,
    -> { order(:position, :created_at) },
    class_name: "ActivityEquipmentAction",
    dependent: :destroy,
    inverse_of: :activity_entry

  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :occurred_at, presence: true
  validates :units_affected, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
end
