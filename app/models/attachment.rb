class Attachment < ApplicationRecord
  CATEGORIES = %w[photo dfr moisture_mapping moisture_readings psychrometric_log signed_document sign_in_sheet general].freeze

  belongs_to :attachable, polymorphic: true
  belongs_to :uploaded_by_user, class_name: "User"

  has_one_attached :file do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 200, 200 ]
  end

  validates :category, presence: true, inclusion: { in: CATEGORIES }
end
