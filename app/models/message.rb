class Message < ApplicationRecord
  belongs_to :incident
  belongs_to :user

  has_many :attachments, as: :attachable, dependent: :destroy

  validates :body, presence: true
end
