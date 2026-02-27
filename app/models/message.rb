class Message < ApplicationRecord
  belongs_to :incident
  belongs_to :user

  has_many :attachments, as: :attachable, dependent: :destroy

  after_create_commit :expire_unread_cache

  validate :body_or_attachment_present

  private

  def body_or_attachment_present
    return if body.present? || attachments.any?

    errors.add(:body, "can't be blank")
  end

  def expire_unread_cache
    UnreadCacheService.expire_for_incident(incident, exclude_user: user)
  end
end
