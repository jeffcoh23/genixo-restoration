class IncidentContact < ApplicationRecord
  belongs_to :incident
  belongs_to :created_by_user, class_name: "User"

  validates :name, presence: true
end
