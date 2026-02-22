require "application_system_test_case"

class DailyOperationsTest < ApplicationSystemTestCase
  setup do
    @genixo = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @greystar = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "Sunset Apartments", property_management_org: @greystar,
      mitigation_org: @genixo, street_address: "100 Sunset Blvd",
      city: "Houston", state: "TX", zip: "77001", unit_count: 24
    )

    @manager = User.create!(organization: @genixo, user_type: "manager",
      email_address: "mgr@genixo.com", first_name: "Test", last_name: "Manager", password: "password123")
    @tech = User.create!(organization: @genixo, user_type: "technician",
      email_address: "tech@genixo.com", first_name: "Bob", last_name: "Tech", password: "password123")

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Active incident for testing", emergency: true
    )

    IncidentAssignment.create!(incident: @incident, user: @manager, assigned_by_user: @manager)
    IncidentAssignment.create!(incident: @incident, user: @tech, assigned_by_user: @manager)

    @dehumidifier = EquipmentType.create!(name: "Dehumidifier", organization: @genixo)
  end

  # E1: Send a message on an incident
  test "manager sends a message on incident" do
    login_as @manager
    visit incident_path(@incident)

    # Switch to Messages tab
    click_button "Messages"
    assert_text "No messages yet"

    # Type a message and press Enter to send
    message_box = find("textarea[placeholder='Type a message...']")
    message_box.fill_in with: "Water extraction is complete in unit 4B."
    message_box.send_keys :return

    # Message should appear in the thread
    assert_text "Water extraction is complete in unit 4B."
    assert_text "You"
  end

  # E4: Technician logs labor hours
  test "technician logs labor entry" do
    login_as @tech
    visit incident_path(@incident)

    # Switch to Labor tab
    click_button "Labor"
    assert_text "No labor hours recorded yet."

    # Open the labor form modal
    click_button "Add Labor", match: :first
    assert_text "Add Labor Entry"

    # Fill date and time inputs (no id attributes — find by type within the modal)
    within("[role='dialog']") do
      find("input[type='date']").fill_in with: Date.current.iso8601
      all("input[type='time']")[0].fill_in with: "08:00"
      all("input[type='time']")[1].fill_in with: "16:30"

      click_button "Add Labor"
    end

    # Labor entry should appear in the table
    assert_text "Bob Tech"
  end

  # E9: Manager places equipment
  test "manager places equipment on incident" do
    login_as @manager
    visit incident_path(@incident)

    # Switch to Equipment tab
    click_button "Equipment"
    assert_text "No equipment recorded yet."

    # Open the equipment form modal
    click_button "Add Equipment"

    # Select equipment type from the first select in the modal
    first("select").select "Dehumidifier"

    click_button "Place Equipment"

    # Equipment entry should appear in the table
    assert_text "Dehumidifier"
  end
end
