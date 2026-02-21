class Message < ApplicationRecord
  belongs_to :incident
  belongs_to :user

  has_many :attachments, as: :attachable, dependent: :destroy

  validate :body_or_attachment_present

  private

  def body_or_attachment_present
    return if body.present? || attachments.any?

    errors.add(:body, "can't be blank")
  end
end
