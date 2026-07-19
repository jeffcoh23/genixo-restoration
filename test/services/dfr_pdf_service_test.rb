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

  test "renders a weather line with attribution when a snapshot is provided" do
    weather = WeatherSnapshot.new(
      incident: @incident, date: @date, temp_max: 88, temp_min: 71, temp_avg: 79,
      conditions: "Partly cloudy", precip: 0.12, wind_speed: 9, fetched_at: Time.current
    )
    pdf_data = DfrPdfService.new(incident: @incident, date: @date, include_photos: false, weather: weather).generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    # Stable tokens only — PDF::Inspector splits runs unpredictably, so the exact
    # temp/precip formatting is asserted in WeatherSnapshotTest#summary_line.
    assert_includes text, "Weather:"
    assert_includes text, "Partly cloudy"
    assert_includes text, "Weather data by Visual Crossing"
  end

  test "omits the weather line when no snapshot is provided" do
    pdf_data = DfrPdfService.new(incident: @incident, date: @date, include_photos: false).generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    refute_includes text, "Weather:"
    refute_includes text, "Visual Crossing"
  end

  test "API-sourced conditions render as literal text, never as inline_format markup" do
    weather = WeatherSnapshot.new(
      incident: @incident, date: @date, temp_max: 80, temp_min: 60,
      conditions: "<i>Rain & hail</i>", fetched_at: Time.current
    )
    pdf_data = DfrPdfService.new(incident: @incident, date: @date, include_photos: false, weather: weather).generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    # Escaped: the tag characters survive as literal glyphs. Unescaped, Prawn
    # would parse <i>...</i> as italic markup and the brackets would vanish.
    assert_includes text, "<i>Rain & hail</i>"
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
    # `convert` works on both ImageMagick 6 (Ubuntu apt) and 7 (macOS brew).
    system("convert", "-size", "4032x3024", "gradient:red-blue", "-quality", "90", big_path.to_s) ||
      raise("ImageMagick convert command failed — is `imagemagick` installed?")
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

  test "renders smart quotes and other non-Latin-1 chars without raising" do
    # Regression: Daniel's iPad-typed DFRs failed in 26ms because Prawn's
    # default Helvetica font rejects U+2019 (’). iOS auto-corrects every
    # apostrophe to a smart quote, so every it’s/door’s broke the entire PDF.
    smart = 0x2019.chr("UTF-8")  # ’ right single quotation mark
    em_space = 0x2003.chr("UTF-8")  # em-wide space
    em_dash = 0x2014.chr("UTF-8")  # — em dash

    # travel_to keeps occurred_at and @date in lockstep — otherwise the UTC date
    # (used for @date) and the Chicago day-window the service queries can
    # straddle midnight, dropping the activity from the report (CI flake).
    travel_to Time.utc(2026, 5, 15, 14, 0, 0) do
      @date = Date.current
      @incident.activity_entries.create!(
        title: "Scope#{smart}",
        details: "All door#{smart}s 6 in. trim#{em_dash}rebuild#{em_space}required",
        occurred_at: Time.current,
        performed_by_user: @manager
      )

      pdf_data = DfrPdfService.new(incident: @incident, date: @date, include_photos: false).generate
      text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

      assert_includes text, "door#{smart}s", "smart quote should survive in rendered PDF"
      assert_includes text, "rebuild", "em dash should not break surrounding text"
    end
  end

  test "falls back to ASCII-coerced text when font lacks a glyph" do
    # Noto Sans covers Latin/Greek/Cyrillic but not emoji. Rather than fail
    # the whole report, the service should retry with sanitized text.
    travel_to Time.utc(2026, 5, 15, 14, 0, 0) do
      @date = Date.current
      @incident.activity_entries.create!(
        title: "Emoji test",
        details: "Job site update 🔥 all clear 🚧",
        occurred_at: Time.current,
        performed_by_user: @manager
      )

      pdf_data = nil
      assert_nothing_raised do
        pdf_data = DfrPdfService.new(incident: @incident, date: @date, include_photos: false).generate
      end
      text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
      assert_includes text, "Job site update", "non-emoji content should survive sanitization"
      assert_includes text, "all clear", "non-emoji content should survive sanitization"
    end
  end

  test "includes photos from other dates when explicitly selected" do
    # Daniel: "we should be able to select any photos, not just photos for
    # that day." An explicit selection overrides the report-date scoping.
    other_date_photo = create_photo("other.jpg", log_date: @date - 1.day)

    service = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: true,
      photo_attachment_ids: [ other_date_photo.id ]
    )
    pdf_data = service.generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    assert_includes text, "Photos"
    assert_includes pdf_data, "DCTDecode", "selected cross-date photo should be embedded as JPEG"
  end

  test "nil photo_attachment_ids still scopes photos to the report date" do
    create_photo("other.jpg", log_date: @date - 1.day)

    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: true, photo_attachment_ids: nil)
    pdf_data = service.generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    refute_includes text, "Photos"
  end

  test "photo IDs belonging to another incident are excluded" do
    other_incident = Incident.create!(property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Other")
    foreign = other_incident.attachments.create!(category: "photo", log_date: @date, uploaded_by_user: @manager)
    foreign.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_photo.jpg")),
      filename: "foreign.jpg", content_type: "image/jpeg"
    )

    service = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: true,
      photo_attachment_ids: [ foreign.id ]
    )
    pdf_data = service.generate
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")

    refute_includes text, "Photos"
  end

  # --- documents ---

  test "appends a selected PDF document's pages to the DFR" do
    doc = create_pdf_document("scope.pdf")

    base = DfrPdfService.new(incident: @incident, date: @date, include_photos: false).generate
    with_doc = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: false,
      document_attachment_ids: [ doc.id ]
    ).generate

    text = PDF::Inspector::Text.analyze(with_doc).strings.join(" ")
    assert_includes text, "Documents"
    assert_includes text, "scope.pdf (attached)"
    # documents section adds one page; the appended document adds its own page
    assert_equal page_count(base) + 2, page_count(with_doc)
  end

  test "corrupt PDF documents are listed by filename, never fail the DFR" do
    doc = create_pdf_document("broken.pdf", content: "not really a pdf at all")

    pdf_data = nil
    assert_nothing_raised do
      pdf_data = DfrPdfService.new(
        incident: @incident, date: @date, include_photos: false,
        document_attachment_ids: [ doc.id ]
      ).generate
    end

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    assert_includes text, "broken.pdf (could not be attached)"
    refute_includes text, "(attached)"
  end

  test "documents over the per-file size cap are listed, not appended" do
    doc = create_pdf_document("huge.pdf")
    # byte_size is a column on the blob — fake an oversized upload without
    # allocating the bytes
    doc.file.blob.update_column(:byte_size, DfrPdfService::MAX_DOCUMENT_BYTES + 1)

    pdf_data = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: false,
      document_attachment_ids: [ doc.id ]
    ).generate

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    assert_includes text, "huge.pdf (too large to attach)"
    refute_includes text, "(attached)"
  end

  test "documents past the aggregate cap are listed, not appended" do
    near_cap = DfrPdfService::MAX_DOCUMENT_BYTES - 1.kilobyte
    docs = [ "a.pdf", "b.pdf", "c.pdf" ].map { |name| create_pdf_document(name) }
    docs.each { |d| d.file.blob.update_column(:byte_size, near_cap) }

    pdf_data = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: false,
      document_attachment_ids: docs.map(&:id)
    ).generate

    # 15MB-ish each against a 40MB aggregate: two append, the third is listed
    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    assert_includes text, "a.pdf (attached)"
    assert_includes text, "b.pdf (attached)"
    assert_includes text, "c.pdf (too large to attach)"
    refute_includes text, "c.pdf (attached)"
  end

  test "document IDs belonging to another incident are excluded" do
    other_incident = Incident.create!(property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Other")
    foreign = other_incident.attachments.create!(category: "signed_document", uploaded_by_user: @manager)
    foreign.file.attach(io: StringIO.new(minimal_pdf), filename: "foreign.pdf", content_type: "application/pdf")

    pdf_data = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: false,
      document_attachment_ids: [ foreign.id ]
    ).generate

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    refute_includes text, "Documents"
    refute_includes text, "foreign.pdf"
  end

  test "glyph-fallback rebuild still appends documents correctly" do
    # An emoji forces with_glyph_fallback to build the PDF twice; the memoized
    # parsed documents must survive being appended in both builds.
    travel_to Time.utc(2026, 5, 15, 14, 0, 0) do
      @date = Date.current
      @incident.activity_entries.create!(
        title: "Emoji retry 🔥", occurred_at: Time.current, performed_by_user: @manager
      )
      doc = create_pdf_document("retry.pdf")

      pdf_data = DfrPdfService.new(
        incident: @incident, date: @date, include_photos: false,
        document_attachment_ids: [ doc.id ]
      ).generate

      assert pdf_data.start_with?("%PDF")
      text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
      assert_includes text, "retry.pdf (attached)"
      assert_includes text, "Attached document body"
    end
  end

  test "image documents are embedded, non-PDF documents listed by filename" do
    image_doc = @incident.attachments.create!(category: "signed_document", uploaded_by_user: @manager)
    image_doc.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_photo.jpg")),
      filename: "site-map.jpg", content_type: "image/jpeg"
    )
    word_doc = @incident.attachments.create!(category: "general", uploaded_by_user: @manager)
    word_doc.file.attach(io: StringIO.new("fake docx"), filename: "notes.docx",
      content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document")

    pdf_data = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: false,
      document_attachment_ids: [ image_doc.id, word_doc.id ]
    ).generate

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    assert_includes text, "site-map.jpg"
    assert_includes text, "notes.docx"
    assert_includes pdf_data, "DCTDecode", "image document should be embedded as JPEG"
  end

  test "image documents over the per-file cap are listed, not embedded" do
    image_doc = @incident.attachments.create!(category: "signed_document", uploaded_by_user: @manager)
    image_doc.file.attach(
      io: File.open(Rails.root.join("test/fixtures/files/test_photo.jpg")),
      filename: "huge-scan.jpg", content_type: "image/jpeg"
    )
    image_doc.file.blob.update_column(:byte_size, DfrPdfService::MAX_DOCUMENT_BYTES + 1)

    pdf_data = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: false,
      document_attachment_ids: [ image_doc.id ]
    ).generate

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    assert_includes text, "huge-scan.jpg (too large to attach)"
    refute_includes pdf_data, "DCTDecode", "oversized image must not be embedded"
  end

  test "active content is stripped from appended PDF pages" do
    require "combine_pdf"
    # Author a PDF whose page carries script-bearing actions: an
    # additional-actions dict (/AA) plus a link annotation firing JavaScript.
    source = CombinePDF.parse(minimal_pdf)
    page = source.pages.first
    page[:AA] = { O: { S: :JavaScript, JS: "app.alert('aa-open')" } }
    page[:Annots] = [ {
      Type: :Annot, Subtype: :Link, Rect: [ 0, 0, 10, 10 ],
      A: { S: :JavaScript, JS: "app.alert('link-js')" }
    } ]
    doc = create_pdf_document("scripted.pdf", content: source.to_pdf)

    pdf_data = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: false,
      document_attachment_ids: [ doc.id ]
    ).generate

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    assert_includes text, "scripted.pdf (attached)"
    assert_includes text, "Attached document body", "page content must survive stripping"
    refute_includes pdf_data, "app.alert", "JavaScript must not survive into the DFR"
    refute_includes pdf_data, "/AA", "additional-actions dict must be stripped"
  end

  test "documents without an attached file are skipped gracefully" do
    bare = @incident.attachments.create!(category: "signed_document", uploaded_by_user: @manager)

    pdf_data = nil
    assert_nothing_raised do
      pdf_data = DfrPdfService.new(
        incident: @incident, date: @date, include_photos: false,
        document_attachment_ids: [ bare.id ]
      ).generate
    end

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    refute_includes text, "Documents", "file-less attachment should not produce a Documents section"
  end

  test "concat falls back to an in-memory merge when pdfunite is unavailable" do
    require "combine_pdf"
    require "open3"
    require "tmpdir"
    require "minitest/mock"
    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: false)

    Dir.mktmpdir do |dir|
      a = File.join(dir, "a.pdf"); File.binwrite(a, minimal_pdf)
      b = File.join(dir, "b.pdf"); File.binwrite(b, minimal_pdf)

      # Simulate pdfunite missing (capture3 raises ENOENT). The CombinePDF
      # fallback must still stitch both parts into a valid PDF.
      merged = Open3.stub(:capture3, ->(*) { raise Errno::ENOENT, "pdfunite" }) do
        service.send(:concat_parts, [ a, b ], dir)
      end

      assert_equal 2, page_count(merged), "fallback merge must combine both parts"
    end
  end

  test "concat returns the body part when both pdfunite and the fallback merge fail" do
    require "combine_pdf"
    require "open3"
    require "tmpdir"
    require "minitest/mock"
    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: false)

    Dir.mktmpdir do |dir|
      body = File.join(dir, "body.pdf"); File.binwrite(body, minimal_pdf)
      other = File.join(dir, "b.pdf"); File.binwrite(other, minimal_pdf)

      # pdfunite missing AND every part fails to load: generation must never
      # raise — it ships the body part alone. DfrPdfJob has no retry, so a raise
      # would leave the UI polling forever.
      result = Open3.stub(:capture3, ->(*) { raise Errno::ENOENT, "pdfunite" }) do
        CombinePDF.stub(:load, ->(*) { raise StandardError, "merge boom" }) do
          service.send(:concat_parts, [ body, other ], dir)
        end
      end

      assert_equal File.binread(body), result, "must fall back to the body part, never raise"
    end
  end

  test "fallback skips a corrupt part instead of losing the whole report" do
    require "combine_pdf"
    require "open3"
    require "tmpdir"
    require "minitest/mock"
    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: false)

    Dir.mktmpdir do |dir|
      body = File.join(dir, "body.pdf"); File.binwrite(body, minimal_pdf)
      corrupt = File.join(dir, "corrupt.pdf"); File.binwrite(corrupt, "not a pdf")
      good = File.join(dir, "good.pdf"); File.binwrite(good, minimal_pdf)

      # pdfunite missing → in-memory fallback. One part is corrupt; it must be
      # skipped, not sink the two good parts.
      merged = Open3.stub(:capture3, ->(*) { raise Errno::ENOENT, "pdfunite" }) do
        service.send(:concat_parts, [ body, corrupt, good ], dir)
      end

      assert_equal 2, page_count(merged), "corrupt part skipped; body + good part survive"
    end
  end

  test "fallback ships body only when parts exceed the in-memory merge cap" do
    require "open3"
    require "tmpdir"
    require "minitest/mock"
    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: false)

    Dir.mktmpdir do |dir|
      body = File.join(dir, "body.pdf"); File.binwrite(body, minimal_pdf)
      other = File.join(dir, "b.pdf"); File.binwrite(other, minimal_pdf)

      # pdfunite missing AND the parts are (pretend) huge: the fallback must NOT
      # load them all into memory (that re-creates the OOM) — it ships body only.
      oversize = DfrPdfService::MAX_FALLBACK_MERGE_BYTES
      result = Open3.stub(:capture3, ->(*) { raise Errno::ENOENT, "pdfunite" }) do
        File.stub(:size, oversize) do
          service.send(:concat_parts, [ body, other ], dir)
        end
      end

      assert_equal File.binread(body), result, "over the cap, ship body only — never bulk-load into memory"
    end
  end

  test "renders every photo across a batch boundary" do
    # PHOTO_BATCH_SIZE + 1 photos span two batches; the extra photo must not be
    # dropped and the report must stay a valid, multi-page PDF.
    count = DfrPdfService::PHOTO_BATCH_SIZE + 1
    count.times { |i| create_photo("p#{i}.jpg") }

    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: true)
    pdf_data = service.generate

    assert_includes PDF::Inspector::Text.analyze(pdf_data).strings.join(" "), "Photos"
    pages = PDF::Inspector::Page.analyze(pdf_data).pages
    assert_operator pages.size, :>, DfrPdfService::PHOTO_BATCH_SIZE / 2,
      "expected #{count} photos across batches to span many pages; got #{pages.size}"
  end

  test "the Photos heading appears once even when photos span multiple batches" do
    (DfrPdfService::PHOTO_BATCH_SIZE + 3).times { |i| create_photo("p#{i}.jpg") }

    service = DfrPdfService.new(incident: @incident, date: @date, include_photos: true)
    text = PDF::Inspector::Text.analyze(service.generate).strings.join

    assert_equal 1, text.scan("Photos").size, "Photos heading must not repeat per batch"
  end

  test "parts concatenate in order: body, photos (across batches), documents, appended pages" do
    # The whole report in one shot with photos spanning a batch boundary AND an
    # appended PDF — verifies concatenation order is body → photos → documents
    # section → appended document pages, and that nothing is dropped.
    (DfrPdfService::PHOTO_BATCH_SIZE + 2).times { |i| create_photo("p#{i}.jpg") }
    doc = create_pdf_document("scope.pdf")

    service = DfrPdfService.new(
      incident: @incident, date: @date, include_photos: true,
      document_attachment_ids: [ doc.id ]
    )
    text = PDF::Inspector::Text.analyze(service.generate).strings.join(" ")

    photos_at = text.index("Photos")
    docs_at = text.index("Documents")
    appended_at = text.index("Attached document body") # body of the appended minimal_pdf

    assert photos_at, "Photos section missing"
    assert docs_at, "Documents section missing"
    assert appended_at, "appended document page missing"
    assert_operator photos_at, :<, docs_at, "photos must precede the Documents section"
    assert_operator docs_at, :<, appended_at, "the Documents section must precede appended pages"
  end

  private

  def page_count(pdf_data)
    PDF::Inspector::Page.analyze(pdf_data).pages.size
  end

  def minimal_pdf
    require "prawn"
    Prawn::Document.new { |p| p.text "Attached document body" }.render
  end

  def create_pdf_document(filename, category: "signed_document", content: nil)
    att = @incident.attachments.create!(category: category, uploaded_by_user: @manager)
    att.file.attach(
      io: StringIO.new(content || minimal_pdf),
      filename: filename, content_type: "application/pdf"
    )
    att
  end

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
