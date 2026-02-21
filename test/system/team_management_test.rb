require "application_system_test_case"

class TeamManagementTest < ApplicationSystemTestCase
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

    @pm_user = User.create!(organization: @greystar, user_type: "property_manager",
      email_address: "pm@greystar.com", first_name: "Carol", last_name: "PM", password: "password123")
    @pm_mgr = User.create!(organization: @greystar, user_type: "pm_manager",
      email_address: "pmmgr@greystar.com", first_name: "Dan", last_name: "PMMgr", password: "password123")

    PropertyAssignment.create!(user: @pm_user, property: @property)

    @incident = Incident.create!(
      property: @property, created_by_user: @manager,
      status: "active", project_type: "emergency_response",
      damage_type: "flood", description: "Active incident", emergency: true
    )

    # Manager is already assigned
    IncidentAssignment.create!(incident: @incident, user: @manager, assigned_by_user: @manager)
  end

  # D1: Manager assigns a mitigation team member
  test "manager assigns technician to incident" do
    login_as @manager
    visit incident_path(@incident)

    # Go to Manage tab
    click_button "Manage"
    assert_text "Mitigation Team"

    # The first "Assign" button is in the Mitigation Team section
    assign_buttons = all("button", text: "Assign")
    assign_buttons[0].click

    # Select the tech from the dropdown
    click_button "Bob Tech"

    # Tech should now appear in the team list
    assert_text "Bob Tech"
    assert @incident.reload.assigned_users.include?(@tech)
  end

  # D2: PM user assigns own-org PM user
  test "pm user assigns pm manager to incident" do
    # PM user must be assigned to see the incident
    IncidentAssignment.create!(incident: @incident, user: @pm_user, assigned_by_user: @manager)

    login_as @pm_user
    visit incident_path(@incident)

    # Go to Manage tab
    click_button "Manage"
    assert_text "Property Management"

    # PM user only sees one Assign button (in PM section — mitigation assignable list is empty for PM users)
    click_button "Assign"

    # Select the PM Manager from the dropdown
    click_button "Dan PMMgr"

    # PM Manager should now appear in the team
    assert_text "Dan PMMgr"
    assert @incident.reload.assigned_users.include?(@pm_mgr)
  end
end
