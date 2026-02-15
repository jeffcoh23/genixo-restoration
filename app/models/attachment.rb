class Attachment < ApplicationRecord
  CATEGORIES = %w[photo moisture_mapping moisture_readings psychrometric_log signed_document general].freeze

  belongs_to :attachable, polymorphic: true
  belongs_to :uploaded_by_user, class_name: "User"

  has_one_attached :file

  validates :category, presence: true, inclusion: { in: CATEGORIES }
end
