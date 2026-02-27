require "application_system_test_case"

class IncidentPanelsTest < ApplicationSystemTestCase
  setup do
    @mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    @pm = Organization.create!(name: "Greystar", organization_type: "property_management")

    @property = Property.create!(
      name: "River Oaks",
      property_management_org: @pm,
      mitigation_org: @mitigation,
      street_address: "100 Main St",
      city: "Houston",
      state: "TX",
      zip: "77001",
      unit_count: 42
    )

    @manager = User.create!(
      organization: @mitigation,
      user_type: User::MANAGER,
      email_address: "manager@example.com",
      first_name: "Mia",
      last_name: "Manager",
      password: "password123"
    )

    @incident = Incident.create!(
      property: @property,
      created_by_user: @manager,
      status: "active",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Water intrusion at loading dock",
      emergency: true
    )
  end

  test "incident tabs preserve core order and include photos tab" do
    login_as @manager
    visit incident_path(@incident)

    tab_container = find(:xpath, "//button[normalize-space()='Daily Log']/ancestor::div[contains(@class,'min-w-max')][1]")
    labels = tab_container.all("button").map { |button| button.text.strip.gsub(/\s+/, " ") }

    daily_log = index_for_tab(labels, "Daily Log")
    labor = index_for_tab(labels, "Labor")
    equipment = index_for_tab(labels, "Equipment")
    moisture = index_for_tab(labels, "Moisture")
    documents = index_for_tab(labels, "Documents")
    messages = index_for_tab(labels, "Messages")
    manage = index_for_tab(labels, "Manage")
    photos = index_for_tab(labels, "Photos")

    assert daily_log
    assert labor
    assert equipment
    assert moisture
    assert documents
    assert messages
    assert manage
    assert photos

    assert_operator daily_log, :<, labor
    assert_operator labor, :<, equipment
    assert_operator equipment, :<, moisture
    assert_operator moisture, :<, documents
    assert_operator documents, :<, messages
    assert_operator messages, :<, manage
  end

  test "messages panel has file and camera controls" do
    login_as @manager
    visit incident_path(@incident)

    click_button "Messages"

    assert_selector "button[aria-label='Attach files']"
    assert_selector "button[aria-label='Take photo']"
  end

  test "moisture panel: add points, record readings, see grid" do
    login_as @manager
    visit incident_path(@incident)

    click_button "Moisture"
    assert_text "No moisture readings recorded yet."

    # Add first measurement point with an initial reading
    click_button "Add Point"
    within("[role='dialog']") do
      fill_in placeholder: "e.g. 1107", with: "1107"
      fill_in placeholder: "e.g. Bathroom", with: "Bathroom"
      fill_in placeholder: "e.g. Wall, Ceiling", with: "Wall"
      fill_in placeholder: "e.g. Drywall, Wood", with: "Drywall"
      fill_in placeholder: "e.g. 7.5, Dry", with: "7.5"
      fill_in placeholder: "e.g. 18.2", with: "18.2"
      click_button "Add Point"
    end

    # Grid should now show the point row with reading
    assert_no_text "No moisture readings recorded yet."
    assert_text "1107"
    assert_text "Bathroom"
    assert_text "Drywall"
    assert_text "18.2"

    # Add a second point (no initial reading)
    click_button "Add Point"
    within("[role='dialog']") do
      fill_in placeholder: "e.g. 1107", with: "1107"
      fill_in placeholder: "e.g. Bathroom", with: "Bedroom"
      fill_in placeholder: "e.g. Wall, Ceiling", with: "Floor"
      fill_in placeholder: "e.g. Drywall, Wood", with: "Carpet"
      fill_in placeholder: "e.g. 7.5, Dry", with: "Dry"
      click_button "Add Point"
    end

    # Both points visible in the grid
    assert_text "Bedroom"
    assert_text "Carpet"

    # Record batch readings for both points
    click_button "Record Readings"
    within("[role='dialog']") do
      # Fill in value inputs for each point row
      inputs = all("input[type='number']")
      inputs[0].fill_in with: "14.1"
      inputs[1].fill_in with: "85"
      click_button "Save Readings"
    end

    # Verify readings appear in the grid
    assert_text "14.1"
    assert_text "85"
  end

  test "photos panel has upload and take photo actions" do
    login_as @manager
    visit incident_path(@incident)

    click_button "Photos"

    assert_button "Upload Photos"
    assert_button "Take Photos"
  end

  private

  def index_for_tab(labels, label)
    labels.index { |text| text.start_with?(label) }
  end
end
