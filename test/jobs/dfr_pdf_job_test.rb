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
    assert_includes attachment.file.filename.to_s, "DFR-"
    assert_equal "application/pdf", attachment.file.content_type
    assert_equal date, attachment.log_date.to_s
  end

  test "uses incident job_id in filename when available" do
    @incident.update!(job_id: "JOB-123")
    date = Date.current.to_s

    DfrPdfJob.perform_now(@incident.id, date, "America/Chicago", @manager.id)

    attachment = @incident.attachments.last
    assert_includes attachment.file.filename.to_s, "DFR-JOB-123"
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

  test "PDF includes equipment summary with counts and hours for on-site equipment" do
    require "pdf/inspector"

    dehu = EquipmentType.create!(name: "Dehumidifier", organization: @genixo)
    air_mover = EquipmentType.create!(name: "Air Mover", organization: @genixo)

    # 2 dehumidifiers placed yesterday, still on-site
    EquipmentEntry.create!(incident: @incident, equipment_type: dehu,
      placed_at: 1.day.ago, logged_by_user: @manager)
    EquipmentEntry.create!(incident: @incident, equipment_type: dehu,
      placed_at: 1.day.ago, logged_by_user: @manager)

    # 1 air mover placed yesterday, still on-site
    EquipmentEntry.create!(incident: @incident, equipment_type: air_mover,
      placed_at: 1.day.ago, logged_by_user: @manager)

    pdf_data = DfrPdfService.new(
      incident: @incident, date: Date.current, timezone: "America/Chicago", include_photos: false
    ).generate

    text = PDF::Inspector::Text.analyze(pdf_data).strings.join(" ")
    assert_includes text, "Equipment:"
    assert_includes text, "2 Dehumidifier"
    assert_includes text, "1 Air Mover"
    assert_match(/\d+\.\d+ hrs/, text, "Should include hours for equipment")
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
    assert_includes text, "1 Dehumidifier"
    refute_includes text, "Air Mover", "Removed equipment should not appear"
  end

  test "PDF excludes equipment placed after the report date" do
    require "pdf/inspector"

    dehu = EquipmentType.create!(name: "Dehumidifier", organization: @genixo)

    # Placed tomorrow — should NOT appear on today's DFR
    EquipmentEntry.create!(incident: @incident, equipment_type: dehu,
      placed_at: 1.day.from_now, logged_by_user: @manager)

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
end
