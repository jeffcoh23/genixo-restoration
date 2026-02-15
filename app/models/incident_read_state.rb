class IncidentReadState < ApplicationRecord
  belongs_to :incident
  belongs_to :user

  validates :incident_id, uniqueness: { scope: :user_id }
end
