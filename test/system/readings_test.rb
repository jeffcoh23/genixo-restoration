require "application_system_test_case"

# System tests for the Readings tab (Moisture and Psychrometric sub-panels).
class ReadingsTest < ApplicationSystemTestCase
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
  end

  # R1: Adding a new moisture point via the inline form saves it to the table
  test "manager adds a moisture point via inline form" do
    login_as @manager
    visit incident_path(@incident)
    find("[data-testid='incident-tab-readings']").click

    find("input[placeholder='Unit']").fill_in with: "Unit 3"
    find("input[placeholder='Room']").fill_in with: "Master Bath"
    find("input[placeholder='Item']").fill_in with: "Wall"
    find("input[placeholder='Material']").fill_in with: "Drywall"
    find("input[placeholder='Goal']").fill_in with: "16"
    find("button[title='Save']").click

    assert_text "Master Bath"
    assert_text "Unit 3"
  end

  # R2: Newly added moisture points survive switching between Moisture and Psychrometric sub-tabs.
  # Regression test: switching sub-tabs unmounted the panel (losing localPoints state),
  # making newly saved points disappear even though they were persisted in the DB.
  # Fix: both sub-panels are kept mounted and toggled via CSS hidden class.
  test "newly added moisture point persists after switching sub-tabs and back" do
    login_as @manager
    visit incident_path(@incident)
    find("[data-testid='incident-tab-readings']").click

    find("input[placeholder='Unit']").fill_in with: "Unit 7"
    find("input[placeholder='Room']").fill_in with: "Kitchen"
    find("input[placeholder='Item']").fill_in with: "Floor"
    find("input[placeholder='Material']").fill_in with: "Tile"
    find("input[placeholder='Goal']").fill_in with: "15"
    find("button[title='Save']").click

    # Point should appear immediately via optimistic localPoints state
    assert_text "Kitchen"

    # Switch to Psychrometric sub-tab, then back to Moisture
    click_button "Psychrometric"
    click_button "Moisture"

    # The point must still be visible — localPoints state is preserved because
    # the Moisture panel is kept in the DOM (CSS hidden) rather than unmounted
    assert_text "Kitchen"
    assert_text "Unit 7"
  end

  # R3: Server-loaded moisture readings are visible after switching sub-tabs and back
  test "existing moisture readings remain visible after switching sub-tabs" do
    point = MoistureMeasurementPoint.create!(
      incident: @incident, unit: "Unit 2", room: "Hallway",
      item: "Baseboard", material: "Wood", goal: "Dry", measurement_unit: "Pts",
      position: 1
    )
    MoistureReading.create!(
      moisture_measurement_point: point,
      recorded_by_user: @manager,
      log_date: Date.current,
      value: 28
    )

    login_as @manager
    visit incident_path(@incident)
    find("[data-testid='incident-tab-readings']").click

    assert_text "Hallway"

    click_button "Psychrometric"
    click_button "Moisture"

    assert_text "Hallway"
    assert_text "Unit 2"
  end
end
