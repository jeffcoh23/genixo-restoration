require "application_system_test_case"
require_relative "planned_system_test_support"

class DailyOperationsAdditionalTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")
    @property = Property.create!(name: "River Oaks", mitigation_org: @mitigation, property_management_org: @pm)

    @manager = User.create!(organization: @mitigation, user_type: User::MANAGER,
      email_address: "manager@example.com", first_name: "Mia", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @mitigation, user_type: User::TECHNICIAN,
      email_address: "tech@example.com", first_name: "Tina", last_name: "Tech", password: "password123")

    @incident = Incident.create!(property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response", damage_type: "flood",
      description: "Active incident for daily ops tests")
    IncidentAssignment.create!(incident: @incident, user: @manager, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)

    @equipment_type = EquipmentType.create!(organization: @mitigation, name: "Dehumidifier")
  end

  test "send message with attachment" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Messages"

    post_message_via_fetch(body: "See attached file", filename: "note.txt", content_type: "text/plain")
    assert_text "No entries for this date."
    click_button "Messages"
    assert_text "See attached file"
    assert_text "note.txt"
    message = @incident.messages.order(:id).last
    assert_equal 1, message.attachments.count
  end

  test "manager logs labor for another user" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Labor"
    click_button "Add Labor", match: :first

    within("[role='dialog']") do
      find("[role='combobox']").click
      fill_in "e.g. Technician, Supervisor", with: "Technician"
      find("input[type='date']").fill_in with: Date.current.iso8601
      all("input[type='time']")[0].fill_in with: "08:00"
      all("input[type='time']")[1].fill_in with: "12:00"
    end
    find("[role='option']", text: "Tina Tech (Technician)").click
    within("[role='dialog']") { click_button "Add Labor" }

    assert_text "Tina Tech"
    entry = @incident.labor_entries.order(:id).last
    assert_equal @tech.id, entry.user_id
    assert_equal 4.0, entry.hours.to_f
  end

  test "remove equipment entry" do
    entry = EquipmentEntry.create!(
      incident: @incident,
      logged_by_user: @manager,
      equipment_type: @equipment_type,
      equipment_model: "LGR 7000XLi",
      equipment_identifier: "DH-042",
      placed_at: Date.current,
      location_notes: "Unit 101 bedroom"
    )

    login_as @manager
    visit incident_path(@incident)
    click_button "Equipment"

    find("button[title='Mark as removed']").click

    assert_text "Equipment removed."
    assert entry.reload.removed_at.present?
  end

  test "log activity entry via daily log modal" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Daily Log"
    click_button "Add Activity"

    within("[role='dialog']") do
      fill_in "e.g. Extract water", with: "Removed wet drywall in unit 101"
      fill_in "e.g. Active, On Hold - Waiting for reports", with: "Complete"
      find("[data-testid='activity-form-occurred-at']").fill_in with: Date.current.iso8601
      fill_in "e.g. 2", with: "2"
      fill_in "e.g. Units 237 and 239", with: "Units 101 and 102"
      fill_in "Detailed work performed — per-unit narratives, measurements, observations...", with: "Demo complete in kitchen and hallway."
      click_button "Add Activity"
    end

    assert_text "Activity added."
    assert_text "Removed wet drywall in unit 101"

    entry = @incident.activity_entries.order(:id).last
    assert_equal "Removed wet drywall in unit 101", entry.title
    assert_equal "Complete", entry.status
    assert_equal 2, entry.units_affected
    assert_equal "Units 101 and 102", entry.units_affected_description
    assert_equal "Demo complete in kitchen and hallway.", entry.details

    event = @incident.activity_events.order(:id).last
    assert_equal "activity_logged", event.event_type
  end

  test "upload document" do
    login_as @manager
    visit incident_path(@incident)
    click_button "Documents"
    click_button "Upload Document"

    within("[role='dialog']") do
      find("input[type='file']", visible: :all).set(fixture_photo_path.to_s)
      all("[role='combobox']").first.click
    end
    find("[role='option']", text: "Signed Document").click

    within("[role='dialog']") do
      fill_in "Optional description", with: "Signed work authorization"
      click_button "Upload"
    end

    assert_text "File uploaded."
    assert_text "Signed work authorization"
    assert_text "test_photo.jpg"
    attachment = @incident.attachments.order(:id).last
    assert_equal "signed_document", attachment.category
  end

  DAILY_OPS_CASES = {
    "E3" => "reject empty message",
    "E6" => "technician edits own labor entry",
    "E7" => "manager deletes labor entry",
    "E8" => "technician cannot edit another users labor entry",
    "E10" => "equipment placement uses inventory picker",
    "E11" => "equipment placement supports other custom type",
    "E13" => "edit equipment entry",
    "E14" => "technician cannot edit another users equipment entry",
    "E16" => "add operational note",
    "E18" => "add incident contact",
    "E19" => "update incident contact",
    "E20" => "remove incident contact"
  }.freeze

  DAILY_OPS_CASES.each do |id, description|
    test description do
      pending_e2e id, "Daily-ops panel actions need stable dialog/table selectors and richer seeded incident fixtures"
    end
  end

  private

  def fixture_photo_path
    Rails.root.join("test/fixtures/files/test_photo.jpg")
  end

  def post_message_via_fetch(body:, filename:, content_type:)
    js = <<~JS
      const [path, body, filename, contentType] = arguments;
      const token = document.querySelector('meta[name=\"csrf-token\"]')?.content;
      const fd = new FormData();
      fd.append('message[body]', body);
      fd.append('message[files][]', new File(['hello from e2e'], filename, { type: contentType }));
      fetch(path, {
        method: 'POST',
        headers: token ? { 'X-CSRF-Token': token, 'X-Requested-With': 'XMLHttpRequest' } : { 'X-Requested-With': 'XMLHttpRequest' },
        body: fd
      }).then(() => window.location.reload());
    JS
    page.execute_script(js, incident_messages_path(@incident), body, filename, content_type)
  end
end
