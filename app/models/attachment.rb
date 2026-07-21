class Attachment < ApplicationRecord
  CATEGORIES = %w[photo dfr weekly_report moisture_mapping moisture_readings psychrometric_log signed_document sign_in_sheet proposal general].freeze

  # Reports the app generates itself (as opposed to files users upload). These
  # are excluded from the DFR/weekly photo-and-document pickers — appending a
  # generated report into another generated report recursively bloats PDFs.
  GENERATED_REPORT_CATEGORIES = %w[dfr weekly_report].freeze

  belongs_to :attachable, polymorphic: true
  belongs_to :uploaded_by_user, class_name: "User"

  has_one_attached :file do |attachable|
    attachable.variant :thumbnail, resize_to_fill: [ 200, 200 ]
  end

  validates :category, presence: true, inclusion: { in: CATEGORIES }
end
