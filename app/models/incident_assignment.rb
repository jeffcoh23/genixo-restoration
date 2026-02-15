class IncidentAssignment < ApplicationRecord
  belongs_to :incident
  belongs_to :user
  belongs_to :assigned_by_user, class_name: "User"

  validates :user_id, uniqueness: { scope: :incident_id }
end
