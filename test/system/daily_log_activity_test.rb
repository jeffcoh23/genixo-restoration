require "application_system_test_case"

# System tests for the Daily Log, Activity, and Equipment tabs.
# These cover the most critical daily-use workflows of the app.
class DailyLogActivityTest < ApplicationSystemTestCase
  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "River Oaks", property_management_org: @pm,
      mitigation_org: @mitigation, street_address: "100 Main St",
      city: "Houston", state: "TX", zip: "77001", unit_count: 42
    )

    @manager = User.create!(
      organization: @mitigation, user_type: User::MANAGER,
      email_address: "manager@example.com",
      first_name: "Mia", last_name: "Manager", password: "password123"
    )

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Water intrusion", emergency: true
    )

    @dehumidifier_type = EquipmentType.create!(name: "Dehumidifier", organization: @mitigation)
    @air_mover_type = EquipmentType.create!(name: "Air Mover", organization: @mitigation)
  end

  # D1: Edit an activity entry from the daily log timeline
  test "manager edits activity entry from daily log" do
    ActivityEntry.create!(
      incident: @incident, performed_by_user: @manager,
      title: "Water extraction",
      occurred_at: Time.zone.local(2026, 1, 15, 12, 0, 0)
    )

    login_as @manager
    visit incident_path(@incident)

    assert_text "Water extraction"

    find("[data-testid='edit-activity-btn']").click
    assert_text "Edit Activity"

    within("[role='dialog']") do
      find("input[placeholder='e.g. Extract water']").fill_in with: "Water extraction complete"
      click_button "Update Activity"
    end

    assert_text "Water extraction complete"
  end

  # D2: Add a new activity entry
  test "manager adds activity entry from daily log" do
    login_as @manager
    visit incident_path(@incident)

    click_button "Add Activity"
    assert_selector "[role='dialog']"

    within("[role='dialog']") do
      find("input[placeholder='e.g. Extract water']").fill_in with: "Demo test activity"
      find("input[data-testid='activity-form-occurred-at']").fill_in with: "2026-01-15"
      click_button "Add Activity"
    end

    assert_text "Demo test activity"
  end

  # D3: Date filter shows only selected date's entries
  test "daily log date filter shows only entries for selected date" do
    # Use noon timestamps to avoid UTC-midnight timezone boundary issues
    ActivityEntry.create!(
      incident: @incident, performed_by_user: @manager,
      title: "Jan 10 task", occurred_at: Time.zone.local(2026, 1, 10, 12, 0, 0)
    )
    ActivityEntry.create!(
      incident: @incident, performed_by_user: @manager,
      title: "Jan 5 task", occurred_at: Time.zone.local(2026, 1, 5, 12, 0, 0)
    )

    login_as @manager
    visit incident_path(@incident)

    assert_text "Jan 10 task"
    assert_text "Jan 5 task"

    # Click the Jan 10 date pill — format_date uses "%b %-d, %Y"
    click_button "Jan 10, 2026"

    assert_text "Jan 10 task"
    assert_no_text "Jan 5 task"
  end

  # D4: Labor entries do NOT appear as timeline rows in the daily log
  test "labor entries do not appear as daily log timeline rows" do
    # Use noon timestamp so date_key is unambiguously Jan 15 in any timezone
    ActivityEntry.create!(
      incident: @incident, performed_by_user: @manager,
      title: "Dry out operation", occurred_at: Time.zone.local(2026, 1, 15, 12, 0, 0)
    )
    LaborEntry.create!(
      incident: @incident, created_by_user: @manager,
      role_label: "Technician", log_date: Date.new(2026, 1, 15),
      started_at: Time.zone.local(2026, 1, 15, 8, 0, 0),
      ended_at: Time.zone.local(2026, 1, 15, 16, 0, 0),
      hours: 8
    )

    login_as @manager
    visit incident_path(@incident)

    # Only the activity row appears in the timeline — not the labor entry
    timeline_rows = all("[data-testid='daily-log-timeline-row']")
    assert_equal 1, timeline_rows.count
    assert_text "Dry out operation"
  end

  # D5: Attachment entries do NOT appear as timeline rows in the daily log
  test "attachments do not appear as daily log timeline rows" do
    ActivityEntry.create!(
      incident: @incident, performed_by_user: @manager,
      title: "Inspection performed", occurred_at: Time.zone.local(2026, 1, 15, 12, 0, 0)
    )
    att = Attachment.new(
      attachable: @incident, uploaded_by_user: @manager,
      category: "photo", log_date: Date.new(2026, 1, 15)
    )
    att.file.attach(io: StringIO.new("fake"), filename: "photo.jpg", content_type: "image/jpeg")
    att.save!

    login_as @manager
    visit incident_path(@incident)

    # Only the activity row should be in the timeline, not the attachment
    timeline_rows = all("[data-testid='daily-log-timeline-row']")
    assert_equal 1, timeline_rows.count
    assert_text "Inspection performed"
  end

  # D6: DFR download link is present for each date group with entries
  test "daily log shows DFR link for each date with entries" do
    ActivityEntry.create!(
      incident: @incident, performed_by_user: @manager,
      title: "Field work done", occurred_at: Time.zone.local(2026, 1, 15, 12, 0, 0)
    )

    login_as @manager
    visit incident_path(@incident)

    assert_selector "[data-testid='dfr-link-2026-01-15']"
  end

  # L1: Labor form does NOT have a Notes field
  test "labor form has no notes textarea" do
    login_as @manager
    visit incident_path(@incident)

    click_button "Labor"
    click_button "Add Labor", match: :first

    assert_text "Add Labor Entry"

    within("[role='dialog']") do
      assert_no_text "Notes"
      assert_equal 0, all("textarea").count
    end
  end

  # E1: Equipment type filter shows only matching entries
  test "equipment type filter shows only matching type" do
    EquipmentEntry.create!(
      incident: @incident, logged_by_user: @manager,
      equipment_type: @dehumidifier_type, placed_at: Time.current
    )
    EquipmentEntry.create!(
      incident: @incident, logged_by_user: @manager,
      equipment_type: @air_mover_type, placed_at: Time.current
    )

    login_as @manager
    visit incident_path(@incident)
    click_button "Equipment"

    assert_text "Dehumidifier"
    assert_text "Air Mover"

    find("[data-testid='equipment-type-filter']").click
    find("[role='option']", text: "Dehumidifier").click

    assert_text "Dehumidifier"
    assert_no_text "Air Mover"
  end

  # E2: Equipment status filter shows only active or removed entries
  test "equipment status filter separates active from removed entries" do
    EquipmentEntry.create!(
      incident: @incident, logged_by_user: @manager,
      equipment_type: @dehumidifier_type, placed_at: 3.days.ago
    )
    EquipmentEntry.create!(
      incident: @incident, logged_by_user: @manager,
      equipment_type: @air_mover_type,
      placed_at: 2.days.ago, removed_at: 1.day.ago
    )

    login_as @manager
    visit incident_path(@incident)
    click_button "Equipment"

    assert_text "Dehumidifier"
    assert_text "Air Mover"

    # Filter by Active — removed Air Mover should disappear
    find("[data-testid='equipment-status-filter']").click
    find("[role='option']", text: "Active").click

    assert_text "Dehumidifier"
    assert_no_text "Air Mover"

    # Switch to Removed — active Dehumidifier should disappear
    find("[data-testid='equipment-status-filter']").click
    find("[role='option']", text: "Removed").click

    assert_no_text "Dehumidifier"
    assert_text "Air Mover"
  end
end
