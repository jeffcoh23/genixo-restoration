class IncidentReadState < ApplicationRecord
  belongs_to :incident
  belongs_to :user

  validates :incident_id, uniqueness: { scope: :user_id }

  after_save_commit :expire_unread_cache

  private

  def expire_unread_cache
    UnreadCacheService.expire_for_user(user)
  end
end
