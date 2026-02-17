require "test_helper"

class DailyActivityServiceTest < ActiveSupport::TestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo
    )

    @manager = User.create!(organization: @genixo, user_type: User::MANAGER,
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Test incident", emergency: true
    )

    @service = DailyActivityService.new(incident: @incident)
    @today = Date.current
    @yesterday = Date.current - 1
  end

  # --- activity_dates ---

  test "returns dates from labor entries" do
    @incident.labor_entries.create!(
      role_label: "Technician", log_date: @today, hours: 4.0,
      started_at: @today.beginning_of_day + 8.hours, ended_at: @today.beginning_of_day + 12.hours,
      user: @manager, created_by_user: @manager
    )
    @incident.labor_entries.create!(
      role_label: "Technician", log_date: @yesterday, hours: 2.0,
      started_at: @yesterday.beginning_of_day + 8.hours, ended_at: @yesterday.beginning_of_day + 10.hours,
      user: @manager, created_by_user: @manager
    )

    dates = @service.activity_dates
    assert_includes dates, @today
    assert_includes dates, @yesterday
    assert_equal @today, dates.first # most recent first
  end

  test "returns dates from equipment entries" do
    dehu = EquipmentType.create!(organization: @genixo, name: "Dehumidifier")
    @incident.equipment_entries.create!(
      equipment_type: dehu, placed_at: @today.beginning_of_day + 9.hours,
      logged_by_user: @manager
    )

    dates = @service.activity_dates
    assert_includes dates, @today
  end

  test "returns dates from removed equipment" do
    dehu = EquipmentType.create!(organization: @genixo, name: "Dehumidifier")
    @incident.equipment_entries.create!(
      equipment_type: dehu,
      placed_at: @yesterday.beginning_of_day + 9.hours,
      removed_at: @today.beginning_of_day + 14.hours,
      logged_by_user: @manager
    )

    dates = @service.activity_dates
    assert_includes dates, @today
    assert_includes dates, @yesterday
  end

  test "returns dates from operational notes" do
    @incident.operational_notes.create!(
      note_text: "Test note", log_date: @today,
      created_by_user: @manager
    )

    dates = @service.activity_dates
    assert_includes dates, @today
  end

  test "returns dates from activity events" do
    ActivityLogger.log(
      incident: @incident, event_type: "status_changed",
      user: @manager, metadata: {}
    )

    dates = @service.activity_dates
    assert_includes dates, @today
  end

  test "deduplicates dates across sources" do
    @incident.labor_entries.create!(
      role_label: "Technician", log_date: @today, hours: 4.0,
      started_at: @today.beginning_of_day + 8.hours, ended_at: @today.beginning_of_day + 12.hours,
      user: @manager, created_by_user: @manager
    )
    @incident.operational_notes.create!(
      note_text: "Test", log_date: @today,
      created_by_user: @manager
    )
    ActivityLogger.log(
      incident: @incident, event_type: "status_changed",
      user: @manager, metadata: {}
    )

    dates = @service.activity_dates
    assert_equal 1, dates.count(@today)
  end

  test "returns empty array when no activity" do
    assert_equal [], @service.activity_dates
  end

  # --- activity_for_date ---

  test "returns labor entries for date" do
    @incident.labor_entries.create!(
      role_label: "Technician", log_date: @today, hours: 4.0,
      started_at: @today.beginning_of_day + 8.hours, ended_at: @today.beginning_of_day + 12.hours,
      user: @manager, created_by_user: @manager
    )
    @incident.labor_entries.create!(
      role_label: "Technician", log_date: @yesterday, hours: 2.0,
      started_at: @yesterday.beginning_of_day + 8.hours, ended_at: @yesterday.beginning_of_day + 10.hours,
      user: @manager, created_by_user: @manager
    )

    result = @service.activity_for_date(@today)
    assert_equal 1, result[:labor_entries].size
    assert_equal @today, result[:labor_entries].first.log_date
  end

  test "returns equipment placed on date" do
    dehu = EquipmentType.create!(organization: @genixo, name: "Dehumidifier")
    @incident.equipment_entries.create!(
      equipment_type: dehu,
      placed_at: @today.beginning_of_day + 9.hours,
      logged_by_user: @manager
    )

    result = @service.activity_for_date(@today)
    assert_equal 1, result[:equipment_entries].size
  end

  test "returns equipment removed on date" do
    dehu = EquipmentType.create!(organization: @genixo, name: "Dehumidifier")
    entry = @incident.equipment_entries.create!(
      equipment_type: dehu,
      placed_at: @yesterday.beginning_of_day + 9.hours,
      removed_at: @today.beginning_of_day + 14.hours,
      logged_by_user: @manager
    )

    result = @service.activity_for_date(@today)
    assert_includes result[:equipment_entries], entry
  end

  test "returns operational notes for date" do
    @incident.operational_notes.create!(
      note_text: "Today's note", log_date: @today,
      created_by_user: @manager
    )
    @incident.operational_notes.create!(
      note_text: "Yesterday's note", log_date: @yesterday,
      created_by_user: @manager
    )

    result = @service.activity_for_date(@today)
    assert_equal 1, result[:operational_notes].size
    assert_equal "Today's note", result[:operational_notes].first.note_text
  end

  test "returns activity events for date" do
    ActivityLogger.log(
      incident: @incident, event_type: "status_changed",
      user: @manager, metadata: { from: "new", to: "active" }
    )

    result = @service.activity_for_date(@today)
    assert_equal 1, result[:activity_events].size
    assert_equal "status_changed", result[:activity_events].first.event_type
  end

  test "returns attachments for date" do
    att = @incident.attachments.create!(
      category: "photo", log_date: @today,
      uploaded_by_user: @manager
    )
    att.file.attach(io: StringIO.new("fake"), filename: "test.jpg", content_type: "image/jpeg")

    result = @service.activity_for_date(@today)
    assert_equal 1, result[:attachments].size
  end

  test "returns empty collections for date with no activity" do
    result = @service.activity_for_date(@today)
    assert_empty result[:labor_entries]
    assert_empty result[:equipment_entries]
    assert_empty result[:operational_notes]
    assert_empty result[:attachments]
    assert_empty result[:activity_events]
  end
end
