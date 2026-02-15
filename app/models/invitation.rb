class Invitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by_user, class_name: "User"

  validates :email, presence: true
  validates :user_type, presence: true, inclusion: { in: User::ALL_TYPES }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  before_validation :generate_token, on: :create

  def accepted?
    accepted_at.present?
  end

  def expired?
    expires_at < Time.current
  end

  private

  def generate_token
    self.token ||= SecureRandom.urlsafe_base64(32)
  end
end
