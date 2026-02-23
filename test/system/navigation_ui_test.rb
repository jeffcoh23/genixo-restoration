require "application_system_test_case"
require_relative "planned_system_test_support"

class NavigationUiTest < ApplicationSystemTestCase
  include PlannedSystemTestSupport

  test "daily log unread badge tracks only daily log activity entries" do
    mitigation = Organization.create!(name: "Genixo", organization_type: "mitigation")
    pm = Organization.create!(name: "Greystar", organization_type: "property_management")

    property = Property.create!(
      name: "River Oaks",
      mitigation_org: mitigation,
      property_management_org: pm,
      street_address: "100 Main St",
      city: "Houston",
      state: "TX",
      zip: "77001",
      unit_count: 50
    )

    viewer = User.create!(
      organization: mitigation,
      user_type: User::MANAGER,
      email_address: "viewer@example.com",
      first_name: "Vera",
      last_name: "Viewer",
      password: "password123"
    )
    actor = User.create!(
      organization: mitigation,
      user_type: User::TECHNICIAN,
      email_address: "actor@example.com",
      first_name: "Alex",
      last_name: "Actor",
      password: "password123"
    )

    incident = Incident.create!(
      property: property,
      created_by_user: viewer,
      status: "active",
      project_type: "emergency_response",
      damage_type: "flood",
      description: "Water damage in hallway"
    )
    IncidentAssignment.create!(incident: incident, user: viewer, assigned_by_user: viewer)
    IncidentAssignment.create!(incident: incident, user: actor, assigned_by_user: viewer)

    Message.create!(incident: incident, user: actor, body: "Uploaded update")
    ActivityEvent.create!(incident: incident, performed_by_user: actor, event_type: "labor_created", metadata: {})
    ActivityEvent.create!(incident: incident, performed_by_user: actor, event_type: "equipment_placed", metadata: {})
    ActivityEvent.create!(incident: incident, performed_by_user: actor, event_type: "activity_logged", metadata: {})

    login_as viewer
    visit incident_path(incident)

    assert_tab_badge "Messages", "1"
    assert_tab_badge "Daily Log", "1"
  end

  private

  def assert_tab_badge(label, expected_count)
    tab = all("button").find { |button| button.text.include?(label) }
    assert tab, "Expected to find tab button for #{label.inspect}"
    within(tab) do
      assert_selector "span", text: expected_count
    end
  end
end
