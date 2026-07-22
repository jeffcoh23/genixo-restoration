require "application_system_test_case"

# E2E for the Weekly Reports tab, the consumables sheet, and the delayed flag
# (Daniel's July 2026 requests).
class WeeklyReportsTest < ApplicationSystemTestCase
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
      damage_type: "flood", description: "Water intrusion"
    )
  end

  test "manager generates a weekly report end to end" do
    ActivityEntry.create!(
      incident: @incident, performed_by_user: @manager,
      title: "Dry-down pass", occurred_at: 2.days.ago
    )

    login_as @manager
    visit incident_path(@incident)

    find("[data-testid='incident-tab-weekly_reports']").click
    assert_text "Generate Weekly Report"

    start_date = (Date.current - 6.days).iso8601
    end_date = Date.current.iso8601

    # No photos/documents on the incident → Generate submits directly.
    find("[data-testid='weekly-report-generate']").click
    assert_selector "[data-testid='weekly-report-pending-#{start_date}']"

    # Run the enqueued job inline (Solid Queue has no worker in system tests);
    # the panel's 5s poll then swaps the pending row for the finished report.
    DfrPdfJob.perform_now(@incident.id, start_date, @manager.timezone, @manager.id, [], nil, end_date)

    assert_selector "[data-testid='weekly-report-row-#{start_date}']", wait: 15
    assert_selector "[data-testid='weekly-report-link-#{start_date}']"
    assert @incident.attachments.exists?(category: "weekly_report", log_date: start_date, log_date_end: end_date)
  end

  test "weekly reports tab is read-only without manage_daily_logs" do
    report = @incident.attachments.create!(category: "weekly_report",
      log_date: Date.current - 6.days, log_date_end: Date.current, uploaded_by_user: @manager)
    report.file.attach(io: StringIO.new("%PDF-fake"), filename: "weekly.pdf", content_type: "application/pdf")

    @manager.update!(permissions: @manager.permissions - [ Permissions::MANAGE_DAILY_LOGS.to_s ])
    login_as @manager
    visit incident_path(@incident)

    find("[data-testid='incident-tab-weekly_reports']").click
    assert_selector "[data-testid='weekly-report-row-#{(Date.current - 6.days).iso8601}']"
    assert_no_text "Generate Weekly Report"
    assert_no_selector "[data-testid='weekly-report-refresh-#{(Date.current - 6.days).iso8601}']"
  end

  test "manager logs consumables from the equipment tab sheet" do
    hepa = ConsumableType.create!(organization: @mitigation, name: "HEPA Filter Air Scrubber Small", position: 0)

    login_as @manager
    visit incident_path(@incident)

    find("[data-testid='incident-tab-equipment']").click
    find("[data-testid='equipment-view-consumables']").click

    find("[data-testid='consumable-qty-#{hepa.id}']").fill_in with: "3"
    find("[data-testid='consumable-writein-name-0']").fill_in with: "Ozone pads"
    find("[data-testid='consumable-writein-qty-0']").fill_in with: "2"
    find("[data-testid='consumables-save']").click

    assert_selector "[data-testid='consumables-day-#{Date.current.iso8601}']", wait: 10

    entries = @incident.consumable_entries.for_date(Date.current)
    assert_equal 2, entries.count
    assert_equal 3, entries.find_by(consumable_type: hepa).quantity
    assert_equal 2, entries.find_by(custom_name: "Ozone pads").quantity
  end

  test "delayed checkbox in the edit form shows the badge" do
    login_as @manager
    visit incident_path(@incident)

    assert_no_selector "[data-testid='incident-delayed-badge']"

    find("[data-testid='edit-incident-btn']", match: :first).click
    find("[data-testid='incident-delayed-checkbox']").click
    click_button "Save Changes"

    assert_selector "[data-testid='incident-delayed-badge']", wait: 10
    assert @incident.reload.delayed
  end
end
