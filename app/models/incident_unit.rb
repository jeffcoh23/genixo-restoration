class IncidentUnit < ApplicationRecord
  belongs_to :incident
  belongs_to :created_by_user, class_name: "User"
  has_many :incident_tasks, dependent: :destroy

  validates :unit_number, presence: true

  default_scope { order(:position, :unit_number) }
end
