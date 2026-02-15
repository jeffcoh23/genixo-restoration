class OperationalNote < ApplicationRecord
  belongs_to :incident
  belongs_to :created_by_user, class_name: "User"

  validates :note_text, presence: true
  validates :log_date, presence: true
end
