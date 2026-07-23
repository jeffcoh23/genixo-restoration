require "test_helper"

class DfrPdfJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "Sunset Apts", mitigation_org: @genixo, property_management_org: @greystar)

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")

    @incident = Incident.create!(property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood", description: "Test DFR")
  end

  test "creates an attachment with generated PDF" do
    date = Date.current.to_s

    assert_difference -> { @incident.attachments.count }, 1 do
      DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)
    end

    attachment = @incident.attachments.last
    assert_equal "dfr", attachment.category
    assert attachment.file.attached?
    assert_equal "application/pdf", attachment.file.content_type
    assert_equal date, attachment.log_date.to_s
  end

  test "renders the weather line when a snapshot is cached for the incident/date" do
    require "pdf/inspector"
    date = Date.current
    # Pre-cache weather so WeatherService.for returns it without any HTTP; this
    # proves the job fetches weather and threads it into the rendered PDF.
    WeatherSnapshot.create!(incident: @incident, date: date, temp_max: 90, temp_min: 70,
      conditions: "Sunny", wind_speed: 8, fetched_at: Time.current)

    DfrPdfJob.perform_now(@incident.id, date.to_s, "America/Chicago", @manager.id)

    pdf = @incident.attachments.where(category: "dfr").last.file.download
    text = PDF::Inspector::Text.analyze(pdf).strings.join(" ")
    assert_includes text, "Weather:"
    assert_includes text, "Sunny"
  end

  test "generates the DFR normally when weather is unavailable" do
    # No cached snapshot and no API key (test_helper unsets it) → WeatherService
    # returns nil → the DFR must still generate without a weather line.
    date = Date.current
    assert_difference -> { @incident.attachments.count }, 1 do
      DfrPdfJob.perform_now(@incident.id, date.to_s, "America/Chicago", @manager.id)
    end
    require "pdf/inspector"
    pdf = @incident.attachments.where(category: "dfr").last.file.download
    refute_includes PDF::Inspector::Text.analyze(pdf).strings.join(" "), "Weather:"
  end

  test "filename uses 'DFR - Property - JobNumber - Date' format when job_id is present" do
    @incident.update!(job_id: "JOB-123")
    date = Date.current.to_s

    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)

    attachment = @incident.attachments.last
    assert_equal "DFR - Sunset Apts - JOB-123 - #{date}.pdf", attachment.file.filename.to_s
  end

  test "filename omits job number segment when incident has no job_id" do
    date = Date.current.to_s

    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)

    attachment = @incident.attachments.last
    assert_equal "DFR - Sunset Apts - #{date}.pdf", attachment.file.filename.to_s
  end

  test "filename sanitizes property names with filesystem-unfriendly characters" do
    @property.update!(name: "Bldg A/B: Phase 1")
    date = Date.current.to_s

    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)

    attachment = @incident.attachments.last
    refute_match(/[\/\\:*?"<>|]/, attachment.file.filename.to_s)
    assert_includes attachment.file.filename.to_s, "Bldg A B Phase 1"
  end

  test "sets description with date" do
    date = Date.current.to_s
    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)

    attachment = @incident.attachments.last
    assert_includes attachment.description, date
  end

  test "skips if DFR already exists for that date" do
    date = Date.current.to_s

    # Create first DFR
    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)
    assert_equal 1, @incident.attachments.where(category: "dfr", log_date: date).count

    # Second call should be a no-op
    assert_no_difference -> { @incident.attachments.count } do
      DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)
    end
  end

  test "regenerating a DFR replaces the file and keeps it attached" do
    date = Date.current.to_s

    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)
    dfr = @incident.attachments.find_by(category: "dfr", log_date: date)
    original_blob_id = dfr.file.blob.id

    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)
    dfr.reload

    assert dfr.file.attached?, "DFR should still have a file after regeneration"
    refute_equal original_blob_id, dfr.file.blob.id, "regeneration should attach a new blob"
  end

  test "PDF lists equipment per unit with ID, type, start date, and end date" do
    require "pdf/inspector"

    # Pinned to mid-morning Chicago: relative times ("2 hours ago") land on the
    # same calendar day in UTC and America/Chicago — around the UTC date
    # rollover they otherwise straddle days and the removed unit vanishes.
    travel_to Time.utc(2026, 5, 15, 14, 0, 0) do
      dehu = EquipmentType.create!(name: "Dehumidifier", organization: @genixo)
      air_mover = EquipmentType.create!(name: "Air Mover", organization: @genixo)

      EquipmentEntry.create!(incident: @incident, equipment_type: dehu, tag_number: "DH-101",
        placed_at: 2.days.ago, logged_by_user: @manager)
      EquipmentEntry.create!(incident: @incident, equipment_type: dehu, equipment_identifier: "SN-555",
        placed_at: 1.day.ago, logged_by_user: @manager)
      EquipmentEntry.create!(incident: @incident, equipment_type: air_mover, tag_number: "AM-7",
        placed_at: 2.days.ago, removed_at: 2.hours.ago, logged_by_user: @manager)

      pdf_data = DfrPdfService.new(
        incident: @incident, date: Date.current, timezone: "America/Chicago", include_photos: false
      ).generate

      text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
      assert_includes text, "Equipment:"
      # Header row + one row per unit, tagged by ID and type.
      [ "ID", "Type", "Start Date", "End Date", "Hours" ].each { |h| assert_includes text, h }
      # Whole hours-in-place per unit. The removed unit's figure is exact:
      # placed 2 days ago, removed 2 hours ago → 46 hours. (In-place units cap
      # at the report day's end, so their figures depend on the frozen clock.)
      assert_match(/\b46\b/, text, "removed unit shows its cumulative hours (48h placed - 2h early removal)")
      assert_includes text, "DH-101"
      assert_includes text, "SN-555"
      assert_includes text, "AM-7"
      assert_includes text, "Dehumidifier"
      assert_includes text, "Air Mover"
      assert_includes text, "In place", "still-deployed units must show In place, not an end date"
      assert_includes text, "5/15/26", "removed unit shows its end date"
      refute_match(/\d+\.\d+ hrs/, text, "the computed hours aggregate must be gone")
    end
  end

  test "PDF excludes equipment removed before the report date" do
    require "pdf/inspector"

    dehu = EquipmentType.create!(name: "Dehumidifier", organization: @genixo)
    air_mover = EquipmentType.create!(name: "Air Mover", organization: @genixo)

    # Dehumidifier still on-site
    EquipmentEntry.create!(incident: @incident, equipment_type: dehu,
      placed_at: 2.days.ago, logged_by_user: @manager)

    # Air mover removed yesterday — should NOT appear on today's DFR
    EquipmentEntry.create!(incident: @incident, equipment_type: air_mover,
      placed_at: 3.days.ago, removed_at: 1.day.ago, logged_by_user: @manager)

    pdf_data = DfrPdfService.new(
      incident: @incident, date: Date.current, timezone: "America/Chicago", include_photos: false
    ).generate

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    assert_includes text, "Dehumidifier"
    refute_includes text, "Air Mover", "Removed equipment should not appear"
  end

  test "PDF excludes equipment placed after the report date" do
    require "pdf/inspector"

    dehu = EquipmentType.create!(name: "Dehumidifier", organization: @genixo)

    # Placed 2 days from now — should NOT appear on today's DFR
    EquipmentEntry.create!(incident: @incident, equipment_type: dehu,
      placed_at: 2.days.from_now, logged_by_user: @manager)

    pdf_data = DfrPdfService.new(
      incident: @incident, date: Date.current, timezone: "America/Chicago", include_photos: false
    ).generate

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    refute_includes text, "Equipment:", "No equipment section when nothing on-site"
  end

  test "PDF omits equipment section when no equipment exists" do
    require "pdf/inspector"

    pdf_data = DfrPdfService.new(
      incident: @incident, date: Date.current, timezone: "America/Chicago", include_photos: false
    ).generate

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    refute_includes text, "Equipment:"
  end

  test "passes photo_attachment_ids to service when provided" do
    date = Date.current.to_s

    # Create photos for today
    photo1 = @incident.attachments.create!(category: "photo", log_date: date, uploaded_by_user: @manager)
    photo1.file.attach(io: StringIO.new("fake"), filename: "photo1.jpg", content_type: "image/jpeg")
    photo2 = @incident.attachments.create!(category: "photo", log_date: date, uploaded_by_user: @manager)
    photo2.file.attach(io: StringIO.new("fake"), filename: "photo2.jpg", content_type: "image/jpeg")

    # Pass only photo1's ID
    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id, [ photo1.id ])

    attachment = @incident.attachments.where(category: "dfr").last
    assert attachment.file.attached?
  end

  test "generates DFR without photos when empty array passed" do
    date = Date.current.to_s

    photo = @incident.attachments.create!(category: "photo", log_date: date, uploaded_by_user: @manager)
    photo.file.attach(io: StringIO.new("fake"), filename: "photo.jpg", content_type: "image/jpeg")

    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id, [])

    attachment = @incident.attachments.where(category: "dfr").last
    assert attachment.file.attached?
  end

  test "generates DFR with all photos when nil passed (backwards compatible)" do
    date = Date.current.to_s

    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id, nil)

    attachment = @incident.attachments.where(category: "dfr").last
    assert attachment.file.attached?
  end

  test "runs with the pre-documents argument list (jobs enqueued before deploy)" do
    # Solid Queue serializes positional args: a job enqueued before the
    # document_attachment_ids param existed carries only five arguments and
    # must still run after deploy.
    date = Date.current.to_s

    assert_nothing_raised do
      DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id, nil)
    end
    assert @incident.attachments.where(category: "dfr").last.file.attached?
  end

  test "retries on a transient generation failure instead of dropping the report" do
    require "minitest/mock"
    date = Date.current.to_s

    # Simulate a transient failure (e.g. a flaky S3 read surfacing as a nil).
    # retry_on must catch it and re-enqueue rather than fail outright.
    raising = ->(*_args, **_kw) { raise StandardError, "transient S3 blip" }
    with_test_queue_adapter do
      assert_enqueued_jobs 1, only: DfrPdfJob do
        DfrPdfService.stub(:new, raising) do
          DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)
        end
      end
    end
  end

  test "discards (never retries) when the incident no longer exists" do
    date = Date.current.to_s

    # A deleted incident raises RecordNotFound, which can never succeed — it must
    # be discarded, not retried forever, and must not raise.
    with_test_queue_adapter do
      assert_no_enqueued_jobs do
        assert_nothing_raised do
          DfrPdfJob.perform_now(999_999, date, "America/Chicago", @manager.id)
        end
      end
    end
  end

  test "passes document_attachment_ids through to the generated PDF" do
    require "pdf/inspector"
    require "prawn"
    date = Date.current.to_s

    doc = @incident.attachments.create!(category: "signed_document", uploaded_by_user: @manager)
    doc.file.attach(
      io: StringIO.new(Prawn::Document.new { |p| p.text "Signed scope" }.render),
      filename: "scope.pdf", content_type: "application/pdf"
    )

    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id, nil, [ doc.id ])

    attachment = @incident.attachments.where(category: "dfr").last
    text = PDF::Inspector::Text.analyze(attachment.file.download).strings.join(" ")
    assert_includes text, "scope.pdf (attached)"
  end

  # --- weekly reports ---

  test "end_date produces a weekly_report attachment spanning the range" do
    start_date = Date.current - 6.days

    assert_difference -> { @incident.attachments.where(category: "weekly_report").count }, 1 do
      DfrPdfJob.perform_now(@incident.id, start_date.to_s, "America/Chicago", @manager.id, [], nil, Date.current.to_s)
    end

    attachment = @incident.attachments.where(category: "weekly_report").last
    assert attachment.file.attached?
    assert_equal start_date, attachment.log_date
    assert_equal Date.current, attachment.log_date_end
    assert_includes attachment.description, "Weekly Field Report"

    require "pdf/inspector"
    text = PDF::Inspector::Text.analyze(attachment.file.download).strings.join(" ")
    assert_includes text, "Weekly Field Report"
  end

  test "weekly filename spans the range" do
    @incident.update!(job_id: "JOB-123")
    start_date = Date.current - 6.days

    DfrPdfJob.perform_now(@incident.id, start_date.to_s, "America/Chicago", @manager.id, [], nil, Date.current.to_s)

    attachment = @incident.attachments.where(category: "weekly_report").last
    assert_equal "Weekly Report - Sunset Apts - JOB-123 - #{start_date} to #{Date.current}.pdf",
      attachment.file.filename.to_s
  end

  test "regenerating the same span replaces the file instead of adding a row" do
    start_date = Date.current - 6.days
    args = [ @incident.id, start_date.to_s, "America/Chicago", @manager.id, [], nil, Date.current.to_s ]

    DfrPdfJob.perform_now(*args)
    report = @incident.attachments.find_by(category: "weekly_report", log_date: start_date)
    original_blob_id = report.file.blob.id

    assert_no_difference -> { @incident.attachments.count } do
      DfrPdfJob.perform_now(*args)
    end
    report.reload
    assert report.file.attached?
    refute_equal original_blob_id, report.file.blob.id
  end

  test "same start date with different end dates are distinct weekly reports" do
    start_date = Date.current - 13.days

    DfrPdfJob.perform_now(@incident.id, start_date.to_s, "America/Chicago", @manager.id, [], nil, (start_date + 6).to_s)
    DfrPdfJob.perform_now(@incident.id, start_date.to_s, "America/Chicago", @manager.id, [], nil, (start_date + 13).to_s)

    assert_equal 2, @incident.attachments.where(category: "weekly_report", log_date: start_date).count
  end

  test "a weekly report and a DFR for the same date coexist" do
    date = Date.current

    DfrPdfJob.perform_now(@incident.id, date.to_s, "America/Chicago", @manager.id)
    DfrPdfJob.perform_now(@incident.id, date.to_s, "America/Chicago", @manager.id, [], nil, (date + 6).to_s)

    assert_equal 1, @incident.attachments.where(category: "dfr", log_date: date).count
    assert_equal 1, @incident.attachments.where(category: "weekly_report", log_date: date).count
  end

  test "a losing concurrent weekly insert attaches over the winner's row" do
    start_date = Date.current - 6.days
    end_date = Date.current

    # Simulate the race: the winner's row appears after this job's find_by
    # returned nothing. The unique index rejects the insert; the job must
    # rescue and attach over the winner instead of failing.
    winner = @incident.attachments.create!(category: "weekly_report",
      log_date: start_date, log_date_end: end_date, uploaded_by_user: @manager)

    original_find_by = Attachment.method(:find_by)
    faked_once = false
    assert_no_difference -> { @incident.attachments.count } do
      @incident.attachments.singleton_class.define_method(:find_by) do |*args, **kw|
        if !faked_once && kw[:category] == "weekly_report"
          faked_once = true
          nil
        else
          super(*args, **kw)
        end
      end
      DfrPdfJob.perform_now(@incident.id, start_date.to_s, "America/Chicago", @manager.id, [], nil, end_date.to_s)
    end

    assert winner.reload.file.attached?, "the job must attach its PDF onto the winner's row"
  end

  test "weekly report threads per-day cached weather into the PDF" do
    require "pdf/inspector"
    start_date = Date.current - 2.days
    WeatherSnapshot.create!(incident: @incident, date: start_date, temp_max: 90, temp_min: 70,
      conditions: "Sunny start", fetched_at: Time.current)
    WeatherSnapshot.create!(incident: @incident, date: Date.current, temp_max: 60, temp_min: 50,
      conditions: "Rainy finish", fetched_at: Time.current)

    DfrPdfJob.perform_now(@incident.id, start_date.to_s, "America/Chicago", @manager.id, [], nil, Date.current.to_s)

    pdf = @incident.attachments.where(category: "weekly_report").last.file.download
    text = PDF::Inspector::Text.analyze(pdf).strings.join(" ")
    assert_includes text, "Sunny start"
    assert_includes text, "Rainy finish"
  end

  private

  # This app runs Solid Queue as the ActiveJob adapter even in tests, so the
  # enqueue assertions (which need the :test adapter) require a local swap.
  def with_test_queue_adapter
    old = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    yield
  ensure
    ActiveJob::Base.queue_adapter = old
  end
end
