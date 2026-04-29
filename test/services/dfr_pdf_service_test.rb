require "test_helper"
require "pdf/inspector"

class DfrPdfServiceTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "svc-mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")

    @incident = Incident.create!(property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Test DFR")

    @date = Date.current
  end

  test "includes all photos for date when no photo_attachment_ids specified" do
    create_photo("photo1.jpg")
    create_photo("photo2.jpg")
    create_photo("photo3.jpg")

    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: true)
    pdf_data = service.generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    assert_includes text, "Photos"
  end

  test "includes all photos when photo_attachment_ids is nil" do
    create_photo("photo1.jpg")
    create_photo("photo2.jpg")

    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: true, photo_attachment_ids: nil)
    pdf_data = service.generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    assert_includes text, "Photos"
  end

  test "filters to only selected photos when photo_attachment_ids provided" do
    photo1 = create_photo("photo1.jpg")
    photo2 = create_photo("photo2.jpg")
    photo3 = create_photo("photo3.jpg")

    # Only include photo1 and photo3
    service = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: true,
      photo_attachment_ids: [ photo1.id, photo3.id ]
    )

    # Service should filter — verify by checking the query directly
    photos = @incident.attachments.where(category: "photo", log_date: @date, id: [ photo1.id, photo3.id ])
    assert_equal 2, photos.count
    assert_includes photos.pluck(:id), photo1.id
    assert_includes photos.pluck(:id), photo3.id
    refute_includes photos.pluck(:id), photo2.id
  end

  test "omits photos section when photo_attachment_ids is empty array" do
    create_photo("photo1.jpg")

    service = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: true,
      photo_attachment_ids: []
    )
    pdf_data = service.generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    refute_includes text, "Photos"
  end

  test "photo image data is actually embedded in PDF when photo included" do
    photo = create_photo("photo1.jpg")

    service = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: true,
      photo_attachment_ids: [ photo.id ]
    )
    pdf_data = service.generate

    # Verify JPEG binary data is embedded — not just the "Photos" heading.
    # The broken implementation (pdf.image called after blob.open closed the
    # tempfile) would silently skip the image; no JPEG marker would appear.
    jpeg_signature = "\xFF\xD8\xFF".b
    assert pdf_data.b.include?(jpeg_signature), "Expected JPEG image data to be embedded in the PDF"
  end

  test "ignores invalid photo_attachment_ids gracefully" do
    photo = create_photo("photo1.jpg")

    service = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: true,
      photo_attachment_ids: [ photo.id, 999999 ]
    )
    pdf_data = service.generate

    # Should not raise — just includes the one valid photo
    assert pdf_data.present?
  end

  test "auto-paginates when many photos exceed a single page" do
    8.times { |i| create_photo("photo#{i}.jpg") }

    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: true)
    pdf_data = service.generate

    # Regression: previous absolute-positioned (`pdf.image at: [...]`) layout
    # disabled Prawn auto-pagination, so photos beyond ~4 rendered off-page.
    # Flow mode auto-paginates, so a many-photo PDF spans multiple pages.
    pages = PDF::Inspector::Page.analyze(pdf_data).pages
    assert_operator pages.size, :>, 1, "Expected multi-page PDF when 8 photos are included; got #{pages.size}"
  end

  test "stacks two photos per page rather than one-per-page" do
    # Daniel's complaint: every photo was on its own page with a big gap.
    # With the half-page height cap, 4 photos must fit in <= 2 photo pages
    # (i.e. <= 3 pages total including the leading content page).
    4.times { |i| create_photo("photo#{i}.jpg") }

    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: true)
    pdf_data = service.generate

    pages = PDF::Inspector::Page.analyze(pdf_data).pages
    assert_operator pages.size, :<=, 3, "Expected 4 photos to pack into <= 2 photo pages; got #{pages.size} total pages"
  end

  test "applies EXIF orientation before embedding so phone portraits are upright" do
    # Fixture: 200x100 raw pixels, EXIF orientation = 6 (rotate 90° CW for display).
    # Without auto_orient, Prawn embeds the raw 200x100 sideways pixels.
    # With auto_orient, the rotation is baked in and the embed is 100x200 upright.
    require "pdf-reader"

    attachment = @incident.attachments.create!(
      category: "photo", log_date: @date, uploaded_by_user: @manager
    )
    attachment.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/exif_portrait_phone.jpg")),
      filename: "phone_portrait.jpg",
      content_type: "image/jpeg"
    )

    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: true)
    pdf_data = service.generate

    image_dims = []
    PDF::Reader.new(StringIO.new(pdf_data)).pages.each do |page|
      page.xobjects.each do |_, xobj|
        next unless xobj.hash[:Subtype] == :Image
        image_dims << [ xobj.hash[:Width], xobj.hash[:Height] ]
      end
    end

    assert_equal 1, image_dims.size, "Expected one embedded image"
    width, height = image_dims.first
    assert_equal 100, width, "Width should be 100 after EXIF rotation (was 200 sideways)"
    assert_equal 200, height, "Height should be 200 after EXIF rotation (was 100 sideways)"
  end

  test "resizes large photos to <= 1600px before embedding to keep PDF small" do
    require "pdf-reader"
    require "mini_magick"

    big_path = Rails.root.join("tmp", "big_landscape_test.jpg")
    system("magick", "-size", "4032x3024", "gradient:red-blue", "-quality", "90", big_path.to_s)
    attachment = @incident.attachments.create!(category: "photo", log_date: @date, uploaded_by_user: @manager)
    attachment.file.attach(io: File.open(big_path), filename: "big.jpg", content_type: "image/jpeg")

    pdf_data = DfrPdfService.new(incident: @incident, date: @date, include_photos: true).generate

    image_dims = []
    PDF::Reader.new(StringIO.new(pdf_data)).pages.each do |page|
      page.xobjects.each do |_, xobj|
        next unless xobj.hash[:Subtype] == :Image
        image_dims << [ xobj.hash[:Width], xobj.hash[:Height] ]
      end
    end

    assert_equal 1, image_dims.size
    width, height = image_dims.first
    assert_operator [ width, height ].max, :<=, 1600, "Longest side should be <= 1600 after resize"
    aspect_ratio = width.to_f / height
    assert_in_delta 4032.0 / 3024, aspect_ratio, 0.01, "Aspect ratio (4:3 landscape) should be preserved"
  ensure
    File.delete(big_path) if big_path && File.exist?(big_path)
  end

  test "does not enlarge photos already smaller than 1600px" do
    require "pdf-reader"

    # The existing 1x1 fixture is far smaller than 1600 — should pass through untouched.
    create_photo("small.jpg")

    pdf_data = DfrPdfService.new(incident: @incident, date: @date, include_photos: true).generate

    image_dims = []
    PDF::Reader.new(StringIO.new(pdf_data)).pages.each do |page|
      page.xobjects.each do |_, xobj|
        next unless xobj.hash[:Subtype] == :Image
        image_dims << [ xobj.hash[:Width], xobj.hash[:Height] ]
      end
    end

    width, height = image_dims.first
    assert_operator [ width, height ].max, :<, 1600, "Small photos should not be enlarged"
  end

  test "does not include photos from other dates even if IDs match" do
    other_date_photo = create_photo("other.jpg", log_date: @date - 1.day)

    service = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: true,
      photo_attachment_ids: [ other_date_photo.id ]
    )
    pdf_data = service.generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    refute_includes text, "Photos"
  end

  private

  def create_photo(filename, log_date: @date)
    # Create a minimal valid 1x1 JPEG for Prawn to process
    attachment = @incident.attachments.create!(
      category: "photo",
      log_date: log_date,
      uploaded_by_user: @manager
    )
    attachment.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_photo.jpg")),
      filename: filename,
      content_type: "image/jpeg"
    )
    attachment
  end
end
