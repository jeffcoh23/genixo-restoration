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
    documents = index_for_tab(labels, "Documents")
    messages = index_for_tab(labels, "Messages")
    manage = index_for_tab(labels, "Manage")
    photos = index_for_tab(labels, "Photos")

    assert daily_log
    assert labor
    assert equipment
    assert documents
    assert messages
    assert manage
    assert photos

    assert_operator daily_log, :<, labor
    assert_operator labor, :<, equipment
    assert_operator equipment, :<, documents
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
